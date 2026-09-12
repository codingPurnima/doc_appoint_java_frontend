import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class AuthService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static String? _accessToken;
  static String? _refreshToken;
  static String? _role;
  static String? _username;
  static String? _lastError;
  static Future<String?>? _ongoingRefresh;

  String get baseUrl => AppConfig.baseUrl;

  static bool get isLoggedIn => _accessToken != null && _accessToken!.isNotEmpty;
  static String? get accessToken => _accessToken;
  static String? get refreshToken => _refreshToken;
  static String? get role => _role;
  static String? get username => _username;
  static String? get lastError => _lastError;

  static void clearLastError() {
    _lastError = null;
  }

  Future<void> loadTokens() async {
    _accessToken = await _secureStorage.read(key: 'access_token');
    _refreshToken = await _secureStorage.read(key: 'refresh_token');
    _role = await _secureStorage.read(key: 'role');
    _username = await _secureStorage.read(key: 'username');
  }

  Future<void> clearSessionData() async {
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
    await _secureStorage.delete(key: 'role');
    await _secureStorage.delete(key: 'username');

    _accessToken = null;
    _refreshToken = null;
    _role = null;
    _username = null;
  }

  Future<bool> hasValidSession() async {
    await loadTokens();
    return _accessToken != null &&
        _accessToken!.isNotEmpty &&
        _refreshToken != null &&
        _refreshToken!.isNotEmpty &&
        _role != null &&
        _role!.isNotEmpty;
  }

  Future<bool> register(String username, String phone, String password) async {
    _lastError = null;
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/register'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "username": username,
              "phone": phone,
              "password": password,
            }),
          )
          .timeout(AppConfig.requestTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }

      _lastError = _extractErrorMessage(
        response,
        defaultMessage: "Registration failed",
      );
      return false;
    } on TimeoutException {
      _lastError = "Connection timed out. Please check your network.";
      return false;
    } catch (_) {
      _lastError = "Unable to connect to server. Please check your network.";
      return false;
    }
  }

  Future<bool> registerDoctor(
    String username,
    String phone,
    String password,
    String secret,
  ) async {
    _lastError = null;
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/register/doctor?secret=$secret'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "username": username,
              "phone": phone,
              "password": password,
            }),
          )
          .timeout(AppConfig.requestTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }

      _lastError = _extractErrorMessage(
        response,
        defaultMessage: "Doctor registration failed",
      );
      return false;
    } on TimeoutException {
      _lastError = "Connection timed out. Please check your network.";
      return false;
    } catch (_) {
      _lastError = "Unable to connect to server. Please check your network.";
      return false;
    }
  }

  Future<Map<String, String>?> login(String username, String password) async {
    _lastError = null;
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"username": username, "password": password}),
          )
          .timeout(AppConfig.requestTimeout);

      if (response.statusCode != 200 || response.body.isEmpty) {
        _lastError = _extractErrorMessage(
          response,
          defaultMessage: "Invalid username or password",
        );
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        _lastError = "Unexpected response from server";
        return null;
      }

      final accessToken = decoded["access_token"]?.toString();
      final refreshToken = decoded["refresh_token"]?.toString();
      final role = decoded["role"]?.toString();

      if (accessToken == null || refreshToken == null || role == null) {
        _lastError = "Incomplete credentials received from server";
        return null;
      }

      await _secureStorage.write(key: 'access_token', value: accessToken);
      await _secureStorage.write(key: 'refresh_token', value: refreshToken);
      await _secureStorage.write(key: 'role', value: role);
      await _secureStorage.write(key: 'username', value: username);

      _accessToken = accessToken;
      _refreshToken = refreshToken;
      _role = role;
      _username = username;

      return {"access_token": accessToken, "role": role};
    } on TimeoutException {
      _lastError = "Connection timed out. Please check your network.";
      return null;
    } catch (_) {
      _lastError = "Unable to connect to server. Please check your network.";
      return null;
    }
  }

  Future<void> logout() async {
    await clearSessionData();
  }

  Future<String?> refreshAccessToken() async {
    if (_ongoingRefresh != null) {
      return _ongoingRefresh;
    }

    _ongoingRefresh = _doRefresh();
    try {
      return await _ongoingRefresh;
    } finally {
      _ongoingRefresh = null;
    }
  }

  Future<String?> _doRefresh() async {
    final refreshToken =
        _refreshToken ?? await _secureStorage.read(key: 'refresh_token');

    if (refreshToken == null || refreshToken.isEmpty) {
      await clearSessionData();
      return null;
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/refresh'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"refresh_token": refreshToken}),
          )
          .timeout(AppConfig.requestTimeout);

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final newAccessToken = decoded["access_token"]?.toString();
          if (newAccessToken != null && newAccessToken.isNotEmpty) {
            await _secureStorage.write(key: 'access_token', value: newAccessToken);
            _accessToken = newAccessToken;
            return newAccessToken;
          }
        }
      }
    } catch (_) {
      // Network/timeout during refresh
    }

    await clearSessionData();
    return null;
  }

  String _extractErrorMessage(
    http.Response response, {
    required String defaultMessage,
  }) {
    try {
      if (response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          if (data['details'] is Map<String, dynamic>) {
            final detailsMap = data['details'] as Map<String, dynamic>;
            final messages = detailsMap.values
                .map((v) => v.toString().trim())
                .where((v) => v.isNotEmpty)
                .toList();
            if (messages.isNotEmpty) {
              return messages.join('\n');
            }
          }
          final message = data['message']?.toString();
          if (message != null && message.isNotEmpty) {
            if (message.contains('Invalid or expired JWT token')) {
              return 'Session expired. Please log in again.';
            }
            if (message.contains('unexpected internal error')) {
              return 'Registration failed. Username or phone number may already be registered.';
            }
            return message;
          }
        }
      }
    } catch (_) {
      // Fall through to status code defaults
    }

    if (response.statusCode == 400) {
      return 'Invalid details submitted.';
    } else if (response.statusCode == 401) {
      return 'Invalid username or password.';
    } else if (response.statusCode == 403) {
      return 'Access denied or session expired.';
    } else if (response.statusCode >= 500) {
      return 'Server error occurred. Please try again later.';
    }

    return defaultMessage;
  }
}


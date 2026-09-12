import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class AuthService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static String? _accessToken;
  static String? _refreshToken;
  static String? _role;
  final String baseUrl = AppConfig.baseUrl;

  static bool get isLoggedIn => _accessToken != null;

  Future<void> loadTokens() async {
    _accessToken = await _secureStorage.read(key: 'access_token');
    _refreshToken = await _secureStorage.read(key: 'refresh_token');
    _role = await _secureStorage.read(key: 'role');
  }

  Future<void> clearSessionData() async {
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
    await _secureStorage.delete(key: 'role');

    _accessToken = null;
    _refreshToken = null;
    _role = null;
  }

  Future<bool> hasValidSession() async {
    await loadTokens();
    return _accessToken != null && _refreshToken != null && _role != null;
  }

  Future<bool> register(String username, String phone, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "phone": phone,
        "password": password,
      }),
    );

    return response.statusCode == 201;
  }

  Future<bool> registerDoctor(
    String username,
    String phone,
    String password,
    String secret,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register/doctor?secret=$secret'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "phone": phone,
        "password": password,
      }),
    );

    return response.statusCode == 200;
  }

  Future<Map<String, String>?> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );

    if (response.statusCode != 200 || response.body.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final accessToken = decoded["access_token"]?.toString();
    final refreshToken = decoded["refresh_token"]?.toString();
    final role = decoded["role"]?.toString();

    if (accessToken == null || refreshToken == null || role == null) {
      return null;
    }

    await _secureStorage.write(key: 'access_token', value: accessToken);
    await _secureStorage.write(key: 'refresh_token', value: refreshToken);
    await _secureStorage.write(key: 'role', value: role);

    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _role = role;

    return {"access_token": accessToken, "role": role};
  }

  Future<void> logout() async {
    await clearSessionData();
  }

  Future<String?> refreshAccessToken() async {
    final refreshToken =
        _refreshToken ?? await _secureStorage.read(key: 'refresh_token');

    if (refreshToken == null || refreshToken.isEmpty) {
      await clearSessionData();
      return null;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/auth/refresh'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"refresh_token": refreshToken}),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        await clearSessionData();
        return null;
      }

      final newAccessToken = decoded["access_token"]?.toString();
      if (newAccessToken == null || newAccessToken.isEmpty) {
        await clearSessionData();
        return null;
      }

      await _secureStorage.write(key: 'access_token', value: newAccessToken);
      _accessToken = newAccessToken;

      return newAccessToken;
    }

    await clearSessionData();
    return null;
  }

  static String? get accessToken => _accessToken;
  static String? get refreshToken => _refreshToken;
  static String? get role => _role;
}

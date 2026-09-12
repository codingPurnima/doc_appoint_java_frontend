import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_service.dart';

class ApiService {
  static String get baseUrl => AppConfig.baseUrl;
  static const Duration _requestTimeout = AppConfig.requestTimeout;

  Future<String?> getToken() async {
    await AuthService().loadTokens();
    return AuthService.accessToken;
  }

  Map<String, String> _jsonHeaders({String? token}) {
    final headers = <String, String>{"Content-Type": "application/json"};
    if (token != null && token.isNotEmpty) {
      headers["Authorization"] = "Bearer $token";
    }
    return headers;
  }

  Future<http.Response> _withTimeout(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request().timeout(_requestTimeout);
    } on TimeoutException {
      throw TimeoutException('Request timed out after $_requestTimeout.');
    }
  }

  Future<http.Response> getRequest(String endpoint) async {
    final token = await getToken();

    var response = await _withTimeout(() async {
      return http.get(
        Uri.parse("$baseUrl$endpoint"),
        headers: _jsonHeaders(token: token),
      );
    });

    if (response.statusCode == 401) {
      final authService = AuthService();
      final newToken = await authService.refreshAccessToken();
      if (newToken != null) {
        response = await _withTimeout(() async {
          return http.get(
            Uri.parse("$baseUrl$endpoint"),
            headers: _jsonHeaders(token: newToken),
          );
        });
      } else {
        await authService.clearSessionData();
      }
    }
    return response;
  }

  Future<http.Response> postRequest(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final token = await getToken();

    var response = await _withTimeout(() async {
      return http.post(
        Uri.parse("$baseUrl$endpoint"),
        headers: _jsonHeaders(token: token),
        body: jsonEncode(body),
      );
    });

    if (response.statusCode == 401) {
      final authService = AuthService();
      final newToken = await authService.refreshAccessToken();

      if (newToken != null) {
        response = await _withTimeout(() async {
          return http.post(
            Uri.parse("$baseUrl$endpoint"),
            headers: _jsonHeaders(token: newToken),
            body: jsonEncode(body),
          );
        });
      } else {
        await authService.clearSessionData();
      }
    }

    return response;
  }

  Future<http.Response> putRequest(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final token = await getToken();

    var response = await _withTimeout(() async {
      return http.put(
        Uri.parse("$baseUrl$endpoint"),
        headers: _jsonHeaders(token: token),
        body: jsonEncode(body),
      );
    });

    if (response.statusCode == 401) {
      final authService = AuthService();
      final newToken = await authService.refreshAccessToken();

      if (newToken != null) {
        response = await _withTimeout(() async {
          return http.put(
            Uri.parse("$baseUrl$endpoint"),
            headers: _jsonHeaders(token: newToken),
            body: jsonEncode(body),
          );
        });
      } else {
        await authService.clearSessionData();
      }
    }

    return response;
  }

  Future<http.Response> patchRequest(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final token = await getToken();

    var response = await _withTimeout(() async {
      return http.patch(
        Uri.parse("$baseUrl$endpoint"),
        headers: _jsonHeaders(token: token),
        body: jsonEncode(data),
      );
    });

    if (response.statusCode == 401) {
      final authService = AuthService();
      final newToken = await authService.refreshAccessToken();

      if (newToken != null) {
        response = await _withTimeout(() async {
          return http.patch(
            Uri.parse("$baseUrl$endpoint"),
            headers: _jsonHeaders(token: newToken),
            body: jsonEncode(data),
          );
        });
      } else {
        await authService.clearSessionData();
      }
    }

    return response;
  }

  Future<List<dynamic>?> getAvailableSlots(String date) async {
    final token = await getToken();

    final response = await _withTimeout(() async {
      return http.get(
        Uri.parse("$baseUrl/slots/available?date=$date"),
        headers: _jsonHeaders(token: token),
      );
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return null;
  }

  Future<bool> bookAppointment(int slotId) async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      return false;
    }

    final response = await _withTimeout(() async {
      return http.post(
        Uri.parse("$baseUrl/appointments/book"),
        headers: _jsonHeaders(token: token),
        body: jsonEncode({"slot_id": slotId}),
      );
    });

    return response.statusCode == 201;
  }

  Future<void> toggleFreezeSlot(int slotId) async {
    final response = await patchRequest("/slots/$slotId/freeze", {});
    if (response.statusCode != 200) {
      throw Exception("Failed to toggle slot freeze");
    }
  }

  Future<List<dynamic>> getDoctorAppointments() async {
    final response = await getRequest("/appointments/doctor");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load appointments");
    }
  }

  Future<void> completeAppointment(int appointmentId) async {
    final response = await patchRequest(
      "/appointments/$appointmentId/complete",
      {},
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to complete appointment");
    }
  }
}

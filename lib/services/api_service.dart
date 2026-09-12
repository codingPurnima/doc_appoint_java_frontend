import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_service.dart';

class ApiService {
  static String get baseUrl => AppConfig.baseUrl;
  static const Duration _requestTimeout = AppConfig.requestTimeout;
  static String? _lastError;

  static String? get lastError => _lastError;

  static void clearLastError() {
    _lastError = null;
  }

  static String _extractErrorMessage(
    http.Response response, {
    String defaultMessage = "An error occurred",
  }) {
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          if (decoded['details'] is Map<String, dynamic>) {
            final detailsMap = decoded['details'] as Map<String, dynamic>;
            final messages = detailsMap.values
                .map((v) => v.toString().trim())
                .where((v) => v.isNotEmpty)
                .toList();
            if (messages.isNotEmpty) {
              return messages.join('\n');
            }
          }
          final message = decoded['message']?.toString();
          if (message != null && message.trim().isNotEmpty) {
            return message.trim();
          }
          final error = decoded['error']?.toString();
          if (error != null && error.trim().isNotEmpty) {
            return error.trim();
          }
        }
      } catch (_) {}
    }

    if (response.statusCode == 400) {
      return 'Invalid request details.';
    } else if (response.statusCode == 401) {
      return 'Session expired. Please log in again.';
    } else if (response.statusCode == 403) {
      return 'Access denied or session expired.';
    } else if (response.statusCode == 409) {
      return 'Slot is no longer available or already booked.';
    } else if (response.statusCode >= 500) {
      return 'Server error occurred. Please try again later.';
    }

    return defaultMessage;
  }

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

    if (response.statusCode == 401 || response.statusCode == 403) {
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

    if (response.statusCode == 401 || response.statusCode == 403) {
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

    if (response.statusCode == 401 || response.statusCode == 403) {
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

    if (response.statusCode == 401 || response.statusCode == 403) {
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
    _lastError = null;
    try {
      final response = await getRequest("/slots/available?date=$date");
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded;
        }
        return [];
      }
      _lastError = _extractErrorMessage(
        response,
        defaultMessage: "Failed to load slots for $date",
      );
      return null;
    } catch (e) {
      _lastError = "Connection error. Please check your network.";
      return null;
    }
  }

  Future<bool> bookAppointment(int slotId) async {
    _lastError = null;
    try {
      final response = await postRequest(
        "/appointments/book",
        {"slot_id": slotId},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }

      _lastError = _extractErrorMessage(
        response,
        defaultMessage: "Booking failed. Please try another slot.",
      );
      return false;
    } catch (e) {
      _lastError = "Connection error while booking appointment.";
      return false;
    }
  }

  Future<bool> cancelAppointment(int appointmentId) async {
    _lastError = null;
    try {
      final response = await putRequest(
        "/appointments/$appointmentId/cancel",
        {},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      }

      _lastError = _extractErrorMessage(
        response,
        defaultMessage: "Failed to cancel appointment.",
      );
      return false;
    } catch (e) {
      _lastError = "Connection error while cancelling appointment.";
      return false;
    }
  }

  Future<List<dynamic>> getPatientAppointments() async {
    _lastError = null;
    try {
      final response = await getRequest("/appointments/me");
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded;
        }
        return [];
      }
      _lastError = _extractErrorMessage(
        response,
        defaultMessage: "Failed to load patient appointments.",
      );
      return [];
    } catch (e) {
      _lastError = "Connection error while fetching appointments.";
      return [];
    }
  }

  Future<List<dynamic>?> getDoctorSlots(String date) async {
    _lastError = null;
    try {
      final response = await getRequest("/slots?date=$date");
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded;
        }
        return [];
      }
      _lastError = _extractErrorMessage(
        response,
        defaultMessage: "Failed to load slots for $date.",
      );
      return null;
    } catch (e) {
      _lastError = "Connection error while loading slots.";
      return null;
    }
  }

  Future<bool> generateSlots({
    required String date,
    required String dayStart,
    required String dayEnd,
    required int slotDurationMinutes,
    List<Map<String, String>> breaks = const [],
  }) async {
    _lastError = null;
    try {
      final response = await postRequest("/slots/generate", {
        "date": date,
        "day_start": dayStart,
        "day_end": dayEnd,
        "slot_duration_minutes": slotDurationMinutes,
        "breaks": breaks,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }

      _lastError = _extractErrorMessage(
        response,
        defaultMessage: "Failed to generate slots.",
      );
      return false;
    } catch (e) {
      _lastError = "Connection error while generating slots.";
      return false;
    }
  }

  Future<bool> toggleFreezeSlot(int slotId) async {
    _lastError = null;
    try {
      final response = await patchRequest("/slots/$slotId/freeze", {});
      if (response.statusCode == 200) {
        return true;
      }

      _lastError = _extractErrorMessage(
        response,
        defaultMessage: "Failed to toggle slot freeze.",
      );
      return false;
    } catch (e) {
      _lastError = "Connection error while toggling slot freeze.";
      return false;
    }
  }

  Future<List<dynamic>> getDoctorAppointments() async {
    _lastError = null;
    try {
      final response = await getRequest("/appointments/doctor");
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded;
        }
        return [];
      }
      _lastError = _extractErrorMessage(
        response,
        defaultMessage: "Failed to load doctor appointments.",
      );
      return [];
    } catch (e) {
      _lastError = "Connection error while fetching appointments.";
      return [];
    }
  }

  Future<bool> completeAppointment(int appointmentId) async {
    _lastError = null;
    try {
      final response = await patchRequest(
        "/appointments/$appointmentId/complete",
        {},
      );

      if (response.statusCode == 200) {
        return true;
      }

      _lastError = _extractErrorMessage(
        response,
        defaultMessage: "Failed to complete appointment.",
      );
      return false;
    } catch (e) {
      _lastError = "Connection error while completing appointment.";
      return false;
    }
  }
}

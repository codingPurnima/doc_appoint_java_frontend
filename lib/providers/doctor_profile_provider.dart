import 'dart:convert';

import 'package:docappoint/services/api_service.dart';
import 'package:docappoint/services/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DoctorProfileState {
  final Map<String, dynamic>? user;
  final List<dynamic> appointments;
  final bool isLoading;
  final String? error;

  const DoctorProfileState({
    required this.user,
    required this.appointments,
    required this.isLoading,
    required this.error,
  });

  DoctorProfileState copyWith({
    Map<String, dynamic>? user,
    List<dynamic>? appointments,
    bool? isLoading,
    String? error,
  }) {
    return DoctorProfileState(
      user: user ?? this.user,
      appointments: appointments ?? this.appointments,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class DoctorProfileNotifier extends Notifier<DoctorProfileState> {
  final ApiService api = ApiService();

  @override
  DoctorProfileState build() {
    return const DoctorProfileState(
      user: null,
      appointments: [],
      isLoading: true,
      error: null,
    );
  }

  Future<void> fetchProfileData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final userResponse = await api.getRequest("/users/me");
      final appointments = await api.getDoctorAppointments();

      Map<String, dynamic>? userData;
      if (userResponse.statusCode == 200) {
        try {
          final decoded = jsonDecode(userResponse.body);
          if (decoded is Map<String, dynamic>) {
            userData = decoded;
          }
        } catch (_) {}
      }

      if (userData == null) {
        await AuthService().loadTokens();
        final username = AuthService.username;
        if (username != null && username.isNotEmpty) {
          userData = {
            "username": username,
            "name": username,
            "role": AuthService.role ?? "doctor",
          };
        }
      }

      state = state.copyWith(
        user: userData,
        appointments: appointments,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> completeAppointment(int id) async {
    final success = await api.completeAppointment(id);
    if (success) {
      await fetchProfileData();
    }
    return success;
  }

  Future<void> logout() async {
    await AuthService().logout();
  }
}

final doctorProfileProvider =
    NotifierProvider<DoctorProfileNotifier, DoctorProfileState>(
      DoctorProfileNotifier.new,
    );

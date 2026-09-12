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
      final responses = await Future.wait([
        api.getRequest("/users/me"),
        api.getRequest("/appointments/doctor"),
      ], eagerError: false);

      final userResponse = responses[0];
      final appointmentResponse = responses[1];

      if (userResponse.statusCode == 200 &&
          appointmentResponse.statusCode == 200) {
        state = state.copyWith(
          user: jsonDecode(userResponse.body),
          appointments: jsonDecode(appointmentResponse.body),
          isLoading: false,
          error: null,
        );
        return;
      }

      if (userResponse.statusCode == 401 ||
          appointmentResponse.statusCode == 401) {
        state = state.copyWith(isLoading: false, error: "session_expired");
        return;
      }

      state = state.copyWith(isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<int> completeAppointment(int id) async {
    final response = await api.patchRequest("/appointments/$id/complete", {});
    if (response.statusCode == 200) {
      await fetchProfileData();
    }
    return response.statusCode;
  }

  Future<void> logout() async {
    await AuthService().logout();
  }
}

final doctorProfileProvider =
    NotifierProvider<DoctorProfileNotifier, DoctorProfileState>(
      DoctorProfileNotifier.new,
    );

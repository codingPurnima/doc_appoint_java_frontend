import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/slot.dart';
import '../services/api_service.dart';

class DoctorHomeState {
  final List<Slot> slots;
  final bool isLoading;
  final String? error;

  const DoctorHomeState({
    required this.slots,
    required this.isLoading,
    required this.error,
  });

  DoctorHomeState copyWith({
    List<Slot>? slots,
    bool? isLoading,
    String? error,
  }) {
    return DoctorHomeState(
      slots: slots ?? this.slots,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class DoctorHomeNotifier extends Notifier<DoctorHomeState> {
  final ApiService api = ApiService();

  // the initial state of the notifier
  @override
  DoctorHomeState build() {
    return const DoctorHomeState(slots: [], isLoading: true, error: null);
  }

  Future<void> fetchSlots() async {
    try {
      final today = DateTime.now().toIso8601String().split("T")[0];
      final response = await api.getRequest("/slots?date=$today");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          state = state.copyWith(
            slots: data.map((json) => Slot.fromJson(json)).toList(),
            isLoading: false,
            error: null,
          );
        } else {
          state = state.copyWith(
            isLoading: false,
            error: "Unexpected response",
          );
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: "Failed to fetch slots",
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> toggleFreezeSlot(int id) async {
    await api.toggleFreezeSlot(id);
    await fetchSlots();
  }
}

final doctorHomeProvider =
    NotifierProvider<DoctorHomeNotifier, DoctorHomeState>(
      DoctorHomeNotifier.new,
    );
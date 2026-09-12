import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/slot.dart';
import '../services/api_service.dart';

class DoctorHomeState {
  final List<Slot> slots;
  final bool isLoading;
  final String? error;
  final String selectedDate;

  const DoctorHomeState({
    required this.slots,
    required this.isLoading,
    required this.error,
    required this.selectedDate,
  });

  DoctorHomeState copyWith({
    List<Slot>? slots,
    bool? isLoading,
    String? error,
    String? selectedDate,
  }) {
    return DoctorHomeState(
      slots: slots ?? this.slots,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }
}

class DoctorHomeNotifier extends Notifier<DoctorHomeState> {
  final ApiService api = ApiService();

  @override
  DoctorHomeState build() {
    final today = DateTime.now().toIso8601String().split("T")[0];
    return DoctorHomeState(
      slots: [],
      isLoading: true,
      error: null,
      selectedDate: today,
    );
  }

  Future<void> fetchSlots([String? date]) async {
    final queryDate = date ?? state.selectedDate;
    state = state.copyWith(isLoading: true, selectedDate: queryDate);

    try {
      final list = await api.getDoctorSlots(queryDate);
      if (list != null) {
        state = state.copyWith(
          slots: list.map((json) => Slot.fromJson(json)).toList(),
          isLoading: false,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: ApiService.lastError ?? "Failed to fetch slots",
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiService.lastError ?? e.toString(),
      );
    }
  }

  Future<bool> toggleFreezeSlot(int id) async {
    final success = await api.toggleFreezeSlot(id);
    if (success) {
      await fetchSlots(state.selectedDate);
    }
    return success;
  }
}

final doctorHomeProvider =
    NotifierProvider<DoctorHomeNotifier, DoctorHomeState>(
      DoctorHomeNotifier.new,
    );
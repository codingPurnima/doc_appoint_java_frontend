import 'package:docappoint/services/api_service.dart';
import 'package:docappoint/theme/app_theme.dart';
import 'package:docappoint/widgets/empty_state_view.dart';
import 'package:docappoint/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import '../../models/slot.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  DateTime selectedDate = DateTime.now();
  List<Slot> slots = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSlots();
  }

  String _formatDate(DateTime dt) {
    return dt.toIso8601String().split("T")[0];
  }

  bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> fetchSlots([DateTime? date]) async {
    if (date != null) {
      selectedDate = date;
    }
    setState(() {
      isLoading = true;
    });

    final dateStr = _formatDate(selectedDate);
    final result = await ApiService().getAvailableSlots(dateStr);

    if (!mounted) return;

    if (result != null) {
      setState(() {
        slots = result.map((json) => Slot.fromJson(json)).toList();
        isLoading = false;
      });
    } else {
      setState(() {
        slots = [];
        isLoading = false;
      });
      if (ApiService.lastError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiService.lastError!)),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (picked != null && !_isSameDay(picked, selectedDate)) {
      fetchSlots(picked);
    }
  }

  void _bookSlot(Slot slot) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.event_available, color: AppColors.primary),
            SizedBox(width: 10),
            Text("Confirm Booking"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Would you like to book this appointment slot?",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule, size: 18, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text(
                    "${slot.startTime} - ${slot.endTime}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(100, 42)),
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await ApiService().bookAppointment(slot.id);

              if (!mounted) return;

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Booking Successful. Try to reach 10 mins earlier than your time",
                    ),
                  ),
                );
                fetchSlots();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ApiService.lastError ?? "Booking Failed",
                    ),
                  ),
                );
              }
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableSlots = slots
        .where((slot) => slot.status == "available" && !slot.isExpired)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Welcome!"),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: "Select Date",
            onPressed: _selectDate,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh Slots",
            onPressed: () => fetchSlots(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: AppColors.cardBorder, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Available Slots",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: _selectDate,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isToday(selectedDate)
                                    ? "Today's Consultations (${_formatDate(selectedDate)})"
                                    : "Consultations for ${_formatDate(selectedDate)}",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 14,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.availableBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.availableBorder),
                  ),
                  child: Text(
                    "${availableSlots.length} Open",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.availableText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text(
                          "Loading available slots...",
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : availableSlots.isEmpty
                ? EmptyStateView(
                    icon: Icons.event_busy_outlined,
                    title: _isToday(selectedDate)
                        ? "No slots available today"
                        : "No slots available for ${_formatDate(selectedDate)}",
                    subtitle:
                        "Please check back later or select another date for openings.",
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    itemCount: availableSlots.length,
                    itemBuilder: (BuildContext context, int index) {
                      final slot = availableSlots[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.schedule_outlined,
                                color: AppColors.accent,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${slot.startTime} - ${slot.endTime}",
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const StatusBadge(status: "available"),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => _bookSlot(slot),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(88, 38),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: const Text("Book"),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.medical_information, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text("Doctor Information"),
                ],
              ),
              content: Text(
                "You are viewing slots for your assigned doctor. Tap 'Book' on any available slot to confirm your appointment.",
              ),
            ),
          );
        },
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        tooltip: "Doctor Information",
        child: const Icon(Icons.medical_information_outlined),
      ),
    );
  }
}

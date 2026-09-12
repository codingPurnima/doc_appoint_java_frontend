import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/status_badge.dart';

class ProfileScreen extends StatelessWidget {
  final Map<String, dynamic>? user;
  final List<dynamic> appointments;
  final bool isLoading;
  final VoidCallback onLogout;
  final Function(int)? onCancelOrCompleteAppointment;
  final String title;

  const ProfileScreen({
    super.key,
    required this.user,
    required this.appointments,
    required this.isLoading,
    required this.onLogout,
    required this.title,
    this.onCancelOrCompleteAppointment,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(title)),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text(
                "Loading profile...",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final isDoctor = title.toLowerCase().contains("doctor");
    final userName = user?["name"] ?? user?["username"] ?? "User";
    final userPhone = user?["phone"] ?? "";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded),
            tooltip: "Logout",
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Profile Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: AppColors.cardBorder, width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : "U",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (userPhone.toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              size: 14,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              userPhone.toString(),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDoctor ? AppColors.completedBg : AppColors.availableBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDoctor ? AppColors.completedBorder : AppColors.availableBorder,
                    ),
                  ),
                  child: Text(
                    isDoctor ? "Doctor" : "Patient",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDoctor ? AppColors.completedText : AppColors.availableText,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Section Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Appointments History",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  "${appointments.length} Total",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Appointments List
          Expanded(
            child: appointments.isEmpty
                ? const EmptyStateView(
                    icon: Icons.event_note_outlined,
                    title: "No appointments yet",
                    subtitle: "Booked consultations will appear here.",
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: appointments.length,
                    itemBuilder: (context, index) {
                      final appointment = appointments[index];
                      final status = appointment["status"]?.toString() ?? "";
                      final date = appointment["date"]?.toString() ?? "";
                      final startTime =
                          (appointment["start_time"] ??
                                  appointment["startTime"])
                              ?.toString() ??
                          "";
                      final endTime =
                          (appointment["end_time"] ?? appointment["endTime"])
                              ?.toString() ??
                          "";
                      final patientName =
                          (appointment["patient_name"] ??
                                  appointment["patientName"])
                              ?.toString() ??
                          "Patient";
                      final rawId =
                          appointment["appointment_id"] ??
                          appointment["appointmentId"] ??
                          appointment["id"];
                      final appointmentId =
                          rawId is int ? rawId : int.tryParse('$rawId');

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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 14,
                                      color: AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      date,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                StatusBadge(status: status),
                              ],
                            ),
                            const Divider(height: 18, color: AppColors.cardBorder),
                            Row(
                              children: [
                                const Icon(
                                  Icons.schedule_outlined,
                                  size: 16,
                                  color: AppColors.accent,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "$startTime - $endTime",
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.person_outline,
                                  size: 16,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Patient: $patientName",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            if (status == "booked" && onCancelOrCompleteAppointment != null && appointmentId != null) ...[
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: isDoctor
                                    ? ElevatedButton.icon(
                                        onPressed: () => onCancelOrCompleteAppointment?.call(
                                          appointmentId,
                                        ),
                                        icon: const Icon(Icons.check, size: 16),
                                        label: const Text("Complete"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.completedDot,
                                          foregroundColor: Colors.white,
                                          minimumSize: const Size(100, 36),
                                          padding: const EdgeInsets.symmetric(horizontal: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          textStyle: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      )
                                    : OutlinedButton.icon(
                                        onPressed: () => onCancelOrCompleteAppointment?.call(
                                          appointmentId,
                                        ),
                                        icon: const Icon(Icons.close, size: 16),
                                        label: const Text("Cancel"),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.bookedText,
                                          side: const BorderSide(color: AppColors.bookedBorder),
                                          minimumSize: const Size(90, 36),
                                          padding: const EdgeInsets.symmetric(horizontal: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          textStyle: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
import 'package:docappoint/providers/doctor_profile_provider.dart';
import 'package:docappoint/screens/common/profile_screen.dart';
import 'package:docappoint/services/api_service.dart';
import 'package:docappoint/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DoctorProfileScreen extends ConsumerStatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  ConsumerState<DoctorProfileScreen> createState() =>
      _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends ConsumerState<DoctorProfileScreen> {
  ProviderSubscription<DoctorProfileState>? _profileSubscription;
  bool _hasHandledSessionExpiry = false;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;
      ref.read(doctorProfileProvider.notifier).fetchProfileData();
    });

    _profileSubscription = ref.listenManual<DoctorProfileState>(
      doctorProfileProvider,
      (previous, next) {
        if (_hasHandledSessionExpiry || next.error != "session_expired") {
          return;
        }

        _hasHandledSessionExpiry = true;

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Oops! Seems like your session expired. "
                "Please login again.",
              ),
            ),
          );

          await ref.read(doctorProfileProvider.notifier).logout();

          if (!mounted) return;

          Navigator.pushNamedAndRemoveUntil(context, "/", (_) => false);
        });
      },
    );
  }

  @override
  void dispose() {
    _profileSubscription?.close();
    super.dispose();
  }

  Future<void> completeAppointment(
    BuildContext context,
    WidgetRef ref,
    int appointmentId,
  ) async {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.completedDot),
            SizedBox(width: 8),
            Text("Complete Appointment"),
          ],
        ),
        content: const Text("Mark this consultation as completed?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.completedDot,
              minimumSize: const Size(90, 38),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);

              final success = await ref
                  .read(doctorProfileProvider.notifier)
                  .completeAppointment(appointmentId);

              if (!context.mounted) return;

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Appointment completed")),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ApiService.lastError ?? "Failed to complete appointment.",
                    ),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text("Complete"),
          ),
        ],
      ),
    );
  }

  Future<void> logout(BuildContext context, WidgetRef ref) async {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.bookedDot),
            SizedBox(width: 8),
            Text("Logout"),
          ],
        ),
        content: const Text(
          "Are you sure you want to log out of your account?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.bookedDot,
              minimumSize: const Size(90, 38),
            ),
            onPressed: () async {
              await ref.read(doctorProfileProvider.notifier).logout();

              if (!context.mounted) return;

              Navigator.pop(dialogContext);

              Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(doctorProfileProvider);

    return ProfileScreen(
      user: state.user,
      appointments: state.appointments,
      isLoading: state.isLoading,
      onLogout: () => logout(context, ref),
      title: "Doctor Profile",
      onCancelOrCompleteAppointment: (id) =>
          completeAppointment(context, ref, id),
    );
  }
}

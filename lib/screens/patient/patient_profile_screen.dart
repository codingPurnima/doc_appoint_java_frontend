import 'dart:convert';
import 'package:docappoint/screens/common/login_screen.dart';
import 'package:docappoint/screens/common/profile_screen.dart';
import 'package:docappoint/services/api_service.dart';
import 'package:docappoint/services/auth_service.dart';
import 'package:docappoint/theme/app_theme.dart';
import 'package:flutter/material.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  Map<String, dynamic>? user;
  List<dynamic> appointments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProfileData();
  }

  Future<void> fetchProfileData() async {
    final api = ApiService();
    final userResponse = await api.getRequest("/users/me");
    final appointmentResponse = await api.getRequest("/appointments/me");

    if (!mounted) return;

    if (userResponse.statusCode == 200 &&
        appointmentResponse.statusCode == 200) {
      setState(() {
        user = jsonDecode(userResponse.body);
        appointments = jsonDecode(appointmentResponse.body);
        isLoading = false;
      });
    } else if (userResponse.statusCode == 401) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Oops! Seems like your session expired. Please login again",
          ),
        ),
      );
      await AuthService().logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
      return;
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> cancelAppointment(int appointmentId) async {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.event_busy, color: AppColors.bookedDot),
            SizedBox(width: 8),
            Text("Cancel Appointment"),
          ],
        ),
        content: const Text("Are you sure you want to cancel this appointment?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Keep"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.bookedDot,
              minimumSize: const Size(90, 38),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              final response = await ApiService().putRequest(
                "/appointments/$appointmentId/cancel",
                {},
              );

              if (!mounted) return;

              if (response.statusCode == 200) {
                fetchProfileData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Appointment cancelled")),
                );
              }
            },
            child: const Text("Yes, Cancel"),
          ),
        ],
      ),
    );
  }

  Future<void> logout() async {
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
        content: const Text("Are you sure you want to log out of your account?"),
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
              Navigator.pop(dialogContext);
              await AuthService().logout();
              if (!mounted) return;
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
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text("Patient Profile")),
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
    return ProfileScreen(
      user: user,
      appointments: appointments,
      isLoading: isLoading,
      title: "Patient Profile",
      onLogout: logout,
      onCancelOrCompleteAppointment: cancelAppointment,
    );
  }
}

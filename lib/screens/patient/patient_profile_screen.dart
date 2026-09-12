import 'dart:convert';
import 'package:docappoint/screens/common/login_screen.dart';
import 'package:docappoint/screens/common/profile_screen.dart';
import 'package:docappoint/services/api_service.dart';
import 'package:docappoint/services/auth_service.dart';
import 'package:docappoint/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
    final authService = AuthService();

    await authService.loadTokens();

    http.Response? userResponse;
    try {
      userResponse = await api.getRequest("/users/me");
    } catch (_) {}

    http.Response? appointmentResponse;
    try {
      appointmentResponse = await api.getRequest("/appointments/me");
    } catch (_) {}

    if (!mounted) return;

    if ((userResponse != null && userResponse.statusCode == 401) ||
        (appointmentResponse != null && appointmentResponse.statusCode == 401)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Oops! Seems like your session expired. Please login again",
          ),
        ),
      );
      await authService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
      return;
    }

    Map<String, dynamic>? parsedUser;
    if (userResponse != null && userResponse.statusCode == 200) {
      try {
        final decoded = jsonDecode(userResponse.body);
        if (decoded is Map<String, dynamic>) {
          parsedUser = decoded;
        }
      } catch (_) {}
    }

    final fallbackUsername = AuthService.username ?? "Patient";
    parsedUser = {
      "name":
          parsedUser?["name"] ??
          parsedUser?["username"] ??
          fallbackUsername,
      "username": parsedUser?["username"] ?? fallbackUsername,
      "phone": parsedUser?["phone"] ?? "",
      "role": parsedUser?["role"] ?? AuthService.role ?? "patient",
    };

    List<dynamic> parsedAppointments = [];
    if (appointmentResponse != null && appointmentResponse.statusCode == 200) {
      try {
        final decoded = jsonDecode(appointmentResponse.body);
        if (decoded is List) {
          parsedAppointments = decoded;
        }
      } catch (_) {}
    }

    setState(() {
      user = parsedUser;
      appointments = parsedAppointments;
      isLoading = false;
    });
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
              final success = await ApiService().cancelAppointment(appointmentId);

              if (!mounted) return;

              if (success) {
                fetchProfileData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Appointment cancelled")),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ApiService.lastError ?? "Failed to cancel appointment",
                    ),
                  ),
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

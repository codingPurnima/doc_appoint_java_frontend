import 'package:flutter/material.dart';
import 'patient_home_screen.dart';
import 'patient_profile_screen.dart';
import '../common/main_screen.dart';


class PatientMainScreen extends StatelessWidget {
  const PatientMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScreen(
      screens: const [
        PatientHomeScreen(),
        PatientProfileScreen(),
      ],
      navItems: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      ],
    );
  }
}
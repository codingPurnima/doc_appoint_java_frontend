import 'package:docappoint/screens/doctor/doctor_home_screen.dart';
import 'package:docappoint/screens/doctor/doctor_profile_screen.dart';
import 'package:flutter/material.dart';

import '../common/main_screen.dart';


class DoctorMainScreen extends StatelessWidget {
  const DoctorMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScreen(
      screens: const [
        DoctorHomeScreen(),
        DoctorProfileScreen(),
      ],
      navItems: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      ],
    );
  }
}
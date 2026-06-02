import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/auth_service.dart';
import '../../widgets/floating_nav_bar.dart';
import 'admin_home.dart';
import '../shared/profile_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final screens = [
      const AdminHome(),
      ProfileScreen(user: user),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _index, children: screens),
      extendBody: true,
      bottomNavigationBar: FloatingNavBar(
        items: const [
          (Icons.dashboard_rounded, 'Overview'),
          (Icons.person_rounded, 'Profile'),
        ],
        selected: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

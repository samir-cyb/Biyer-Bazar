import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_strings.dart';
import '../../services/auth_service.dart';
import '../../widgets/floating_nav_bar.dart';
import 'admin_home.dart';
import 'admin_vendor_approval.dart';
import 'admin_chat_monitor.dart';
import '../booking/my_bookings_screen.dart';
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
      const AdminVendorApprovalScreen(),   // NEW — vendor approvals
      const AdminChatMonitorScreen(),      // NEW — chat monitoring
      const MyBookingsScreen(),            // NEW — all bookings overview
      ProfileScreen(user: user),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _index, children: screens),
      extendBody: true,
      bottomNavigationBar: FloatingNavBar(
        items: [
          (Icons.dashboard_rounded,     'Overview'),
          (Icons.verified_user_rounded, AppStrings.vendorApproval),
          (Icons.monitor_rounded,       AppStrings.chatMonitor),
          (Icons.calendar_month_rounded, AppStrings.bookings),
          (Icons.person_rounded,        AppStrings.profile),
        ],
        selected: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

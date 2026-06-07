import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_strings.dart';
import '../../services/auth_service.dart';
import '../../widgets/floating_nav_bar.dart';
import 'host_home.dart';
import 'vendor_search_screen.dart';
import '../chat/chat_list_screen.dart';
import '../booking/my_bookings_screen.dart';
import '../shared/profile_screen.dart';

class HostShell extends StatefulWidget {
  const HostShell({super.key});

  @override
  State<HostShell> createState() => _HostShellState();
}

class _HostShellState extends State<HostShell> {
  int _index = 0;

  // Navigate by index — used by HostHome quick-action buttons
  void navigateTo(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    // 5 tabs: Home | Vendors | Chat | Bookings | Profile
    // My Posts & Budget moved into Profile tab as quick-access buttons
    final screens = [
      HostHome(onNavigate: navigateTo),
      const VendorSearchScreen(),
      const ChatListScreen(),
      const MyBookingsScreen(),
      ProfileScreen(user: user),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _index, children: screens),
      extendBody: true,
      bottomNavigationBar: FloatingNavBar(
        items: [
          (Icons.home_rounded,           AppStrings.home),
          (Icons.search_rounded,         'Vendors'),
          (Icons.chat_bubble_rounded,    AppStrings.messages),
          (Icons.calendar_month_rounded, AppStrings.bookings),
          (Icons.person_rounded,         AppStrings.profile),
        ],
        selected: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

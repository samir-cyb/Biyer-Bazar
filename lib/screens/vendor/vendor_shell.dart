import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_strings.dart';
import '../../services/auth_service.dart';
import '../../widgets/floating_nav_bar.dart';
import 'vendor_home.dart';
import 'my_bids_screen.dart';
import '../chat/chat_list_screen.dart';
import '../booking/my_bookings_screen.dart';
import '../shared/profile_screen.dart';

class VendorShell extends StatefulWidget {
  const VendorShell({super.key});

  @override
  State<VendorShell> createState() => _VendorShellState();
}

class _VendorShellState extends State<VendorShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final screens = [
      VendorHome(onNavigate: (i) => setState(() => _index = i)),
      const MyBidsScreen(),
      const ChatListScreen(),            // NEW — in-app chat
      const MyBookingsScreen(),          // NEW — bookings
      ProfileScreen(user: user),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _index, children: screens),
      extendBody: true,
      bottomNavigationBar: FloatingNavBar(
        items: [
          (Icons.storefront_rounded,       AppStrings.browse),
          (Icons.gavel_rounded,            AppStrings.myBids),
          (Icons.chat_bubble_rounded,      AppStrings.messages),
          (Icons.calendar_month_rounded,   AppStrings.bookings),
          (Icons.person_rounded,           AppStrings.profile),
        ],
        selected: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

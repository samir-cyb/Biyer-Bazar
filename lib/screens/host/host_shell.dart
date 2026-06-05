import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_strings.dart';
import '../../services/auth_service.dart';
import '../../widgets/floating_nav_bar.dart';
import 'host_home.dart';
import 'my_posts_screen.dart';
import 'vendor_search_screen.dart';
import '../budget/budget_dashboard.dart';
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

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final screens = [
      HostHome(onNavigate: (i) => setState(() => _index = i)),
      const MyPostsScreen(),
      const VendorSearchScreen(),        // NEW — vendor search
      const BudgetDashboard(),
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
          (Icons.home_rounded,             AppStrings.home),
          (Icons.article_rounded,          AppStrings.myPosts),
          (Icons.search_rounded,           AppStrings.findVendors),
          (Icons.calculate_rounded,        AppStrings.budget),
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

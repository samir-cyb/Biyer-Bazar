import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/auth_service.dart';
import '../../widgets/floating_nav_bar.dart';
import 'host_home.dart';
import 'my_posts_screen.dart';
import '../budget/budget_dashboard.dart';
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
      const BudgetDashboard(),
      ProfileScreen(user: user),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _index, children: screens),
      extendBody: true,
      bottomNavigationBar: FloatingNavBar(
        items: const [
          (Icons.home_rounded, 'Home'),
          (Icons.article_rounded, 'My Posts'),
          (Icons.calculate_rounded, 'Budget'),
          (Icons.person_rounded, 'Profile'),
        ],
        selected: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/auth_service.dart';
import '../../widgets/floating_nav_bar.dart';
import 'vendor_home.dart';
import 'my_bids_screen.dart';
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
      ProfileScreen(user: user),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _index, children: screens),
      extendBody: true,
      bottomNavigationBar: FloatingNavBar(
        items: const [
          (Icons.storefront_rounded, 'Browse'),
          (Icons.gavel_rounded, 'My Bids'),
          (Icons.person_rounded, 'Profile'),
        ],
        selected: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

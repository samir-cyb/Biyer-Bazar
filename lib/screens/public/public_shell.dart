import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../services/auth_service.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/host/host_shell.dart';
import '../../screens/vendor/vendor_shell.dart';
import '../../screens/admin/admin_shell.dart';
import '../../models/user_model.dart';
import 'landing_home_screen.dart';
import 'public_vendor_page.dart';

class PublicShell extends StatefulWidget {
  const PublicShell({super.key});
  @override
  State<PublicShell> createState() => _PublicShellState();
}

class _PublicShellState extends State<PublicShell> {
  int _index = 0;

  final _screens = const [
    LandingHomeScreen(),
    PublicVendorPage(),
  ];

  void _onLoginTap() async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, a, __, c) =>
            FadeTransition(opacity: a, child: c),
      ),
    );
    _checkAndRoute();
  }

  void _onSignupTap() async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const SignupScreen(),
        transitionsBuilder: (_, a, __, c) =>
            FadeTransition(opacity: a, child: c),
      ),
    );
    _checkAndRoute();
  }

  void _checkAndRoute() {
    final user = AuthService.currentUser;
    if (user == null) return;
    Widget dest;
    switch (user.role) {
      case UserRole.host:   dest = const HostShell();   break;
      case UserRole.vendor: dest = const VendorShell(); break;
      case UserRole.admin:  dest = const AdminShell();  break;
    }
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => dest,
        transitionsBuilder: (_, a, __, c) =>
            FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 450),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 720;
    return Scaffold(
      backgroundColor: AppColors.background,
      // Web/tablet: top nav bar
      appBar: isWide ? _buildWebAppBar() : null,
      // Mobile: bottom nav
      bottomNavigationBar: isWide ? null : _buildMobileNav(),
      extendBody: !isWide,
      body: IndexedStack(
        index: _index,
        children: _screens,
      ),
    );
  }

  // ── Web/Tablet Top Navigation ───────────────────────────────────────────────
  PreferredSizeWidget _buildWebAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background.withOpacity(0.92),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.charcoal.withOpacity(0.08),
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: SafeArea(
              child: Row(
                children: [
                  // Logo
                  _WebLogo(),
                  const Spacer(),
                  // Nav items
                  _NavItem(
                    label: 'Home',
                    icon: Icons.home_rounded,
                    selected: _index == 0,
                    onTap: () => setState(() => _index = 0),
                  ),
                  const SizedBox(width: 8),
                  _NavItem(
                    label: 'Vendors',
                    icon: Icons.storefront_rounded,
                    selected: _index == 1,
                    onTap: () => setState(() => _index = 1),
                  ),
                  const SizedBox(width: 28),
                  // Login
                  TextButton(
                    onPressed: _onLoginTap,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.charcoalMid,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                    ),
                    child: Text('Log In',
                        style: AppTextStyles.headingSmall.copyWith(
                            fontSize: 14, color: AppColors.charcoalMid)),
                  ),
                  const SizedBox(width: 8),
                  // Sign Up
                  GestureDetector(
                    onTap: _onSignupTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.crimson, Color(0xFF950025)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.crimson.withOpacity(0.30),
                            blurRadius: 16, offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text('Sign Up Free',
                          style: AppTextStyles.headingSmall.copyWith(
                              fontSize: 13, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Mobile Bottom Navigation ────────────────────────────────────────────────
  Widget _buildMobileNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20, offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: AppColors.background.withOpacity(0.90),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Home
                    _MobileNavItem(
                      icon: Icons.home_rounded,
                      label: 'Home',
                      selected: _index == 0,
                      onTap: () => setState(() => _index = 0),
                    ),
                    // Vendors
                    _MobileNavItem(
                      icon: Icons.storefront_rounded,
                      label: 'Vendors',
                      selected: _index == 1,
                      onTap: () => setState(() => _index = 1),
                    ),
                    // Login pill
                    GestureDetector(
                      onTap: _onLoginTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.crimson, Color(0xFF950025)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.crimson.withOpacity(0.35),
                              blurRadius: 14, offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person_rounded,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text('Log In',
                                style: AppTextStyles.headingSmall.copyWith(
                                    fontSize: 13, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Web Logo ──────────────────────────────────────────────────────────────────
class _WebLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.gold, AppColors.crimson],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.crimson.withOpacity(0.30),
                blurRadius: 12, offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Text('উ', style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            )),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Utsob', style: AppTextStyles.headingLarge.copyWith(
                fontSize: 18, color: AppColors.charcoal,
                letterSpacing: -0.3)),
            Text('উৎসব', style: AppTextStyles.bodySmall.copyWith(
                fontSize: 10, color: AppColors.gold,
                fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          ],
        ),
      ],
    );
  }
}

// ── Web Nav Item ──────────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({
    required this.label, required this.icon,
    required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.crimson.withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 17,
                color: selected ? AppColors.crimson : AppColors.charcoalLight),
            const SizedBox(width: 6),
            Text(label,
                style: AppTextStyles.headingSmall.copyWith(
                  fontSize: 14,
                  color: selected ? AppColors.crimson : AppColors.charcoalLight,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                )),
          ],
        ),
      ),
    );
  }
}

// ── Mobile Nav Item ───────────────────────────────────────────────────────────
class _MobileNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _MobileNavItem({
    required this.icon, required this.label,
    required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.crimson.withOpacity(0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              size: 22,
              color: selected ? AppColors.crimson : AppColors.charcoalLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              color: selected ? AppColors.crimson : AppColors.charcoalLight,
            ),
          ),
        ],
      ),
    );
  }
}

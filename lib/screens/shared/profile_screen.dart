import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/glass_card.dart';
import '../auth/welcome_screen.dart';

class ProfileScreen extends StatelessWidget {
  final AppUser? user;
  const ProfileScreen({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    final u = user ?? AuthService.currentUser;
    if (u == null) {
      return const Center(child: Text('Not logged in'));
    }

    final roleColor = u.role == UserRole.host
        ? AppColors.crimson
        : u.role == UserRole.vendor
            ? AppColors.gold
            : AppColors.freshTalent;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.charcoal,
            flexibleSpace: FlexibleSpaceBar(
              background: _ProfileHero(user: u, roleColor: roleColor),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                tooltip: 'Sign Out',
                onPressed: () => _confirmLogout(context),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _InfoCard(user: u),
                if (u.role == UserRole.vendor) ...[
                  const SizedBox(height: 16),
                  _VendorInfoCard(user: u),
                ],
                const SizedBox(height: 16),
                _DevCard(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign Out?', style: AppTextStyles.headingLarge),
        content: Text('You will be returned to the welcome screen.',
            style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              AuthService.logout();
              Navigator.of(context).pushAndRemoveUntil(
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const WelcomeScreen(),
                  transitionsBuilder: (_, a, __, c) =>
                      FadeTransition(opacity: a, child: c),
                  transitionDuration: const Duration(milliseconds: 400),
                ),
                (_) => false,
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final AppUser user;
  final Color roleColor;
  const _ProfileHero({required this.user, required this.roleColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.charcoal,
            roleColor.withOpacity(0.6),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: roleColor.withOpacity(0.3),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.3), width: 2),
                    ),
                    child: Center(
                      child: Text(
                        user.name.substring(0, 1).toUpperCase(),
                        style: AppTextStyles.displaySmall
                            .copyWith(color: Colors.white, fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.businessName ?? user.name,
                            style: AppTextStyles.displaySmall
                                .copyWith(color: Colors.white, fontSize: 20)),
                        Text('+88 ${user.phone}',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: Colors.white.withOpacity(0.65))),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${user.role.emoji}  ${user.role.label}',
                            style: AppTextStyles.labelMedium
                                .copyWith(color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final AppUser user;
  const _InfoCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Account Info', style: AppTextStyles.headingMedium),
          const SizedBox(height: 14),
          _Row('Name', user.name),
          _Row('Phone', '+88 ${user.phone}'),
          _Row('Role', user.role.label),
          if (user.city != null) _Row('City', user.city!),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}

class _VendorInfoCard extends StatelessWidget {
  final AppUser user;
  const _VendorInfoCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      backgroundColor: AppColors.gold.withOpacity(0.06),
      borderColor: AppColors.gold.withOpacity(0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vendor Profile', style: AppTextStyles.headingMedium),
          const SizedBox(height: 14),
          if (user.vendorCategory != null)
            _Row('Category', user.vendorCategory!),
          if (user.location != null)
            _Row('Base City', user.location!),
          _Row('Rating', '${user.rating.toStringAsFixed(1)} ⭐'),
          _Row('Bookings', '${user.totalBookings} completed'),
          _Row('On Platform', '${user.daysOnPlatform} days'),
          _Row('Subscription',
              user.subscriptionTier == 'premium' ? '⭐ Premium' : '🆓 Free'),
          _Row('Verified',
              user.isVerified ? '✅ Verified' : '⏳ Pending'),
        ],
      ),
    ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}

class _DevCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      backgroundColor: AppColors.charcoal.withOpacity(0.04),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Text('⚡', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Dev Mode: All data is stored locally on this device using Hive. No server or OTP is active.',
              style: AppTextStyles.bodySmall,
            ),
          ),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn(duration: 400.ms);
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: AppTextStyles.bodySmall
                    .copyWith(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}

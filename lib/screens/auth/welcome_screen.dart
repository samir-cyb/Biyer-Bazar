import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1C0A0A), Color(0xFF1C1A17), Color(0xFF0A1A0A)],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Decorative circles
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.crimson.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withOpacity(0.08),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Logo
                _LogoSection()
                    .animate()
                    .fadeIn(duration: 700.ms)
                    .scale(
                      begin: const Offset(0.7, 0.7),
                      curve: Curves.elasticOut,
                      duration: 900.ms,
                    ),

                const Spacer(flex: 2),

                // Feature pills
                _FeaturePills()
                    .animate(delay: 500.ms)
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.3, end: 0),

                const Spacer(),

                // Role intro cards
                _RoleCards()
                    .animate(delay: 700.ms)
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 32),

                // CTA buttons
                _CTAButtons()
                    .animate(delay: 900.ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [AppColors.gold, AppColors.crimson],
              center: Alignment(-0.3, -0.5),
              radius: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withOpacity(0.35),
                blurRadius: 36,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Center(
            child: Text('💍', style: TextStyle(fontSize: 42)),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'বিয়ের বাজার',
          style: AppTextStyles.banglaHeading.copyWith(
            color: AppColors.gold,
            fontSize: 30,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'BiyerBajar',
          style: AppTextStyles.displaySmall.copyWith(
            color: Colors.white.withOpacity(0.85),
            letterSpacing: 4,
            fontWeight: FontWeight.w300,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Text(
            'Smart Weddings · Fair Bids · Bangladesh',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.55),
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _FeaturePills extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final features = ['🧮 Smart Budget', '🎯 7 Curated Bids', '🔒 Blind Bidding', '📲 bKash Escrow'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: features
            .map(
              (f) => Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: Text(
                  f,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.75),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _RoleCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final roles = [
      ('👰', 'Host', 'Plan your wedding & receive bids'),
      ('📸', 'Vendor', 'Showcase your talent & win gigs'),
      ('⚙️', 'Admin', 'Manage the platform'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: roles
            .asMap()
            .entries
            .map((e) => Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: e.key < 2 ? 10 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        Text(e.value.$1, style: const TextStyle(fontSize: 24)),
                        const SizedBox(height: 6),
                        Text(e.value.$2,
                            style: AppTextStyles.headingSmall.copyWith(
                                color: Colors.white, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(e.value.$3,
                            style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white.withOpacity(0.45),
                                fontSize: 10),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _CTAButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                _route(const SignupScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.crimson,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 17),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                'Create Account',
                style: AppTextStyles.headingMedium
                    .copyWith(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.push(
                context,
                _route(const LoginScreen()),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(vertical: 17),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'Sign In',
                style: AppTextStyles.headingMedium
                    .copyWith(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PageRoute _route(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      );
}

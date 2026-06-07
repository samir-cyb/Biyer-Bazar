import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../widgets/mesh_background.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedMeshBackground(
        dark: true,
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  _LogoSection()
                      .animate()
                      .fadeIn(duration: 700.ms)
                      .scale(
                        begin: const Offset(0.75, 0.75),
                        curve: Curves.elasticOut,
                        duration: 1000.ms,
                      ),

                  const Spacer(flex: 2),

                  _FeaturePills()
                      .animate(delay: 500.ms)
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.25, end: 0),

                  const Spacer(),

                  _RoleCards()
                      .animate(delay: 700.ms)
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.18, end: 0),

                  const SizedBox(height: 28),

                  _CTAButtons()
                      .animate(delay: 900.ms)
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.18, end: 0),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 3D orb via layered BoxShadow — zero GPU compositor cost
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [AppColors.goldLight, AppColors.crimson, Color(0xFF400010)],
              center: Alignment(-0.3, -0.5),
              radius: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withOpacity(0.50),
                blurRadius: 40,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: AppColors.crimson.withOpacity(0.35),
                blurRadius: 60,
                spreadRadius: 8,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.30),
                blurRadius: 20,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Center(child: Text('💍', style: TextStyle(fontSize: 44))),
        ),
        const SizedBox(height: 26),
        Text(
          'উৎসব',
          style: AppTextStyles.banglaHeading.copyWith(
            color: AppColors.gold,
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Utsob',
          style: AppTextStyles.displaySmall.copyWith(
            color: Colors.white.withOpacity(0.80),
            letterSpacing: 5,
            fontWeight: FontWeight.w300,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.14)),
          ),
          child: Text(
            'Smart Weddings · Fair Bids · Bangladesh',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.60),
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
    const features = [
      ('🧮', 'Smart Budget'),
      ('🎯', '7 Curated Bids'),
      ('🔒', 'Blind Bidding'),
      ('📲', 'bKash Escrow'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: features.asMap().entries.map((e) => Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.14)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(e.value.$1, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                e.value.$2,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withOpacity(0.80),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }
}

class _RoleCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const roles = [
      ('👰', 'Host',   'Plan & receive bids'),
      ('📸', 'Vendor', 'Showcase & win gigs'),
      ('⚙️', 'Admin',  'Manage platform'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: roles.asMap().entries.map((e) => Expanded(
          child: Container(
            margin: EdgeInsets.only(right: e.key < 2 ? 10 : 0),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(e.value.$1, style: const TextStyle(fontSize: 26)),
                const SizedBox(height: 7),
                Text(e.value.$2,
                    style: AppTextStyles.headingSmall.copyWith(
                        color: Colors.white, fontSize: 13)),
                const SizedBox(height: 4),
                Text(e.value.$3,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 10),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        )).toList(),
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
              onPressed: () => Navigator.push(context, _route(const SignupScreen())),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.crimson,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 17),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ).copyWith(
                overlayColor: WidgetStateProperty.resolveWith(
                    (s) => s.contains(WidgetState.pressed)
                        ? Colors.white.withOpacity(0.1)
                        : null),
              ),
              child: Text('Create Account',
                  style: AppTextStyles.headingMedium.copyWith(color: Colors.white, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.push(context, _route(const LoginScreen())),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.28)),
                padding: const EdgeInsets.symmetric(vertical: 17),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('Sign In',
                  style: AppTextStyles.headingMedium.copyWith(color: Colors.white, fontSize: 16)),
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
        transitionDuration: const Duration(milliseconds: 350),
      );
}

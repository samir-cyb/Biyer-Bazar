import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/app_colors.dart';
import '../core/app_text_styles.dart';
import '../services/auth_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/shell/app_shell.dart';

/// Wraps any action with an auth check.
/// If the user is logged in, [onAuthenticated] is called immediately.
/// If not, a premium bottom sheet is shown with Login / Sign Up options.
class AuthGuard {
  static void check(
    BuildContext context, {
    required VoidCallback onAuthenticated,
    String? message,
  }) {
    if (AuthService.currentUser != null) {
      onAuthenticated();
      return;
    }
    _showAuthSheet(context, onAuthenticated: onAuthenticated, message: message);
  }

  static void _showAuthSheet(
    BuildContext context, {
    required VoidCallback onAuthenticated,
    String? message,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Pass the outer context so the sheet can push LoginScreen on the right navigator
      // and call AppShell.of() on the correct widget tree
      builder: (_) => _AuthBottomSheet(
        message: message ?? 'Sign in to continue',
        onAuthenticated: onAuthenticated,
        outerContext: context,
      ),
    );
  }
}

class _AuthBottomSheet extends StatelessWidget {
  final String message;
  final VoidCallback onAuthenticated;
  final BuildContext outerContext;
  const _AuthBottomSheet({
    required this.message,
    required this.onAuthenticated,
    required this.outerContext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).padding.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.charcoal.withOpacity(0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),

          // Icon
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.crimson, Color(0xFF4A0018)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.crimson.withOpacity(0.30),
                  blurRadius: 24, offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Text('💍', style: TextStyle(fontSize: 32)),
            ),
          ).animate().scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1.0, 1.0),
            duration: 400.ms,
            curve: Curves.elasticOut,
          ),

          const SizedBox(height: 20),
          Text('Sign in to Utsob', style: AppTextStyles.displaySmall.copyWith(fontSize: 22)),
          const SizedBox(height: 8),
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.charcoalLight),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Login button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // close sheet
                await Navigator.push(
                  outerContext,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const LoginScreen(),
                    transitionsBuilder: (_, a, __, c) =>
                        FadeTransition(opacity: a, child: c),
                  ),
                );
                if (AuthService.currentUser != null) {
                  AppShell.of(outerContext)?.refresh();
                  onAuthenticated();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.crimson,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text('Log In', style: AppTextStyles.headingMedium.copyWith(
                  color: Colors.white, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 12),

          // Sign up button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                Navigator.pop(context); // close sheet
                await Navigator.push(
                  outerContext,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const SignupScreen(),
                    transitionsBuilder: (_, a, __, c) =>
                        FadeTransition(opacity: a, child: c),
                  ),
                );
                if (AuthService.currentUser != null) {
                  AppShell.of(outerContext)?.refresh();
                  onAuthenticated();
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.crimson,
                side: BorderSide(color: AppColors.crimson.withOpacity(0.4)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('Create Account', style: AppTextStyles.headingMedium.copyWith(
                  color: AppColors.crimson, fontSize: 16)),
            ),
          ),

          const SizedBox(height: 16),
          Text(
            'Free to join · No credit card required',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.charcoalLight),
          ),
        ],
      ),
    ).animate().slideY(begin: 0.2, end: 0, duration: 350.ms, curve: Curves.easeOutCubic);
  }
}

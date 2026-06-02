import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/glass_card.dart';
import '../host/host_shell.dart';
import '../vendor/vendor_shell.dart';
import '../admin/admin_shell.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _login() {
    final phone = _phoneCtrl.text.trim();
    if (phone.length < 11) {
      setState(() => _error = 'Enter a valid 11-digit phone number');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final user = AuthService.login(phone);
    setState(() => _loading = false);

    if (user == null) {
      setState(() => _error = 'No account found with this number. Please sign up.');
      return;
    }

    _navigateByRole(user.role);
  }

  void _navigateByRole(UserRole role) {
    Widget shell;
    switch (role) {
      case UserRole.host:
        shell = const HostShell();
        break;
      case UserRole.vendor:
        shell = const VendorShell();
        break;
      case UserRole.admin:
        shell = const AdminShell();
        break;
    }
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => shell,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.charcoal, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text('Welcome back 👋', style: AppTextStyles.displayMedium)
                .animate()
                .fadeIn(duration: 400.ms),
            const SizedBox(height: 8),
            Text('Sign in with your registered phone number.',
                    style: AppTextStyles.bodyLarge)
                .animate(delay: 100.ms)
                .fadeIn(duration: 400.ms),
            const SizedBox(height: 40),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    autofocus: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ],
                    style: AppTextStyles.headingMedium,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '01XXXXXXXXX',
                      prefixText: '+88  ',
                      prefixIcon: Icon(Icons.phone_rounded,
                          color: AppColors.charcoalLight),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.error.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              size: 16, color: AppColors.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_error!,
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.error)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Sign In →'),
                    ),
                  ),
                ],
              ),
            )
                .animate(delay: 200.ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.1, end: 0),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Don't have an account? ",
                    style: AppTextStyles.bodyMedium),
                GestureDetector(
                  onTap: () => Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const SignupScreen(),
                      transitionsBuilder: (_, anim, __, child) =>
                          FadeTransition(opacity: anim, child: child),
                    ),
                  ),
                  child: Text(
                    'Sign Up',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.crimson,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ).animate(delay: 400.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: 32),

            // Dev hint
            GlassCard(
              backgroundColor: AppColors.gold.withOpacity(0.06),
              borderColor: AppColors.gold.withOpacity(0.2),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Text('⚡', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dev Mode Tip',
                            style: AppTextStyles.headingSmall
                                .copyWith(fontSize: 13)),
                        const SizedBox(height: 3),
                        Text(
                          'Admin: 00000000000\nSeed vendors are pre-registered. Or create a new account.',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate(delay: 500.ms).fadeIn(duration: 400.ms),
          ],
        ),
      ),
    );
  }
}

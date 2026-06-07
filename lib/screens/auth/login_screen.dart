import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/mesh_background.dart';
import '../admin/admin_shell.dart';
import '../shell/app_shell.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _loading  = false;
  bool _showPass = false;
  String? _errorMsg;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() { _errorMsg = null; _loading = true; });
    final result = await AuthService.login(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
    setState(() => _loading = false);
    if (!result.isSuccess) {
      setState(() => _errorMsg = result.errorMessage);
      return;
    }
    if (mounted) _afterLogin(result.user!.role);
  }

  void _afterLogin(UserRole role) {
    if (role == UserRole.admin) {
      // Admin gets their own back-office shell
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const AdminShell(),
          transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
          transitionDuration: const Duration(milliseconds: 400),
        ),
        (_) => false,
      );
    } else {
      // Everyone else pops back to AppShell which calls refresh()
      AppShell.of(context)?.refresh();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedMeshBackground(
        dark: true,
        child: Column(
          children: [
            // ── Dark header (60% of screen) ───────────────────────────────
            Expanded(
              flex: 3,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button
                      PressableCard(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.10),
                            border: Border.all(color: Colors.white.withOpacity(0.16)),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                      const Spacer(),
                      Text('Welcome\nback 👋',
                          style: AppTextStyles.displayLarge.copyWith(
                            color: Colors.white,
                            height: 1.15,
                            fontSize: 38,
                          )),
                      const SizedBox(height: 10),
                      Text('Sign in to continue to Utsob.',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: Colors.white.withOpacity(0.60),
                          )),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),

            // ── Light card panel ──────────────────────────────────────────
            Expanded(
              flex: 5,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.20),
                      blurRadius: 40,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GlassCard(
                        child: Column(children: [
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            autofocus: true,
                            style: AppTextStyles.bodyLarge,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: Icon(Icons.email_outlined,
                                  color: AppColors.charcoalLight, size: 20),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: !_showPass,
                            style: AppTextStyles.bodyLarge,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline_rounded,
                                  color: AppColors.charcoalLight, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                    _showPass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                    color: AppColors.charcoalLight, size: 20),
                                onPressed: () => setState(() => _showPass = !_showPass),
                              ),
                            ),
                            onFieldSubmitted: (_) => _login(),
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.push(context,
                                  PageRouteBuilder(
                                    pageBuilder: (_, __, ___) => const ForgotPasswordScreen(),
                                    transitionsBuilder: (_, a, __, c) =>
                                        FadeTransition(opacity: a, child: c),
                                  )),
                              child: Text('Forgot Password?',
                                  style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.crimson, fontWeight: FontWeight.w700)),
                            ),
                          ),
                          if (_errorMsg != null) ...[
                            const SizedBox(height: 6),
                            _ErrorBanner(message: _errorMsg!),
                          ],
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16)),
                              child: _loading
                                  ? const SizedBox(width: 20, height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Text('Sign In →'),
                            ),
                          ),
                        ]),
                      ).animate(delay: 80.ms).fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0),

                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Don't have an account? ", style: AppTextStyles.bodyMedium),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacement(context,
                                PageRouteBuilder(
                                  pageBuilder: (_, __, ___) => const SignupScreen(),
                                  transitionsBuilder: (_, a, __, c) =>
                                      FadeTransition(opacity: a, child: c),
                                )),
                            child: Text('Sign Up',
                                style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.crimson, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ).animate(delay: 200.ms).fadeIn(duration: 400.ms),

                      const SizedBox(height: 24),
                      GlassCard(
                        backgroundColor: AppColors.gold.withOpacity(0.06),
                        borderColor: AppColors.gold.withOpacity(0.22),
                        padding: const EdgeInsets.all(14),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('⚡ Dev Mode Credentials',
                              style: AppTextStyles.headingSmall.copyWith(fontSize: 13)),
                          const SizedBox(height: 6),
                          Text(
                            'Admin: redwansamir90@gmail.com / samir7232\n'
                            'Host: host@biyerbajar.com / host1234\n'
                            'Vendor: vendor@biyerbajar.com / vendor1234',
                            style: AppTextStyles.bodySmall,
                          ),
                        ]),
                      ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.20)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.error),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
        ),
      ]),
    );
  }
}

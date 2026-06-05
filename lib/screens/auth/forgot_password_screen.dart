import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../services/auth_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/mesh_background.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Steps: 1 = enter phone, 2 = enter OTP, 3 = set new password
  int _step = 1;
  final _phoneCtrl = TextEditingController();
  final _otpCtrl   = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _confCtrl  = TextEditingController();
  bool _showPass = false;
  bool _loading = false;
  String? _errorMsg;
  String? _verifiedPhone;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _passCtrl.dispose();
    _confCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length < 11) {
      setState(() => _errorMsg = 'Enter a valid 11-digit phone number');
      return;
    }
    setState(() { _loading = true; _errorMsg = null; });
    final result = await AuthService.sendPhoneOtp(phone);
    setState(() => _loading = false);

    if (!result.isSuccess) {
      setState(() => _errorMsg = result.errorMessage);
      return;
    }
    setState(() { _verifiedPhone = phone; _step = 2; });
  }

  Future<void> _verifyOtp() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length < 4) {
      setState(() => _errorMsg = 'Enter the 6-digit OTP sent to your phone');
      return;
    }
    setState(() { _loading = true; _errorMsg = null; });
    final result = await AuthService.verifyPhoneOtp(
      phone: _verifiedPhone!,
      otp: otp,
    );
    setState(() => _loading = false);

    if (!result.isSuccess) {
      setState(() => _errorMsg = result.errorMessage);
      return;
    }
    setState(() => _step = 3);
  }

  Future<void> _setNewPassword() async {
    if (_passCtrl.text.length < 6) {
      setState(() => _errorMsg = 'Password must be at least 6 characters.');
      return;
    }
    if (_passCtrl.text != _confCtrl.text) {
      setState(() => _errorMsg = 'Passwords do not match.');
      return;
    }
    setState(() { _loading = true; _errorMsg = null; });
    final result = await AuthService.setNewPassword(_passCtrl.text);
    setState(() => _loading = false);

    if (!result.isSuccess) {
      setState(() => _errorMsg = result.errorMessage);
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('✅ Password updated! Please sign in.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.charcoal, size: 20),
          onPressed: () {
            if (_step > 1) {
              setState(() { _step--; _errorMsg = null; });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text('Reset Password', style: AppTextStyles.headingLarge),
      ),
      body: StaticMeshBackground(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step indicator
            Row(children: [
              _StepDot(n: 1, active: _step == 1, done: _step > 1),
              Expanded(child: Container(height: 2,
                  color: _step > 1 ? AppColors.crimson : AppColors.divider,
                  margin: const EdgeInsets.symmetric(horizontal: 6))),
              _StepDot(n: 2, active: _step == 2, done: _step > 2),
              Expanded(child: Container(height: 2,
                  color: _step > 2 ? AppColors.crimson : AppColors.divider,
                  margin: const EdgeInsets.symmetric(horizontal: 6))),
              _StepDot(n: 3, active: _step == 3, done: false),
            ]),
            const SizedBox(height: 28),

            // ── Step 1: Phone ──────────────────────────────────────────────
            if (_step == 1) ...[
              Text('Find your account', style: AppTextStyles.displaySmall)
                  .animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 6),
              Text('We\'ll send a verification code to your registered phone.',
                  style: AppTextStyles.bodyMedium)
                  .animate(delay: 80.ms).fadeIn(duration: 300.ms),
              const SizedBox(height: 28),
              GlassCard(
                child: Column(children: [
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
                      prefixIcon: Icon(Icons.phone_rounded, color: AppColors.charcoalLight, size: 20),
                    ),
                  ),
                  if (_errorMsg != null) ...[
                    const SizedBox(height: 10),
                    _ErrorBanner(msg: _errorMsg!),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _sendOtp,
                      icon: _loading
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(_loading ? 'Sending OTP...' : 'Send OTP →'),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ),
                ]),
              ).animate(delay: 150.ms).fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0),
            ],

            // ── Step 2: OTP ────────────────────────────────────────────────
            if (_step == 2) ...[
              GlassCard(
                backgroundColor: AppColors.freshTalent.withOpacity(0.05),
                borderColor: AppColors.freshTalent.withOpacity(0.2),
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  const Text('📱', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('OTP sent!', style: AppTextStyles.headingSmall.copyWith(color: AppColors.freshTalent)),
                    Text('Check +88 $_verifiedPhone', style: AppTextStyles.bodySmall),
                  ])),
                ]),
              ).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 20),
              Text('Enter verification code', style: AppTextStyles.displaySmall)
                  .animate(delay: 80.ms).fadeIn(duration: 300.ms),
              const SizedBox(height: 20),
              GlassCard(
                child: Column(children: [
                  TextFormField(
                    controller: _otpCtrl,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    style: AppTextStyles.displaySmall.copyWith(letterSpacing: 8),
                    decoration: const InputDecoration(
                      labelText: 'OTP Code',
                      hintText: '• • • • • •',
                      prefixIcon: Icon(Icons.lock_clock_rounded, color: AppColors.charcoalLight, size: 20),
                    ),
                  ),
                  if (_errorMsg != null) ...[
                    const SizedBox(height: 10),
                    _ErrorBanner(msg: _errorMsg!),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _verifyOtp,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: _loading
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Verify OTP →'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _loading ? null : _sendOtp,
                    child: Text('Resend OTP', style: AppTextStyles.bodySmall.copyWith(color: AppColors.crimson)),
                  ),
                ]),
              ).animate(delay: 150.ms).fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0),
            ],

            // ── Step 3: New Password ───────────────────────────────────────
            if (_step == 3) ...[
              GlassCard(
                backgroundColor: AppColors.freshTalent.withOpacity(0.05),
                borderColor: AppColors.freshTalent.withOpacity(0.2),
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  const Text('✅', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Identity verified! Set your new password.',
                      style: AppTextStyles.headingSmall.copyWith(color: AppColors.freshTalent))),
                ]),
              ).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 20),
              Text('Set new password', style: AppTextStyles.displaySmall)
                  .animate(delay: 80.ms).fadeIn(duration: 300.ms),
              const SizedBox(height: 20),
              GlassCard(
                child: Column(children: [
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: !_showPass,
                    autofocus: true,
                    style: AppTextStyles.bodyLarge,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock_rounded, color: AppColors.charcoalLight, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_showPass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            color: AppColors.charcoalLight, size: 20),
                        onPressed: () => setState(() => _showPass = !_showPass),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confCtrl,
                    obscureText: !_showPass,
                    style: AppTextStyles.bodyLarge,
                    decoration: const InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.charcoalLight, size: 20),
                    ),
                  ),
                  if (_errorMsg != null) ...[
                    const SizedBox(height: 10),
                    _ErrorBanner(msg: _errorMsg!),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _setNewPassword,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: _loading
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Update Password ✓'),
                    ),
                  ),
                ]),
              ).animate(delay: 150.ms).fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0),
            ],
          ],
        ),
      )),
    );
  }
}

class _StepDot extends StatelessWidget {
  final int n;
  final bool active;
  final bool done;
  const _StepDot({required this.n, required this.active, required this.done});
  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.crimson : done ? AppColors.freshTalent : AppColors.charcoalLight;
    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.15),
          border: Border.all(color: color, width: 2)),
      child: Center(child: done
          ? Icon(Icons.check_rounded, size: 14, color: color)
          : Text('$n', style: AppTextStyles.headingSmall.copyWith(color: color, fontSize: 13))),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String msg;
  const _ErrorBanner({required this.msg});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.error.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.error.withOpacity(0.2))),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, size: 14, color: AppColors.error),
        const SizedBox(width: 6),
        Expanded(child: Text(msg, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error))),
      ]),
    );
  }
}

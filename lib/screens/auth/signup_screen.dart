import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/service_categories.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/mesh_background.dart';
import '../host/host_shell.dart';
import '../vendor/vendor_shell.dart';
import '../admin/admin_shell.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _nidCtrl      = TextEditingController();
  final _businessCtrl = TextEditingController();

  UserRole? _selectedRole;
  String _selectedCategory = ServiceCategories.all.first;
  String _selectedLocation = 'Dhaka';
  bool _loading = false;
  bool _showPass = false;
  String? _errorMsg;

  static final _categories = ServiceCategories.all;

  static const _locations = ['Dhaka', 'Chittagong', 'Sylhet', 'Rajshahi', 'Khulna', 'Barishal', 'Cumilla', 'Mymensingh', 'Rangpur', 'Narayanganj'];

  @override
  void dispose() {
    for (final c in [_nameCtrl, _emailCtrl, _passCtrl, _confirmCtrl, _phoneCtrl, _nidCtrl, _businessCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMsg = null);
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRole == null) {
      setState(() => _errorMsg = 'Please select your role.');
      return;
    }

    setState(() => _loading = true);
    final result = await AuthService.signup(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      phone: _phoneCtrl.text.trim(),
      role: _selectedRole!,
      nidNumber: _nidCtrl.text.trim().isEmpty ? null : _nidCtrl.text.trim(),
      businessName: _selectedRole == UserRole.vendor ? _businessCtrl.text.trim() : null,
      vendorCategory: _selectedRole == UserRole.vendor ? _selectedCategory : null,
      location: _selectedRole == UserRole.vendor ? _selectedLocation : null,
      city: _selectedRole == UserRole.host ? _selectedLocation : null,
    );
    setState(() => _loading = false);

    if (!result.isSuccess) {
      setState(() => _errorMsg = result.errorMessage);
      return;
    }
    if (mounted) _navigateByRole(_selectedRole!);
  }

  void _navigateByRole(UserRole role) {
    Widget shell;
    switch (role) {
      case UserRole.host:   shell = const HostShell(); break;
      case UserRole.vendor: shell = const VendorShell(); break;
      case UserRole.admin:  shell = const AdminShell(); break;
    }
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => shell,
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StaticMeshBackground(child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 8, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button row
              Row(
                children: [
                  PressableCard(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.charcoal.withOpacity(0.08),
                        border: Border.all(color: AppColors.charcoal.withOpacity(0.12)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppColors.charcoal, size: 16),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text('Create Account', style: AppTextStyles.headingLarge),
                ],
              ),
              const SizedBox(height: 20),
              Text('Join BiyerBajar', style: AppTextStyles.displaySmall),
              Text('Set up your account to get started.', style: AppTextStyles.bodyMedium),
              const SizedBox(height: 24),

              // ── Role Picker ───────────────────────────────────────────────
              Text('I am a...', style: AppTextStyles.labelLarge),
              const SizedBox(height: 10),
              _RolePicker(selected: _selectedRole, onSelect: (r) => setState(() => _selectedRole = r)),
              const SizedBox(height: 20),

              // ── Personal Details ──────────────────────────────────────────
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Personal Details', style: AppTextStyles.headingSmall),
                    const SizedBox(height: 16),
                    _field(_nameCtrl, 'Full Name', Icons.person_rounded,
                        caps: TextCapitalization.words,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null),
                    const SizedBox(height: 12),
                    _field(_emailCtrl, 'Email Address', Icons.email_rounded,
                        type: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter your email';
                          if (!v.contains('@')) return 'Enter a valid email';
                          return null;
                        }),
                    const SizedBox(height: 12),
                    _field(_phoneCtrl, 'Phone Number', Icons.phone_rounded,
                        type: TextInputType.phone,
                        prefix: '+88  ',
                        formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
                        validator: (v) => (v == null || v.length < 11) ? 'Enter valid 11-digit number' : null),
                    const SizedBox(height: 12),
                    _PasswordField(ctrl: _passCtrl, label: 'Password', show: _showPass,
                        onToggle: () => setState(() => _showPass = !_showPass),
                        validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null),
                    const SizedBox(height: 12),
                    _PasswordField(ctrl: _confirmCtrl, label: 'Confirm Password', show: _showPass,
                        onToggle: () => setState(() => _showPass = !_showPass),
                        validator: (v) => v != _passCtrl.text ? 'Passwords do not match' : null),
                    const SizedBox(height: 12),
                    _field(_nidCtrl, 'NID Number (optional — dev mode)', Icons.credit_card_rounded,
                        type: TextInputType.number,
                        formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(17)]),
                  ],
                ),
              ),

              // ── Vendor Extra ───────────────────────────────────────────────
              if (_selectedRole == UserRole.vendor) ...[
                const SizedBox(height: 16),
                GlassCard(
                  backgroundColor: AppColors.gold.withOpacity(0.05),
                  borderColor: AppColors.gold.withOpacity(0.2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Business Details', style: AppTextStyles.headingSmall),
                      const SizedBox(height: 16),
                      _field(_businessCtrl, 'Business / Studio Name', Icons.storefront_rounded,
                          caps: TextCapitalization.words,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter business name' : null),
                      const SizedBox(height: 12),
                      _dropdown('Service Category', _selectedCategory, _categories,
                          (v) => setState(() => _selectedCategory = v ?? _selectedCategory)),
                      const SizedBox(height: 12),
                      _dropdown('Base City', _selectedLocation, _locations,
                          (v) => setState(() => _selectedLocation = v ?? _selectedLocation)),
                    ],
                  ),
                ),
              ],

              // ── Host City ─────────────────────────────────────────────────
              if (_selectedRole == UserRole.host) ...[
                const SizedBox(height: 16),
                GlassCard(
                  child: _dropdown('Your City', _selectedLocation, _locations,
                      (v) => setState(() => _selectedLocation = v ?? _selectedLocation)),
                ),
              ],

              // ── Error ─────────────────────────────────────────────────────
              if (_errorMsg != null) ...[
                const SizedBox(height: 14),
                _ErrorCard(message: _errorMsg!),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 17)),
                  child: _loading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Create My Account →'),
                ),
              ),
            ].animate(interval: 50.ms).fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0),
          ),
        ),
      )),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {
    TextInputType type = TextInputType.text,
    TextCapitalization caps = TextCapitalization.none,
    String? prefix,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      textCapitalization: caps,
      inputFormatters: formatters,
      style: AppTextStyles.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix,
        prefixIcon: Icon(icon, color: AppColors.charcoalLight, size: 20),
      ),
      validator: validator,
    );
  }

  Widget _dropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
      onChanged: onChanged,
      style: AppTextStyles.bodyLarge.copyWith(color: AppColors.charcoal),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final bool show;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;
  const _PasswordField({required this.ctrl, required this.label, required this.show, required this.onToggle, this.validator});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      obscureText: !show,
      style: AppTextStyles.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_rounded, color: AppColors.charcoalLight, size: 20),
        suffixIcon: IconButton(
          icon: Icon(show ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: AppColors.charcoalLight, size: 20),
          onPressed: onToggle,
        ),
      ),
      validator: validator,
    );
  }
}

class _RolePicker extends StatelessWidget {
  final UserRole? selected;
  final ValueChanged<UserRole> onSelect;
  const _RolePicker({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final roles = [
      (UserRole.host,   '👰', 'Host',   'Plan weddings, post events, receive bids'),
      (UserRole.vendor, '📸', 'Vendor', 'Submit bids on wedding events, win clients'),
      (UserRole.admin,  '⚙️', 'Admin',  'Platform management & oversight'),
    ];
    return Column(
      children: roles.map((r) {
        final isSel = selected == r.$1;
        return GestureDetector(
          onTap: () => onSelect(r.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSel ? AppColors.crimson.withOpacity(0.07) : Colors.white.withOpacity(0.55),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSel ? AppColors.crimson : AppColors.charcoal.withOpacity(0.12),
                  width: isSel ? 1.8 : 1),
              boxShadow: isSel ? [BoxShadow(color: AppColors.crimson.withOpacity(0.1),
                  blurRadius: 14, offset: const Offset(0,4))] : null,
            ),
            child: Row(
              children: [
                Text(r.$2, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r.$3, style: AppTextStyles.headingSmall),
                  Text(r.$4, style: AppTextStyles.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                ])),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSel ? AppColors.crimson : Colors.transparent,
                    border: Border.all(color: isSel ? AppColors.crimson : AppColors.charcoal.withOpacity(0.25), width: 2),
                  ),
                  child: isSel ? const Icon(Icons.check_rounded, size: 13, color: Colors.white) : null,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.error),
        const SizedBox(width: 8),
        Expanded(child: Text(message,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.error))),
      ]),
    );
  }
}

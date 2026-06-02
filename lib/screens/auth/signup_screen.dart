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

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _businessCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  UserRole? _selectedRole;
  String _selectedCategory = 'Photography & Video';
  String _selectedLocation = 'Dhaka';
  bool _loading = false;

  final _categories = [
    'Photography & Video',
    'Catering',
    'Decor & Lighting',
    'Makeup Artist',
    'Venue',
    'Attire & Jewelry',
    'Logistics',
  ];

  final _locations = ['Dhaka', 'Chittagong', 'Sylhet', 'Rajshahi', 'Khulna'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _businessCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select your role'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (AuthService.phoneExists(_phoneCtrl.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Phone number already registered. Please sign in.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    final user = AuthService.signup(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      role: _selectedRole!,
      businessName:
          _selectedRole == UserRole.vendor ? _businessCtrl.text.trim() : null,
      vendorCategory:
          _selectedRole == UserRole.vendor ? _selectedCategory : null,
      location:
          _selectedRole == UserRole.vendor ? _selectedLocation : null,
      city: _selectedRole == UserRole.host ? _selectedLocation : null,
    );

    setState(() => _loading = false);
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
        title: Text('Create Account', style: AppTextStyles.headingLarge),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Join BiyerBajar', style: AppTextStyles.displaySmall),
              const SizedBox(height: 4),
              Text('Choose your role and get started',
                  style: AppTextStyles.bodyMedium),
              const SizedBox(height: 28),

              // Role Picker
              Text('I am a...', style: AppTextStyles.labelLarge),
              const SizedBox(height: 12),
              _RolePicker(
                selected: _selectedRole,
                onSelect: (r) => setState(() => _selectedRole = r),
              ),
              const SizedBox(height: 24),

              // Basic Info
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Personal Details',
                        style: AppTextStyles.headingSmall),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      style: AppTextStyles.bodyLarge,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_rounded,
                            color: AppColors.charcoalLight),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Enter your name'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      style: AppTextStyles.bodyLarge,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        hintText: '01XXXXXXXXX',
                        prefixText: '+88  ',
                        prefixIcon: Icon(Icons.phone_rounded,
                            color: AppColors.charcoalLight),
                      ),
                      validator: (v) {
                        if (v == null || v.length < 11) {
                          return 'Enter valid 11-digit number';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              // Vendor-specific fields
              if (_selectedRole == UserRole.vendor) ...[
                const SizedBox(height: 16),
                GlassCard(
                  backgroundColor: AppColors.gold.withOpacity(0.05),
                  borderColor: AppColors.gold.withOpacity(0.2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Business Details',
                          style: AppTextStyles.headingSmall),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _businessCtrl,
                        textCapitalization: TextCapitalization.words,
                        style: AppTextStyles.bodyLarge,
                        decoration: const InputDecoration(
                          labelText: 'Business / Studio Name',
                          prefixIcon: Icon(Icons.storefront_rounded,
                              color: AppColors.charcoalLight),
                        ),
                        validator: (v) => _selectedRole == UserRole.vendor &&
                                (v == null || v.trim().isEmpty)
                            ? 'Enter your business name'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Service Category',
                          prefixIcon: Icon(Icons.category_rounded,
                              color: AppColors.charcoalLight),
                        ),
                        items: _categories
                            .map((c) =>
                                DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedCategory = v ?? _selectedCategory),
                        style: AppTextStyles.bodyLarge
                            .copyWith(color: AppColors.charcoal),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: _selectedLocation,
                        decoration: const InputDecoration(
                          labelText: 'Base City',
                          prefixIcon: Icon(Icons.location_on_rounded,
                              color: AppColors.charcoalLight),
                        ),
                        items: _locations
                            .map((l) =>
                                DropdownMenuItem(value: l, child: Text(l)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedLocation = v ?? _selectedLocation),
                        style: AppTextStyles.bodyLarge
                            .copyWith(color: AppColors.charcoal),
                      ),
                    ],
                  ),
                ),
              ],

              // Host city picker
              if (_selectedRole == UserRole.host) ...[
                const SizedBox(height: 16),
                GlassCard(
                  child: DropdownButtonFormField<String>(
                    value: _selectedLocation,
                    decoration: const InputDecoration(
                      labelText: 'Your City',
                      prefixIcon: Icon(Icons.location_city_rounded,
                          color: AppColors.charcoalLight),
                    ),
                    items: _locations
                        .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedLocation = v ?? _selectedLocation),
                    style: AppTextStyles.bodyLarge
                        .copyWith(color: AppColors.charcoal),
                  ),
                ),
              ],

              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 17),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Create My Account →'),
                ),
              ),
            ]
                .animate(interval: 60.ms)
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.1, end: 0),
          ),
        ),
      ),
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
      (UserRole.host, '👰', 'Host', 'Plan your wedding, post events, receive bids'),
      (UserRole.vendor, '📸', 'Vendor', 'Submit bids on wedding events, win clients'),
      (UserRole.admin, '⚙️', 'Admin', 'Manage users, posts & platform oversight'),
    ];

    return Column(
      children: roles.map((r) {
        final isSelected = selected == r.$1;
        return GestureDetector(
          onTap: () => onSelect(r.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.crimson.withOpacity(0.08)
                  : Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppColors.crimson
                    : AppColors.charcoal.withOpacity(0.12),
                width: isSelected ? 1.8 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.crimson.withOpacity(0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Text(r.$2, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.$3, style: AppTextStyles.headingSmall),
                      const SizedBox(height: 2),
                      Text(r.$4,
                          style: AppTextStyles.bodySmall, maxLines: 2),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? AppColors.crimson
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.crimson
                          : AppColors.charcoal.withOpacity(0.25),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded,
                          size: 13, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

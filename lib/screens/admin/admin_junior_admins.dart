import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/glass_card.dart';

class AdminJuniorAdmins extends StatefulWidget {
  const AdminJuniorAdmins({super.key});
  @override
  State<AdminJuniorAdmins> createState() => _AdminJuniorAdminsState();
}

class _AdminJuniorAdminsState extends State<AdminJuniorAdmins> {
  List<Map<String, dynamic>> _admins = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    dev.log('[AdminJunior] Loading junior admins', name: 'BiyerBajar');
    setState(() => _loading = true);
    final list = await AdminService.getJuniorAdmins();
    setState(() { _admins = list; _loading = false; });
  }

  void _showAddDialog() {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Add Junior Admin', style: AppTextStyles.headingLarge),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('The user must already have an Utsob account.', style: AppTextStyles.bodySmall),
        const SizedBox(height: 16),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'User Email',
            hintText: 'e.g. manager@example.com',
            prefixIcon: Icon(Icons.email_rounded, color: AppColors.charcoalLight, size: 20),
          ),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            final error = await AdminService.addJuniorAdmin(ctrl.text.trim());
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(error == null ? '✅ Junior admin added!' : '❌ $error'),
                backgroundColor: error == null ? AppColors.success : AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ));
              if (error == null) _load();
            }
          },
          child: const Text('Add Admin'),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isMainAdmin = AuthService.currentUser?.isMainAdmin ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.charcoal,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Junior Admins', style: AppTextStyles.headingLarge.copyWith(color: Colors.white)),
        actions: [
          if (isMainAdmin)
            IconButton(
              icon: const Icon(Icons.person_add_rounded, color: Colors.white),
              tooltip: 'Add Junior Admin',
              onPressed: _showAddDialog,
            ),
          IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.crimson))
          : _admins.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text('👮', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 14),
                    Text('No junior admins yet', style: AppTextStyles.headingMedium),
                    const SizedBox(height: 8),
                    Text('Tap + to add a junior admin', style: AppTextStyles.bodySmall),
                    const SizedBox(height: 20),
                    if (isMainAdmin)
                      ElevatedButton.icon(
                        onPressed: _showAddDialog,
                        icon: const Icon(Icons.person_add_rounded, size: 18),
                        label: const Text('Add Junior Admin'),
                      ),
                  ]),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: _admins.length,
                  itemBuilder: (_, i) {
                    final a = _admins[i];
                    final profile = a['profiles'] as Map? ?? {};
                    final name  = profile['name'] as String? ?? 'Unknown';
                    final email = profile['email'] as String? ?? '—';
                    final phone = profile['phone'] as String? ?? '—';
                    final userId = a['user_id'] as String;

                    return GlassCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Row(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(shape: BoxShape.circle,
                              color: AppColors.charcoal.withOpacity(0.1)),
                          child: Center(child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'A',
                            style: AppTextStyles.headingMedium.copyWith(color: AppColors.charcoal),
                          )),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(name, style: AppTextStyles.headingSmall),
                          Text(email, style: AppTextStyles.bodySmall),
                          Text('+88 $phone', style: AppTextStyles.bodySmall.copyWith(color: AppColors.charcoalLight)),
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: AppColors.charcoal.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8)),
                            child: Text('⚙️ Junior Admin', style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
                          ),
                        ])),
                        if (isMainAdmin)
                          IconButton(
                            icon: const Icon(Icons.person_remove_rounded, color: AppColors.error, size: 20),
                            tooltip: 'Remove admin access',
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  title: Text('Remove Admin Access?', style: AppTextStyles.headingLarge),
                                  content: Text('$name will lose admin access and become a regular user.',
                                      style: AppTextStyles.bodyMedium),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel')),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                      child: const Text('Remove'),
                                    ),
                                  ],
                                ),
                              ) ?? false;
                              if (confirm) {
                                await AdminService.removeJuniorAdmin(userId);
                                _load();
                              }
                            },
                          ),
                      ]),
                    ).animate(delay: Duration(milliseconds: i * 40)).fadeIn(duration: 250.ms);
                  },
                ),
      floatingActionButton: isMainAdmin
          ? FloatingActionButton.extended(
              onPressed: _showAddDialog,
              backgroundColor: AppColors.charcoal,
              icon: const Icon(Icons.person_add_rounded, color: Colors.white),
              label: Text('Add Admin', style: AppTextStyles.labelMedium.copyWith(color: Colors.white)),
            )
          : null,
    );
  }
}

import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../models/user_model.dart';
import '../../services/admin_service.dart';
import '../../widgets/glass_card.dart';

class AdminUserManagement extends StatefulWidget {
  const AdminUserManagement({super.key});
  @override
  State<AdminUserManagement> createState() => _AdminUserManagementState();
}

class _AdminUserManagementState extends State<AdminUserManagement>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<AppUser> _hosts   = [];
  List<AppUser> _vendors = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    dev.log('[AdminUsers] Loading all users', name: 'BiyerBajar');
    setState(() => _loading = true);
    final results = await Future.wait([
      AdminService.getAllUsers(roleFilter: 'host'),
      AdminService.getAllUsers(roleFilter: 'vendor'),
    ]);
    setState(() {
      _hosts   = results[0];
      _vendors = results[1];
      _loading = false;
    });
    dev.log('[AdminUsers] hosts:${_hosts.length} vendors:${_vendors.length}', name: 'BiyerBajar');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.charcoal,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('User Management', style: AppTextStyles.headingLarge.copyWith(color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white), onPressed: _load),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppColors.crimson,
          tabs: [
            Tab(text: '👰 Hosts (${_hosts.length})'),
            Tab(text: '📸 Vendors (${_vendors.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.crimson))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _UserList(users: _hosts, onRefresh: _load),
                _UserList(users: _vendors, onRefresh: _load),
              ],
            ),
    );
  }
}

class _UserList extends StatelessWidget {
  final List<AppUser> users;
  final VoidCallback onRefresh;
  const _UserList({required this.users, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Center(child: Text('No users found', style: AppTextStyles.bodyMedium));
    }
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppColors.crimson,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: users.length,
        itemBuilder: (_, i) => _UserCard(user: users[i], index: i, onRefresh: onRefresh),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final AppUser user;
  final int index;
  final VoidCallback onRefresh;
  const _UserCard({required this.user, required this.index, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (user.role == UserRole.host ? AppColors.crimson : AppColors.gold).withOpacity(0.15),
          ),
          child: Center(child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: AppTextStyles.headingMedium.copyWith(
                color: user.role == UserRole.host ? AppColors.crimson : AppColors.gold),
          )),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(user.name, style: AppTextStyles.headingSmall),
          Text(user.email, style: AppTextStyles.bodySmall),
          Text(user.phone.isNotEmpty ? '+88 ${user.phone}' : 'No phone',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.charcoalLight)),
          if (user.city != null)
            Text(user.city!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.charcoalLight)),
        ])),
        Column(children: [
          if (!user.isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('Suspended', style: AppTextStyles.bodySmall.copyWith(color: AppColors.error, fontSize: 10)),
            ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: Text(user.isActive ? 'Suspend User?' : 'Reactivate User?',
                      style: AppTextStyles.headingLarge),
                  content: Text(user.name, style: AppTextStyles.bodyMedium),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: user.isActive ? AppColors.error : AppColors.success),
                      child: Text(user.isActive ? 'Suspend' : 'Reactivate'),
                    ),
                  ],
                ),
              ) ?? false;
              if (confirm) {
                await AdminService.toggleUserActive(user.id, !user.isActive);
                onRefresh();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: (user.isActive ? AppColors.error : AppColors.success).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: (user.isActive ? AppColors.error : AppColors.success).withOpacity(0.3)),
              ),
              child: Text(user.isActive ? 'Suspend' : 'Activate',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: user.isActive ? AppColors.error : AppColors.success,
                      fontWeight: FontWeight.w600, fontSize: 11)),
            ),
          ),
        ]),
      ]),
    ).animate(delay: Duration(milliseconds: index * 30)).fadeIn(duration: 220.ms);
  }
}

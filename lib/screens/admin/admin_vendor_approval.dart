import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/app_strings.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/mesh_background.dart';

class AdminVendorApprovalScreen extends StatefulWidget {
  const AdminVendorApprovalScreen({super.key});

  @override
  State<AdminVendorApprovalScreen> createState() =>
      _AdminVendorApprovalScreenState();
}

class _AdminVendorApprovalScreenState extends State<AdminVendorApprovalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<Map<String, dynamic>> _pending   = [];
  List<Map<String, dynamic>> _approved  = [];
  List<Map<String, dynamic>> _rejected  = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final all = await SupabaseService.vendorProfiles
          .select('*, profiles!vendor_profiles_user_id_fkey(name, email, phone)')
          .order('created_at', ascending: false);

      setState(() {
        _pending  = (all as List).where((r) => r['approval_status'] == 'pending').cast<Map<String, dynamic>>().toList();
        _approved = (all).where((r) => r['approval_status'] == 'approved').cast<Map<String, dynamic>>().toList();
        _rejected = (all).where((r) => r['approval_status'] == 'rejected').cast<Map<String, dynamic>>().toList();
        _loading  = false;
      });
    } catch (e) {
      dev.log('[Admin] loadVendorApprovals error: $e', name: 'BiyerBajar');
      setState(() => _loading = false);
    }
  }

  Future<void> _approve(String userId) async {
    final adminId = AuthService.currentUser?.id;
    dev.log('[Admin] Approving vendor: $userId', name: 'BiyerBajar');
    try {
      await SupabaseService.vendorProfiles.update({
        'approval_status': 'approved',
        'approved_at':     DateTime.now().toIso8601String(),
        'approved_by':     adminId,
        'is_verified':     true,
        'rejection_reason': null,
      }).eq('user_id', userId);

      dev.log('[Admin] Approval DB update done', name: 'BiyerBajar');

      // Send in-app notification to the vendor
      await NotificationService.send(
        toUserId: userId,
        title:    '🎉 Profile Approved!',
        body:     'Your vendor profile has been approved. You are now visible to hosts and can receive bookings.',
        type:     'approval',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Vendor approved and notified.'),
          backgroundColor: AppColors.freshTalent,
          behavior: SnackBarBehavior.floating,
        ));
      }
      _load();
    } catch (e) {
      dev.log('[Admin] Approve FAILED: $e', name: 'BiyerBajar', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Approval failed: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
        ));
      }
    }
  }

  Future<void> _reject(String userId, String reason) async {
    dev.log('[Admin] Rejecting vendor: $userId', name: 'BiyerBajar');
    try {
      await SupabaseService.vendorProfiles.update({
        'approval_status':  'rejected',
        'rejection_reason': reason,
        'is_verified':      false,
      }).eq('user_id', userId);

      await NotificationService.send(
        toUserId: userId,
        title:    '❌ Profile Not Approved',
        body:     'Your vendor profile was not approved. Reason: $reason. Please update your profile and resubmit.',
        type:     'rejection',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Vendor rejected and notified.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ));
      }
      _load();
    } catch (e) {
      dev.log('[Admin] Reject FAILED: $e', name: 'BiyerBajar', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Rejection failed: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StaticMeshBackground(
        child: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.background,
              elevation: 0,
              title: Text(AppStrings.vendorApproval, style: AppTextStyles.headingLarge),
              bottom: TabBar(
                controller: _tabCtrl,
                labelColor: AppColors.crimson,
                unselectedLabelColor: AppColors.charcoalLight,
                indicatorColor: AppColors.crimson,
                indicatorWeight: 2.5,
                labelStyle: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700),
                unselectedLabelStyle: AppTextStyles.bodySmall,
                tabs: [
                  Tab(text: 'Pending (${_pending.length})'),
                  Tab(text: 'Approved (${_approved.length})'),
                  Tab(text: 'Rejected (${_rejected.length})'),
                ],
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabCtrl,
            children: [
              _VendorList(
                  vendors: _pending, status: 'pending',
                  onApprove: _approve, onReject: _reject, loading: _loading),
              _VendorList(
                  vendors: _approved, status: 'approved',
                  onApprove: _approve, onReject: _reject, loading: _loading),
              _VendorList(
                  vendors: _rejected, status: 'rejected',
                  onApprove: _approve, onReject: _reject, loading: _loading),
            ],
          ),
        ),
      ),
    );
  }
}

class _VendorList extends StatelessWidget {
  final List<Map<String, dynamic>> vendors;
  final String status;
  final Future<void> Function(String) onApprove;
  final Future<void> Function(String, String) onReject;
  final bool loading;
  const _VendorList({
    required this.vendors, required this.status,
    required this.onApprove, required this.onReject, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.crimson));
    }
    if (vendors.isEmpty) {
      return Center(
        child: Text('No $status vendors', style: AppTextStyles.bodyMedium));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      itemCount: vendors.length,
      itemBuilder: (_, i) => _VendorApprovalCard(
        vendor: vendors[i],
        status: status,
        onApprove: onApprove,
        onReject: onReject,
        index: i,
      ),
    );
  }
}

class _VendorApprovalCard extends StatelessWidget {
  final Map<String, dynamic> vendor;
  final String status;
  final Future<void> Function(String) onApprove;
  final Future<void> Function(String, String) onReject;
  final int index;
  const _VendorApprovalCard({
    required this.vendor, required this.status,
    required this.onApprove, required this.onReject, required this.index});

  @override
  Widget build(BuildContext context) {
    final profile = vendor['profiles'] as Map? ?? {};
    final userId  = vendor['user_id'] as String? ?? '';
    final bName   = vendor['business_name'] as String? ?? 'Unknown';
    final category= vendor['category'] as String? ?? '';
    final name    = profile['name'] as String? ?? '';
    final email   = profile['email'] as String? ?? '';
    final bio     = vendor['bio'] as String?;
    final location= vendor['location'] as String?;
    final priceMin= vendor['price_range_min'] as int?;
    final priceMax= vendor['price_range_max'] as int?;
    final reason  = vendor['rejection_reason'] as String?;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                    colors: [AppColors.gold, AppColors.crimson])),
              child: Center(
                child: Text(bName.isNotEmpty ? bName[0].toUpperCase() : '?',
                    style: AppTextStyles.headingSmall
                        .copyWith(color: Colors.white, fontSize: 18))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bName, style: AppTextStyles.headingSmall),
                Text('$name · $email',
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                    overflow: TextOverflow.ellipsis),
              ],
            )),
            _StatusBadge(status),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 4, children: [
            _InfoPill(Icons.category_rounded, category),
            if (location != null) _InfoPill(Icons.location_on_rounded, location),
            if (priceMin != null && priceMax != null)
              _InfoPill(Icons.payments_rounded, '৳$priceMin–৳$priceMax'),
          ]),
          if (bio != null) ...[
            const SizedBox(height: 8),
            Text(bio, style: AppTextStyles.bodySmall, maxLines: 3,
                overflow: TextOverflow.ellipsis),
          ],
          if (reason != null && status == 'rejected') ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.info_rounded, size: 13, color: AppColors.error),
              const SizedBox(width: 4),
              Expanded(child: Text('Reason: $reason',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.error,
                      fontSize: 10))),
            ]),
          ],
          if (status == 'pending') ...[
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showRejectDialog(context, userId),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    foregroundColor: AppColors.error,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10)),
                  child: Text(AppStrings.reject,
                      style: const TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => onApprove(userId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.freshTalent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10)),
                  child: Text(AppStrings.approve,
                      style: const TextStyle(fontSize: 12, color: Colors.white)),
                ),
              ),
            ]),
          ],
          if (status == 'approved') ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => _showRejectDialog(context, userId),
                icon: const Icon(Icons.remove_circle_outline_rounded, size: 15),
                label: const Text('Suspend', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
              ),
            ),
          ],
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: index * 60))
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.05, end: 0);
  }

  Future<void> _showRejectDialog(BuildContext context, String userId) async {
    final ctrl = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rejection reason'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
              hintText: 'Enter reason for rejection...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (submitted == true) {
      onReject(userId, ctrl.text.isEmpty ? 'Does not meet requirements' : ctrl.text);
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  Color get _color {
    switch (status) {
      case 'approved': return AppColors.freshTalent;
      case 'rejected': return AppColors.error;
      default:         return AppColors.warning;
    }
  }

  String get _label {
    switch (status) {
      case 'approved': return '✓ Approved';
      case 'rejected': return '✗ Rejected';
      default:         return '⏳ Pending';
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: _color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
    child: Text(_label, style: AppTextStyles.bodySmall.copyWith(
        fontSize: 10, color: _color, fontWeight: FontWeight.w700)),
  );
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoPill(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.overlayDark, borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: AppColors.charcoalLight),
      const SizedBox(width: 4),
      Text(text, style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
    ]),
  );
}

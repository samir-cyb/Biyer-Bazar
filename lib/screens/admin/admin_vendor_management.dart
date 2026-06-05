import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../models/user_model.dart';
import '../../services/admin_service.dart';
import '../../widgets/glass_card.dart';

class AdminVendorManagement extends StatefulWidget {
  const AdminVendorManagement({super.key});
  @override
  State<AdminVendorManagement> createState() => _AdminVendorManagementState();
}

class _AdminVendorManagementState extends State<AdminVendorManagement> {
  List<AppUser> _vendors = [];
  List<AppUser> _filtered = [];
  bool _loading = true;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    dev.log('[AdminVendors] Loading vendor list', name: 'BiyerBajar');
    setState(() => _loading = true);
    final vendors = await AdminService.getAllUsers(roleFilter: 'vendor');
    setState(() { _vendors = vendors; _filtered = vendors; _loading = false; });
    dev.log('[AdminVendors] Loaded ${vendors.length} vendors', name: 'BiyerBajar');
  }

  void _filter(String q) {
    setState(() {
      _searchQuery = q;
      _filtered = q.isEmpty
          ? _vendors
          : _vendors.where((v) =>
              (v.businessName ?? v.name).toLowerCase().contains(q.toLowerCase()) ||
              (v.vendorCategory ?? '').toLowerCase().contains(q.toLowerCase()) ||
              (v.location ?? '').toLowerCase().contains(q.toLowerCase())).toList();
    });
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
        title: Text('Vendor Management', style: AppTextStyles.headingLarge.copyWith(color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _filter,
              decoration: InputDecoration(
                hintText: 'Search vendors...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.charcoalLight),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.close_rounded), onPressed: () { _searchCtrl.clear(); _filter(''); })
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.crimson))
                : _filtered.isEmpty
                    ? Center(child: Text('No vendors found', style: AppTextStyles.bodyMedium))
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.crimson,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _VendorCard(
                            vendor: _filtered[i],
                            index: i,
                            onRefresh: _load,
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _VendorCard extends StatelessWidget {
  final AppUser vendor;
  final int index;
  final VoidCallback onRefresh;
  const _VendorCard({required this.vendor, required this.index, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final tier = vendor.badgeTier;
    final tierColor = Color(int.parse(tier.color.replaceFirst('#', 'FF'), radix: 16));

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(shape: BoxShape.circle,
                color: AppColors.gold.withOpacity(0.15),
                border: Border.all(color: AppColors.gold.withOpacity(0.3))),
            child: Center(child: Text(
              (vendor.businessName ?? vendor.name).isNotEmpty
                  ? (vendor.businessName ?? vendor.name)[0].toUpperCase() : 'V',
              style: AppTextStyles.headingMedium.copyWith(color: AppColors.gold),
            )),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(vendor.businessName ?? vendor.name, style: AppTextStyles.headingSmall),
            Text(vendor.vendorCategory ?? 'Vendor', style: AppTextStyles.bodySmall),
            Text(vendor.email, style: AppTextStyles.bodySmall.copyWith(color: AppColors.charcoalLight)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: tierColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: tierColor.withOpacity(0.3))),
              child: Text('${tier.emoji} ${tier.label}',
                  style: AppTextStyles.bodySmall.copyWith(color: tierColor, fontWeight: FontWeight.w700, fontSize: 10)),
            ),
            const SizedBox(height: 4),
            if (vendor.hasPremiumBadge)
              Text('💎 Premium', style: AppTextStyles.bodySmall.copyWith(color: AppColors.gold, fontWeight: FontWeight.w700)),
            if (vendor.isVerified)
              Text('✅ Verified', style: AppTextStyles.bodySmall.copyWith(color: AppColors.success)),
          ]),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Text('⭐ ${vendor.rating.toStringAsFixed(1)}', style: AppTextStyles.bodySmall),
          const SizedBox(width: 10),
          Text('${vendor.totalBookings} bookings', style: AppTextStyles.bodySmall),
          const SizedBox(width: 10),
          Text('${vendor.location ?? "—"}', style: AppTextStyles.bodySmall),
          if (!vendor.isActive) ...[
            const SizedBox(width: 10),
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('Suspended', style: AppTextStyles.bodySmall.copyWith(color: AppColors.error, fontSize: 10))),
          ],
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 6, children: [
          // Verify / Unverify
          _ActionBtn(
            vendor.isVerified ? 'Unverify' : 'Verify ✅',
            vendor.isVerified ? AppColors.charcoalLight : AppColors.success,
            () async {
              await AdminService.verifyVendor(vendor.id, !vendor.isVerified);
              onRefresh();
            },
          ),
          // Premium badge
          _ActionBtn(
            vendor.hasPremiumBadge ? 'Remove Premium' : 'Grant 💎 Premium',
            vendor.hasPremiumBadge ? AppColors.charcoalLight : AppColors.gold,
            () async {
              await AdminService.grantPremiumBadge(vendor.id, !vendor.hasPremiumBadge);
              onRefresh();
            },
          ),
          // Suspend / Activate
          _ActionBtn(
            vendor.isActive ? 'Suspend' : 'Activate',
            vendor.isActive ? AppColors.error : AppColors.success,
            () async {
              final confirm = await _confirm(context,
                  vendor.isActive ? 'Suspend ${vendor.businessName ?? vendor.name}?' : 'Reactivate?');
              if (confirm) {
                await AdminService.toggleUserActive(vendor.id, !vendor.isActive);
                onRefresh();
              }
            },
          ),
          // Override badge
          _ActionBtn('Override Badge 🏅', AppColors.charcoalMid, () => _showBadgeDialog(context, vendor)),
          // Grant subscription
          _ActionBtn('Grant Sub 🎫', AppColors.freshTalent, () => _showSubDialog(context, vendor)),
        ]),
      ]),
    ).animate(delay: Duration(milliseconds: index * 40)).fadeIn(duration: 250.ms);
  }

  Future<bool> _confirm(BuildContext context, String question) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Confirm', style: AppTextStyles.headingLarge),
        content: Text(question, style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    ) ?? false;
  }

  void _showBadgeDialog(BuildContext context, AppUser vendor) {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Override Badge', style: AppTextStyles.headingLarge),
      content: Column(mainAxisSize: MainAxisSize.min, children: VendorBadgeTier.values.map((tier) {
        final c = Color(int.parse(tier.color.replaceFirst('#', 'FF'), radix: 16));
        return ListTile(
          leading: Text(tier.emoji, style: const TextStyle(fontSize: 22)),
          title: Text(tier.label, style: AppTextStyles.headingSmall.copyWith(color: c)),
          onTap: () async {
            Navigator.pop(context);
            await AdminService.overrideBadgeTier(vendor.id, tier.name);
            onRefresh();
          },
        );
      }).toList()),
    ));
  }

  void _showSubDialog(BuildContext context, AppUser vendor) {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Grant Subscription', style: AppTextStyles.headingLarge),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          leading: const Icon(Icons.calendar_month_rounded),
          title: const Text('Monthly (500 BDT)'),
          onTap: () async {
            Navigator.pop(context);
            await AdminService.grantSubscription(vendor.id, 'monthly');
            onRefresh();
          },
        ),
        ListTile(
          leading: const Icon(Icons.calendar_today_rounded),
          title: const Text('Annual (5000 BDT)'),
          onTap: () async {
            Navigator.pop(context);
            await AdminService.grantSubscription(vendor.id, 'annual');
            onRefresh();
          },
        ),
        ListTile(
          leading: const Icon(Icons.cancel_rounded, color: AppColors.error),
          title: const Text('Revoke Subscription', style: TextStyle(color: AppColors.error)),
          onTap: () async {
            Navigator.pop(context);
            await AdminService.revokeSubscription(vendor.id);
            onRefresh();
          },
        ),
      ]),
    ));
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(this.label, this.color, this.onTap);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.35))),
        child: Text(label, style: AppTextStyles.bodySmall.copyWith(color: color, fontWeight: FontWeight.w600, fontSize: 11)),
      ),
    );
  }
}

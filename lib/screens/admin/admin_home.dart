import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../models/user_model.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../services/platform_settings_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/mesh_background.dart';
import 'admin_vendor_management.dart';
import 'admin_user_management.dart';
import 'admin_platform_settings.dart';
import 'admin_transactions.dart';
import 'admin_junior_admins.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});
  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  PlatformStats? _stats;
  bool _loading = true;
  Timer? _autoRefreshTimer;
  final _fmt = NumberFormat('#,##,###', 'en_IN');

  @override
  void initState() {
    super.initState();
    _loadStats();
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _loadStats(),
    );
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadStats() async {
    dev.log('[AdminHome] Loading platform stats', name: 'BiyerBajar');
    setState(() => _loading = true);
    final stats = await AdminService.getPlatformStats();
    if (mounted) setState(() { _stats = stats; _loading = false; });
    dev.log('[AdminHome] Stats loaded — users:${stats.totalUsers} vendors:${stats.totalVendors}',
        name: 'BiyerBajar');
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final settings = PlatformSettingsService.current;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StaticMeshBackground(child: RefreshIndicator(
        onRefresh: () async {
          await _loadStats();
          await PlatformSettingsService.load();
          setState(() {});
        },
        color: AppColors.crimson,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(user),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Live toggles banner ─────────────────────────────────
                  _LiveStatusBanner(settings: settings),
                  const SizedBox(height: 16),

                  // ── Analytics ───────────────────────────────────────────
                  Text('Platform Overview', style: AppTextStyles.headingLarge),
                  const SizedBox(height: 12),
                  _loading
                      ? const Center(child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(color: AppColors.crimson)))
                      : _AnalyticsGrid(stats: _stats!, fmt: _fmt),
                  const SizedBox(height: 20),

                  // ── Revenue projection ──────────────────────────────────
                  if (!_loading) _RevenueProjectionCard(stats: _stats!, settings: settings, fmt: _fmt),
                  const SizedBox(height: 20),

                  // ── Quick Actions ───────────────────────────────────────
                  Text('Admin Tools', style: AppTextStyles.headingLarge),
                  const SizedBox(height: 12),
                  _AdminToolsGrid(context: context),
                  const SizedBox(height: 20),

                  // ── Badge Distribution ──────────────────────────────────
                  if (!_loading) _BadgeDistributionCard(stats: _stats!),
                ]),
              ),
            ),
          ],
        ),
      )),
    );
  }

  SliverAppBar _buildAppBar(AppUser? user) {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: AppColors.charcoal,
      elevation: 0,
      title: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: const BoxDecoration(shape: BoxShape.circle,
              gradient: LinearGradient(colors: [AppColors.crimson, AppColors.gold])),
          child: Center(child: Text(
            (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'A',
            style: AppTextStyles.headingSmall.copyWith(color: Colors.white, fontSize: 14),
          )),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('Admin Panel', style: AppTextStyles.headingSmall.copyWith(color: Colors.white, fontSize: 14)),
          Text(user?.isMainAdmin == true ? '⚙️ Main Admin' : '⚙️ Junior Admin',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white60)),
        ]),
      ]),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
          onPressed: _loadStats,
          tooltip: 'Refresh stats',
        ),
      ],
    );
  }
}

// ── Live Status Banner ────────────────────────────────────────────────────────
class _LiveStatusBanner extends StatelessWidget {
  final PlatformSettings settings;
  const _LiveStatusBanner({required this.settings});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      backgroundColor: AppColors.charcoal.withOpacity(0.06),
      borderColor: AppColors.charcoal.withOpacity(0.2),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('⚡', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text('Live Platform Status', style: AppTextStyles.headingSmall),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 10, runSpacing: 8, children: [
          _StatusPill('Subscription',
              settings.subscriptionEnabled ? 'ON' : 'OFF',
              settings.subscriptionEnabled ? AppColors.success : AppColors.charcoalLight),
          _StatusPill('Premium Badge',
              settings.premiumBadgeEnabled ? 'ON' : 'OFF',
              settings.premiumBadgeEnabled ? AppColors.gold : AppColors.charcoalLight),
          _StatusPill('Escrow',
              settings.escrowEnabled ? 'ON' : 'OFF',
              settings.escrowEnabled ? AppColors.freshTalent : AppColors.charcoalLight),
          _StatusPill('Free Bids',
              settings.subscriptionEnabled ? '${settings.freeBidLimit}/mo' : 'Unlimited',
              AppColors.crimson),
          _StatusPill('Commission', '${settings.commissionRate.toStringAsFixed(0)}%', AppColors.gold),
        ]),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const AdminPlatformSettings())).then((_) {
              PlatformSettingsService.load();
            }),
            icon: const Icon(Icons.settings_rounded, size: 16),
            label: const Text('Manage Platform Settings'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.charcoal,
              side: BorderSide(color: AppColors.charcoal.withOpacity(0.3)),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ]),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatusPill(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(width: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
          child: Text(value, style: AppTextStyles.bodySmall.copyWith(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

// ── Analytics Grid ────────────────────────────────────────────────────────────
class _AnalyticsGrid extends StatelessWidget {
  final PlatformStats stats;
  final NumberFormat fmt;
  const _AnalyticsGrid({required this.stats, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final cells = [
      ('👥', '${stats.totalUsers}',     'Total Users',    AppColors.crimson),
      ('👰', '${stats.totalHosts}',     'Hosts',          AppColors.charcoalMid),
      ('📸', '${stats.totalVendors}',   'Vendors',        AppColors.gold),
      ('📋', '${stats.totalPosts}',     'Total Posts',    AppColors.freshTalent),
      ('🟢', '${stats.openPosts}',      'Open Posts',     AppColors.success),
      ('✅', '${stats.bookedPosts}',    'Booked',         AppColors.freshTalent),
      ('💬', '${stats.totalBids}',      'Total Bids',     AppColors.charcoalMid),
      ('⭐', '${stats.totalReviews}',   'Reviews',        AppColors.gold),
      ('🌟', '${stats.newUsersToday}',  'New Today',      AppColors.crimson),
      ('📅', '${stats.newUsersThisMonth}', 'This Month',  AppColors.charcoalMid),
      ('✔️',  '${stats.verifiedVendors}', 'Verified',     AppColors.freshTalent),
      ('💎', '${stats.premiumVendors}', 'Premium',        AppColors.gold),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.2,
      children: cells.asMap().entries.map((e) => _StatCell(
        emoji: e.value.$1,
        value: e.value.$2,
        label: e.value.$3,
        color: e.value.$4,
        index: e.key,
      )).toList(),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final Color color;
  final int index;
  const _StatCell({required this.emoji, required this.value, required this.label,
      required this.color, required this.index});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.headingLarge.copyWith(color: color, fontSize: 20)),
        Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
            textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    ).animate(delay: Duration(milliseconds: index * 40)).fadeIn(duration: 250.ms).scale(
        begin: const Offset(0.9, 0.9));
  }
}

// ── Revenue Projection ────────────────────────────────────────────────────────
class _RevenueProjectionCard extends StatelessWidget {
  final PlatformStats stats;
  final PlatformSettings settings;
  final NumberFormat fmt;
  const _RevenueProjectionCard({required this.stats, required this.settings, required this.fmt});

  @override
  Widget build(BuildContext context) {
    // Projections
    final subRevenue = stats.totalVendors * 0.5 * settings.subscriptionPriceMonthly;
    final premiumRevenue = settings.premiumBadgePrice * stats.premiumVendors;
    final commissionEst = stats.bookedPosts * 5000; // avg 100k booking × 5%

    return GlassCard(
      backgroundColor: AppColors.gold.withOpacity(0.06),
      borderColor: AppColors.gold.withOpacity(0.25),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('💰', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Text('Revenue Dashboard', style: AppTextStyles.headingMedium),
        ]),
        const SizedBox(height: 14),
        _RevRow('Actual Commission Earned',
            '৳ ${fmt.format(stats.totalCommissionEarned)}', AppColors.success, true),
        _RevRow('Subscription Revenue (if 50% subscribe)',
            '৳ ${fmt.format(subRevenue.round())} /mo', AppColors.gold, false),
        _RevRow('Premium Badge Revenue',
            '৳ ${fmt.format(premiumRevenue)} /mo', AppColors.gold, false),
        _RevRow('Commission Potential (all bookings)',
            '৳ ${fmt.format(commissionEst)} /mo', AppColors.freshTalent, false),
        const Divider(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Total Potential /mo', style: AppTextStyles.headingSmall),
          Text('৳ ${fmt.format((subRevenue + premiumRevenue + commissionEst).round())}',
              style: AppTextStyles.currencyMedium.copyWith(fontSize: 17, color: AppColors.gold)),
        ]),
        const SizedBox(height: 4),
        Text('Pending transactions: ${stats.pendingTransactions}  ·  Active subscriptions: ${stats.activeSubscriptions}',
            style: AppTextStyles.bodySmall),
      ]),
    ).animate(delay: 100.ms).fadeIn(duration: 350.ms);
  }
}

class _RevRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isReal;
  const _RevRow(this.label, this.value, this.color, this.isReal);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        if (isReal) const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success)
        else const Icon(Icons.trending_up_rounded, size: 14, color: AppColors.charcoalLight),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: AppTextStyles.bodySmall)),
        Text(value, style: AppTextStyles.bodySmall.copyWith(color: color, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

// ── Admin Tools Grid ──────────────────────────────────────────────────────────
class _AdminToolsGrid extends StatelessWidget {
  final BuildContext context;
  const _AdminToolsGrid({required this.context});

  @override
  Widget build(BuildContext context) {
    final tools = [
      ('⚙️', 'Platform\nSettings', AppColors.charcoal,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPlatformSettings()))),
      ('📸', 'Vendor\nManagement', AppColors.gold,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminVendorManagement()))),
      ('👥', 'User\nManagement', AppColors.crimson,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUserManagement()))),
      ('💳', 'Transactions\n& Escrow', AppColors.freshTalent,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminTransactions()))),
      ('👮', 'Junior\nAdmins', AppColors.charcoalMid,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminJuniorAdmins()))),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: tools.asMap().entries.map((e) => GestureDetector(
        onTap: e.value.$4,
        child: GlassCard(
          padding: const EdgeInsets.all(12),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(e.value.$1, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(e.value.$2,
                style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, fontSize: 11),
                textAlign: TextAlign.center),
          ]),
        ).animate(delay: Duration(milliseconds: e.key * 60)).fadeIn(duration: 250.ms),
      )).toList(),
    );
  }
}

// ── Badge Distribution ────────────────────────────────────────────────────────
class _BadgeDistributionCard extends StatelessWidget {
  final PlatformStats stats;
  const _BadgeDistributionCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final total = stats.totalVendors == 0 ? 1 : stats.totalVendors;
    final tiers = [
      (VendorBadgeTier.bronze,   stats.bronzeVendors),
      (VendorBadgeTier.silver,   stats.silverVendors),
      (VendorBadgeTier.gold,     stats.goldVendors),
      (VendorBadgeTier.platinum, stats.platinumVendors),
    ];

    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Vendor Badge Distribution', style: AppTextStyles.headingMedium),
        const SizedBox(height: 14),
        ...tiers.map((t) {
          final pct = t.$2 / total;
          final c = Color(int.parse(t.$1.color.replaceFirst('#', 'FF'), radix: 16));
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              SizedBox(width: 28, child: Text(t.$1.emoji, style: const TextStyle(fontSize: 18))),
              SizedBox(width: 64, child: Text(t.$1.label, style: AppTextStyles.bodySmall)),
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: pct.clamp(0.0, 1.0),
                  backgroundColor: c.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation(c),
                  minHeight: 8,
                ),
              )),
              const SizedBox(width: 10),
              Text('${t.$2}', style: AppTextStyles.headingSmall.copyWith(color: c, fontSize: 13)),
            ]),
          );
        }),
      ]),
    ).animate(delay: 150.ms).fadeIn(duration: 350.ms);
  }
}

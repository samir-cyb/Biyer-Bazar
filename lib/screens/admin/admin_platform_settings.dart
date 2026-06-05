import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../services/platform_settings_service.dart';
import '../../widgets/glass_card.dart';

class AdminPlatformSettings extends StatefulWidget {
  const AdminPlatformSettings({super.key});
  @override
  State<AdminPlatformSettings> createState() => _AdminPlatformSettingsState();
}

class _AdminPlatformSettingsState extends State<AdminPlatformSettings> {
  bool _saving = false;
  late bool _subscriptionEnabled;
  late bool _premiumBadgeEnabled;
  late bool _escrowEnabled;
  late bool _maintenanceMode;
  late int  _freeBidLimit;
  late int  _subPriceMonthly;
  late int  _subPriceAnnual;
  late int  _premiumBadgePrice;
  late double _commissionRate;
  late int  _bookingDepositAmount;
  late int  _maxBidsPerPost;

  late TextEditingController _subMonthlyCtrl;
  late TextEditingController _subAnnualCtrl;
  late TextEditingController _premiumPriceCtrl;
  late TextEditingController _commissionCtrl;
  late TextEditingController _depositCtrl;
  late TextEditingController _maxBidsCtrl;
  late TextEditingController _freeBidCtrl;

  @override
  void initState() {
    super.initState();
    final s = PlatformSettingsService.current;
    _subscriptionEnabled  = s.subscriptionEnabled;
    _premiumBadgeEnabled  = s.premiumBadgeEnabled;
    _escrowEnabled        = s.escrowEnabled;
    _maintenanceMode      = s.maintenanceMode;
    _freeBidLimit         = s.freeBidLimit;
    _subPriceMonthly      = s.subscriptionPriceMonthly;
    _subPriceAnnual       = s.subscriptionPriceAnnual;
    _premiumBadgePrice    = s.premiumBadgePrice;
    _commissionRate       = s.commissionRate;
    _bookingDepositAmount = s.bookingDepositAmount;
    _maxBidsPerPost       = s.maxBidsPerPost;

    _subMonthlyCtrl   = TextEditingController(text: _subPriceMonthly.toString());
    _subAnnualCtrl    = TextEditingController(text: _subPriceAnnual.toString());
    _premiumPriceCtrl = TextEditingController(text: _premiumBadgePrice.toString());
    _commissionCtrl   = TextEditingController(text: _commissionRate.toStringAsFixed(1));
    _depositCtrl      = TextEditingController(text: _bookingDepositAmount.toString());
    _maxBidsCtrl      = TextEditingController(text: _maxBidsPerPost.toString());
    _freeBidCtrl      = TextEditingController(text: _freeBidLimit.toString());
  }

  @override
  void dispose() {
    _subMonthlyCtrl.dispose(); _subAnnualCtrl.dispose();
    _premiumPriceCtrl.dispose(); _commissionCtrl.dispose();
    _depositCtrl.dispose(); _maxBidsCtrl.dispose(); _freeBidCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAll() async {
    setState(() => _saving = true);
    dev.log('[AdminSettings] Saving all platform settings', name: 'BiyerBajar');

    final updates = {
      'subscription_enabled':    _subscriptionEnabled,
      'free_bid_limit':          int.tryParse(_freeBidCtrl.text) ?? 3,
      'subscription_price_monthly': int.tryParse(_subMonthlyCtrl.text) ?? 500,
      'subscription_price_annual':  int.tryParse(_subAnnualCtrl.text) ?? 5000,
      'premium_badge_enabled':   _premiumBadgeEnabled,
      'premium_badge_price':     int.tryParse(_premiumPriceCtrl.text) ?? 1000,
      'escrow_enabled':          _escrowEnabled,
      'commission_rate':         double.tryParse(_commissionCtrl.text) ?? 5.0,
      'booking_deposit_amount':  int.tryParse(_depositCtrl.text) ?? 10000,
      'maintenance_mode':        _maintenanceMode,
      'max_bids_per_post':       int.tryParse(_maxBidsCtrl.text) ?? 7,
    };

    final ok = await PlatformSettingsService.updateAll(updates);
    setState(() => _saving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? '✅ Platform settings saved!' : '❌ Save failed. Check connection.'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
    dev.log('[AdminSettings] Save ${ok ? "succeeded" : "failed"}', name: 'BiyerBajar');
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
        title: Text('Platform Settings', style: AppTextStyles.headingLarge.copyWith(color: Colors.white)),
        actions: [
          if (_saving)
            const Padding(padding: EdgeInsets.all(16),
                child: SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
          else
            IconButton(
              icon: const Icon(Icons.save_rounded, color: Colors.white),
              tooltip: 'Save all',
              onPressed: _saveAll,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Master toggles ─────────────────────────────────────────────
            _SectionHeader('🔄 Master Toggles'),
            GlassCard(
              child: Column(children: [
                _Toggle(
                  title: 'Subscription (Bid Ticket) System',
                  subtitle: _subscriptionEnabled
                      ? 'ON — vendors limited to ${_freeBidCtrl.text} free bids/month'
                      : 'OFF — all vendors have unlimited free bids',
                  value: _subscriptionEnabled,
                  color: AppColors.success,
                  onChanged: (v) {
                    dev.log('[AdminSettings] subscription_enabled → $v', name: 'BiyerBajar');
                    setState(() => _subscriptionEnabled = v);
                  },
                ),
                const Divider(height: 1),
                _Toggle(
                  title: 'Verified Premium Badge',
                  subtitle: 'Allow vendors to pay for top-slot placement',
                  value: _premiumBadgeEnabled,
                  color: AppColors.gold,
                  onChanged: (v) => setState(() => _premiumBadgeEnabled = v),
                ),
                const Divider(height: 1),
                _Toggle(
                  title: 'Escrow / Deposit System',
                  subtitle: 'Hosts pay deposit inside app before event',
                  value: _escrowEnabled,
                  color: AppColors.freshTalent,
                  onChanged: (v) => setState(() => _escrowEnabled = v),
                ),
                const Divider(height: 1),
                _Toggle(
                  title: '⚠️ Maintenance Mode',
                  subtitle: 'Blocks all users except admins',
                  value: _maintenanceMode,
                  color: AppColors.error,
                  onChanged: (v) => setState(() => _maintenanceMode = v),
                ),
              ]),
            ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 20),

            // ── Bid Ticket Config ──────────────────────────────────────────
            _SectionHeader('🎫 Bid Ticket Configuration'),
            GlassCard(
              child: Column(children: [
                _NumField(_freeBidCtrl, 'Free Bids Per Month',
                    'Vendors get this many free bids before paywall kicks in', Icons.confirmation_num_rounded),
                const SizedBox(height: 12),
                _NumField(_subMonthlyCtrl, 'Monthly Subscription Price (BDT)',
                    'e.g. 500 BDT', Icons.calendar_month_rounded),
                const SizedBox(height: 12),
                _NumField(_subAnnualCtrl, 'Annual Subscription Price (BDT)',
                    'e.g. 5000 BDT (save 2 months)', Icons.calendar_today_rounded),
              ]),
            ).animate(delay: 50.ms).fadeIn(duration: 300.ms),
            const SizedBox(height: 20),

            // ── Premium Badge Config ───────────────────────────────────────
            _SectionHeader('💎 Premium Badge Configuration'),
            GlassCard(
              child: _NumField(_premiumPriceCtrl, 'Premium Badge Price (BDT/month)',
                  'Vendors pay this to get top slot placement', Icons.workspace_premium_rounded),
            ).animate(delay: 80.ms).fadeIn(duration: 300.ms),
            const SizedBox(height: 20),

            // ── Commission & Escrow ────────────────────────────────────────
            _SectionHeader('💳 Commission & Escrow'),
            GlassCard(
              child: Column(children: [
                _NumField(_commissionCtrl, 'Commission Rate (%)',
                    'Platform keeps this % of each booking', Icons.percent_rounded,
                    isDecimal: true),
                const SizedBox(height: 12),
                _NumField(_depositCtrl, 'Booking Deposit Amount (BDT)',
                    'Fixed upfront deposit from host', Icons.lock_rounded),
              ]),
            ).animate(delay: 110.ms).fadeIn(duration: 300.ms),
            const SizedBox(height: 20),

            // ── General ────────────────────────────────────────────────────
            _SectionHeader('📋 General'),
            GlassCard(
              child: _NumField(_maxBidsCtrl, 'Max Bids Per Post',
                  'Host sees max this many vendor bids', Icons.gavel_rounded),
            ).animate(delay: 130.ms).fadeIn(duration: 300.ms),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _saveAll,
                icon: _saving
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(_saving ? 'Saving...' : 'Save All Settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.charcoal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: AppTextStyles.headingMedium),
    );
  }
}

class _Toggle extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;
  const _Toggle({required this.title, required this.subtitle, required this.value,
      required this.color, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title, style: AppTextStyles.headingSmall),
      subtitle: Text(subtitle, style: AppTextStyles.bodySmall),
      value: value,
      activeColor: color,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
    );
  }
}

class _NumField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final IconData icon;
  final bool isDecimal;
  const _NumField(this.ctrl, this.label, this.hint, this.icon, {this.isDecimal = false});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isDecimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      inputFormatters: isDecimal
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))]
          : [FilteringTextInputFormatter.digitsOnly],
      style: AppTextStyles.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.charcoalLight, size: 20),
      ),
    );
  }
}

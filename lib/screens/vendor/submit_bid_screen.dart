import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../models/post_model.dart';
import '../../services/auth_service.dart';
import '../../services/bid_service.dart';
import '../../services/platform_settings_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/mesh_background.dart';

class SubmitBidScreen extends StatefulWidget {
  final EventPost post;
  const SubmitBidScreen({super.key, required this.post});

  @override
  State<SubmitBidScreen> createState() => _SubmitBidScreenState();
}

class _SubmitBidScreenState extends State<SubmitBidScreen> {
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _serviceCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  @override
  void dispose() {
    _priceCtrl.dispose();
    _descCtrl.dispose();
    _serviceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final vendor = AuthService.currentUser;
    if (vendor == null) return;

    // ── Bid Ticket enforcement ─────────────────────────────────────────────
    final canBid = PlatformSettingsService.canVendorBidFree(vendor.freeBidsUsedThisMonth);
    dev.log('[BidTicket] vendor=${vendor.id} freeBidsUsed=${vendor.freeBidsUsedThisMonth} canBid=$canBid',
        name: 'BiyerBajar');

    if (!canBid) {
      _showSubscriptionGate();
      return;
    }

    setState(() => _loading = true);

    final services = _serviceCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final bid = await BidService.submitBid(
      vendor: vendor,
      postId: widget.post.id,
      quotedPrice: int.tryParse(_priceCtrl.text) ?? 0,
      packageDescription: _descCtrl.text.trim(),
      includedServices: services,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (bid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You already bid on this event.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('🎉 Bid submitted! The host will review it.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    Navigator.pop(context);
  }

  void _showSubscriptionGate() {
    final settings = PlatformSettingsService.current;
    dev.log('[BidTicket] Showing subscription gate — price ৳${settings.subscriptionPriceMonthly}/mo',
        name: 'BiyerBajar');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8F4F0),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎫', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('Bid Ticket Required', style: AppTextStyles.displaySmall),
            const SizedBox(height: 8),
            Text(
              'You have used all ${settings.freeBidLimit} free bids this month.\n'
              'Subscribe to continue bidding on unlimited events.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GlassCard(
              backgroundColor: AppColors.gold.withOpacity(0.07),
              borderColor: AppColors.gold.withOpacity(0.3),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Monthly Plan', style: AppTextStyles.headingMedium),
                    Text('Unlimited bids for 30 days', style: AppTextStyles.bodySmall),
                  ]),
                  Text('৳ ${settings.subscriptionPriceMonthly}',
                      style: AppTextStyles.currencyMedium.copyWith(color: AppColors.gold)),
                ]),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => _SubscriptionPaymentScreen(
                          plan: 'monthly',
                          price: settings.subscriptionPriceMonthly,
                        ),
                      ));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Subscribe — Pay via bKash/Nagad'),
                  ),
                ),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Annual Plan', style: AppTextStyles.headingSmall),
                    Text('Save 2 months free', style: AppTextStyles.bodySmall),
                  ]),
                  Text('৳ ${settings.subscriptionPriceAnnual}',
                      style: AppTextStyles.headingSmall.copyWith(color: AppColors.charcoalMid)),
                ]),
              ]),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Not now', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.charcoalLight)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = PlatformSettingsService.current;
    final vendor   = AuthService.currentUser;
    final bidsLeft = settings.subscriptionEnabled
        ? (settings.freeBidLimit - (vendor?.freeBidsUsedThisMonth ?? 0)).clamp(0, 99)
        : -1; // -1 = unlimited

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.charcoal, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Submit Bid', style: AppTextStyles.headingLarge),
      ),
      body: StaticMeshBackground(child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Bid Ticket status banner ─────────────────────────────────
              if (settings.subscriptionEnabled)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: bidsLeft <= 1
                        ? AppColors.warning.withOpacity(0.1)
                        : AppColors.freshTalent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: bidsLeft <= 1
                          ? AppColors.warning.withOpacity(0.3)
                          : AppColors.freshTalent.withOpacity(0.25),
                    ),
                  ),
                  child: Row(children: [
                    Text(bidsLeft <= 0 ? '⚠️' : '🎫', style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(
                      bidsLeft > 0
                          ? '$bidsLeft free bid${bidsLeft == 1 ? "" : "s"} remaining this month'
                          : 'No free bids left — subscribe to continue',
                      style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                    )),
                  ]),
                ),
              // Event Summary
              GlassCard(
                backgroundColor: AppColors.crimson.withOpacity(0.05),
                borderColor: AppColors.crimson.withOpacity(0.15),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.article_rounded,
                            size: 18, color: AppColors.crimson),
                        const SizedBox(width: 8),
                        Text('You are bidding on:',
                            style: AppTextStyles.labelLarge
                                .copyWith(color: AppColors.crimson)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(widget.post.serviceCategory,
                        style: AppTextStyles.headingMedium),
                    const SizedBox(height: 4),
                    Text(widget.post.description,
                        style: AppTextStyles.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _Pill(Icons.location_on_rounded,
                            widget.post.location),
                        const SizedBox(width: 8),
                        _Pill(Icons.people_rounded,
                            '${widget.post.guestCapacity} guests'),
                        const SizedBox(width: 8),
                        _Pill(Icons.payments_rounded,
                            'Cap: ৳${widget.post.budgetCeiling}'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Blind bid notice
              GlassCard(
                backgroundColor: AppColors.charcoal.withOpacity(0.04),
                borderColor: AppColors.charcoal.withOpacity(0.1),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.lock_rounded,
                        size: 18, color: AppColors.charcoalMid),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Blind bidding is active. Your price is hidden from competing vendors. Only the host can see your full bid.',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text('Your Bid Details', style: AppTextStyles.headingLarge),
              const SizedBox(height: 14),

              GlassCard(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      style: AppTextStyles.headingMedium,
                      decoration: InputDecoration(
                        labelText: 'Your Quote (BDT)',
                        hintText:
                            'Must be ≤ ৳${widget.post.budgetCeiling}',
                        prefixText: '৳  ',
                        prefixStyle: AppTextStyles.currencyMedium
                            .copyWith(fontSize: 16),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Enter your quoted price';
                        }
                        final val = int.tryParse(v);
                        if (val == null || val <= 0) {
                          return 'Enter a valid amount';
                        }
                        if (val > widget.post.budgetCeiling) {
                          return 'Quote exceeds budget ceiling (৳${widget.post.budgetCeiling})';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 4,
                      style: AppTextStyles.bodyLarge,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Package Description',
                        hintText:
                            'Describe what you offer — coverage hours, deliverables, style...',
                        alignLabelWithHint: true,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Describe your package'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _serviceCtrl,
                      style: AppTextStyles.bodyLarge,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Included Services',
                        hintText:
                            'e.g. Full-day coverage, Edited gallery, Drone shots',
                        helperText:
                            'Separate each service with a comma',
                        prefixIcon: Icon(Icons.checklist_rounded,
                            color: AppColors.charcoalLight),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'List at least one included service'
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon: const Icon(Icons.gavel_rounded, size: 18),
                  label: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Submit Blind Bid'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 17),
                  ),
                ),
              ),
            ]
                .animate(interval: 60.ms)
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.08, end: 0),
          ),
        ),
      )),
    );
  }
}

// ── Subscription Payment Screen (bKash/Nagad UI placeholder) ─────────────────
class _SubscriptionPaymentScreen extends StatefulWidget {
  final String plan;
  final int price;
  const _SubscriptionPaymentScreen({required this.plan, required this.price});
  @override
  State<_SubscriptionPaymentScreen> createState() => _SubscriptionPaymentScreenState();
}

class _SubscriptionPaymentScreenState extends State<_SubscriptionPaymentScreen> {
  String _selectedMethod = 'bkash';
  final _refCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() { _refCtrl.dispose(); super.dispose(); }

  void _submit() async {
    if (_refCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter your transaction ID'),
        backgroundColor: AppColors.warning,
      ));
      return;
    }
    setState(() => _submitting = true);
    dev.log('[Payment] Subscription payment submitted via $_selectedMethod ref:${_refCtrl.text}',
        name: 'BiyerBajar');
    // In production this would call an API / Edge Function
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _submitting = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('✅ Payment submitted! Admin will activate your subscription.'),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.charcoal, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Subscribe to Utsob', style: AppTextStyles.headingLarge),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassCard(
              backgroundColor: AppColors.gold.withOpacity(0.07),
              borderColor: AppColors.gold.withOpacity(0.3),
              child: Row(children: [
                const Text('🎫', style: TextStyle(fontSize: 36)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${widget.plan == 'annual' ? 'Annual' : 'Monthly'} Plan',
                      style: AppTextStyles.headingMedium),
                  Text('Unlimited bids • ${widget.plan == 'annual' ? '12 months' : '30 days'}',
                      style: AppTextStyles.bodySmall),
                ])),
                Text('৳ ${widget.price}',
                    style: AppTextStyles.currencyMedium.copyWith(color: AppColors.gold)),
              ]),
            ),
            const SizedBox(height: 24),

            Text('Choose Payment Method', style: AppTextStyles.headingMedium),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _PayMethodCard('bkash', '🟣 bKash', _selectedMethod == 'bkash',
                  () => setState(() => _selectedMethod = 'bkash'))),
              const SizedBox(width: 12),
              Expanded(child: _PayMethodCard('nagad', '🟠 Nagad', _selectedMethod == 'nagad',
                  () => setState(() => _selectedMethod = 'nagad'))),
            ]),
            const SizedBox(height: 24),

            GlassCard(
              backgroundColor: AppColors.charcoal.withOpacity(0.04),
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Payment Instructions', style: AppTextStyles.headingSmall),
                const SizedBox(height: 12),
                _Step('1', 'Open your ${_selectedMethod == 'bkash' ? 'bKash' : 'Nagad'} app'),
                _Step('2', 'Send ৳ ${widget.price} to merchant number:'),
                Container(
                  margin: const EdgeInsets.only(left: 28, bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.charcoal.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _selectedMethod == 'bkash' ? '01XXXXXXXXXX (bKash Merchant)' : '01XXXXXXXXXX (Nagad Merchant)',
                    style: AppTextStyles.headingSmall.copyWith(letterSpacing: 1),
                  ),
                ),
                _Step('3', 'Copy the Transaction ID and paste below'),
              ]),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _refCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: '${_selectedMethod == 'bkash' ? 'bKash' : 'Nagad'} Transaction ID',
                hintText: 'e.g. 8N7A2B3C4D',
                prefixIcon: const Icon(Icons.receipt_long_rounded, color: AppColors.charcoalLight, size: 20),
              ),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_rounded, size: 18),
                label: Text(_submitting ? 'Submitting...' : 'Confirm Payment →'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your subscription will be activated within a few minutes after admin confirms your payment.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PayMethodCard extends StatelessWidget {
  final String id;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PayMethodCard(this.id, this.label, this.selected, this.onTap);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.charcoal.withOpacity(0.08) : Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.charcoal : AppColors.charcoal.withOpacity(0.12),
            width: selected ? 2 : 1,
          ),
        ),
        child: Center(child: Text(label, style: AppTextStyles.headingSmall)),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String n;
  final String text;
  const _Step(this.n, this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Container(
          width: 22, height: 22,
          decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.charcoal.withOpacity(0.1)),
          child: Center(child: Text(n, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, fontSize: 11))),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: AppTextStyles.bodySmall)),
      ]),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Pill(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.overlayDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.charcoalLight),
          const SizedBox(width: 4),
          Text(label,
              style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}

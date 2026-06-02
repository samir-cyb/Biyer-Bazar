import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../models/post_model.dart';
import '../../services/auth_service.dart';
import '../../services/bid_service.dart';
import '../../widgets/glass_card.dart';

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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final vendor = AuthService.currentUser;
    if (vendor == null) return;

    setState(() => _loading = true);

    final services = _serviceCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final bid = BidService.submitBid(
      vendor: vendor,
      postId: widget.post.id,
      quotedPrice: int.tryParse(_priceCtrl.text) ?? 0,
      packageDescription: _descCtrl.text.trim(),
      includedServices: services,
    );

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.charcoal, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Submit Bid', style: AppTextStyles.headingLarge),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
      ),
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

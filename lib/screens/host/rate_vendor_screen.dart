import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../models/bid_model.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/review_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/mesh_background.dart';

class RateVendorScreen extends StatefulWidget {
  final EventPost post;
  final Bid acceptedBid;
  const RateVendorScreen({super.key, required this.post, required this.acceptedBid});
  @override
  State<RateVendorScreen> createState() => _RateVendorScreenState();
}

class _RateVendorScreenState extends State<RateVendorScreen> {
  double _rating = 5.0;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;
  bool _alreadyReviewed = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkExisting();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkExisting() async {
    final user = AuthService.currentUser;
    if (user == null) return;
    final done = await ReviewService.hasReviewed(
        widget.post.id, user.id, widget.acceptedBid.vendorId);
    setState(() { _alreadyReviewed = done; _checking = false; });
  }

  Future<void> _submit() async {
    final user = AuthService.currentUser;
    if (user == null) return;
    setState(() => _submitting = true);

    final success = await ReviewService.submitReview(
      postId:   widget.post.id,
      hostId:   user.id,
      vendorId: widget.acceptedBid.vendorId,
      rating:   _rating.round(),
      comment:  _commentCtrl.text.trim(),
    );

    setState(() => _submitting = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('✅ Review submitted! Vendor badge updated automatically.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Failed to submit review. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
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
        title: Text('Rate Your Vendor', style: AppTextStyles.headingLarge),
      ),
      body: StaticMeshBackground(child: _checking
          ? const Center(child: CircularProgressIndicator(color: AppColors.crimson))
          : _alreadyReviewed
              ? _AlreadyReviewedState()
              : _buildForm()),
    );
  }

  Widget _buildForm() {
    final bid = widget.acceptedBid;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vendor info header
          GlassCard(
            backgroundColor: AppColors.gold.withOpacity(0.06),
            borderColor: AppColors.gold.withOpacity(0.2),
            child: Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: AppColors.gold.withOpacity(0.15),
                    border: Border.all(color: AppColors.gold.withOpacity(0.3), width: 1.5)),
                child: Center(child: Text(
                  bid.vendorBusinessName.isNotEmpty ? bid.vendorBusinessName[0].toUpperCase() : 'V',
                  style: AppTextStyles.headingLarge.copyWith(color: AppColors.gold, fontSize: 22),
                )),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(bid.vendorBusinessName, style: AppTextStyles.headingMedium),
                Text(bid.vendorCategory, style: AppTextStyles.bodySmall),
                Text(bid.vendorLocation, style: AppTextStyles.bodySmall.copyWith(color: AppColors.charcoalLight)),
              ])),
              _BadgeMini(tier: _parseBadge(bid.vendorBadgeTier)),
            ]),
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 24),

          // Event info
          Text('Event: ${widget.post.serviceCategory}', style: AppTextStyles.headingSmall),
          Text('${widget.post.location}  ·  ${widget.post.eventDate.day}/${widget.post.eventDate.month}/${widget.post.eventDate.year}',
              style: AppTextStyles.bodySmall),
          const SizedBox(height: 24),

          // Star rating
          Text('How would you rate this vendor?', style: AppTextStyles.headingMedium),
          const SizedBox(height: 6),
          Text('Be honest — your rating helps other hosts make better decisions.',
              style: AppTextStyles.bodySmall),
          const SizedBox(height: 20),
          Center(
            child: RatingBar.builder(
              initialRating: _rating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: false,
              itemCount: 5,
              itemSize: 52,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4),
              itemBuilder: (context, _) => const Icon(Icons.star_rounded, color: AppColors.gold),
              onRatingUpdate: (r) => setState(() => _rating = r),
            ),
          ),
          const SizedBox(height: 10),
          Center(child: Text(_ratingLabel(_rating.round()),
              style: AppTextStyles.headingMedium.copyWith(color: AppColors.gold))),
          const SizedBox(height: 24),

          // Badge preview
          _BadgePreview(rating: _rating),
          const SizedBox(height: 20),

          // Comment
          GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Write a Review', style: AppTextStyles.headingSmall),
              const SizedBox(height: 10),
              TextFormField(
                controller: _commentCtrl,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Share your experience — quality, punctuality, professionalism...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: AppTextStyles.bodyMedium,
              ),
            ]),
          ).animate(delay: 100.ms).fadeIn(duration: 300.ms),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.star_rounded, size: 18),
              label: Text(_submitting ? 'Submitting...' : 'Submit Review'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ).animate(delay: 150.ms).fadeIn(duration: 300.ms),
        ],
      ),
    );
  }

  String _ratingLabel(int r) {
    switch (r) {
      case 5: return 'Excellent! ⭐⭐⭐⭐⭐';
      case 4: return 'Very Good';
      case 3: return 'Good';
      case 2: return 'Fair';
      default: return 'Poor';
    }
  }

  VendorBadgeTier _parseBadge(String? t) {
    switch (t) {
      case 'silver':   return VendorBadgeTier.silver;
      case 'gold':     return VendorBadgeTier.gold;
      case 'platinum': return VendorBadgeTier.platinum;
      default:         return VendorBadgeTier.bronze;
    }
  }
}

class _BadgeMini extends StatelessWidget {
  final VendorBadgeTier tier;
  const _BadgeMini({required this.tier});
  @override
  Widget build(BuildContext context) {
    final c = Color(int.parse(tier.color.replaceFirst('#', 'FF'), radix: 16));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.withOpacity(0.3))),
      child: Text('${tier.emoji} ${tier.label}',
          style: AppTextStyles.bodySmall.copyWith(color: c, fontWeight: FontWeight.w700, fontSize: 10)),
    );
  }
}

class _BadgePreview extends StatelessWidget {
  final double rating;
  const _BadgePreview({required this.rating});

  @override
  Widget build(BuildContext context) {
    final r = rating.round();
    String note;
    if (r == 5)      note = 'This rating contributes toward Gold & Platinum badges.';
    else if (r >= 4) note = 'This rating contributes toward Silver & Gold badges.';
    else if (r >= 3) note = 'This rating contributes toward Silver badge.';
    else             note = 'This rating may lower the vendor\'s current badge.';

    return GlassCard(
      backgroundColor: AppColors.charcoal.withOpacity(0.04),
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        const Text('🏅', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Badge System', style: AppTextStyles.headingSmall),
          const SizedBox(height: 4),
          Text('🥉 Bronze: new vendors  ·  🥈 Silver: ≥3.5★ (3+ reviews)\n'
               '🥇 Gold: ≥4.0★ (5+)  ·  💎 Platinum: ≥4.5★ (10+)',
               style: AppTextStyles.bodySmall.copyWith(height: 1.5)),
          const SizedBox(height: 4),
          Text(note, style: AppTextStyles.bodySmall.copyWith(color: AppColors.gold, fontWeight: FontWeight.w600)),
        ])),
      ]),
    );
  }
}

class _AlreadyReviewedState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('✅', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text('Already Reviewed', style: AppTextStyles.headingLarge),
          const SizedBox(height: 8),
          Text('You have already submitted a review for this vendor.',
              style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ]),
      ),
    );
  }
}

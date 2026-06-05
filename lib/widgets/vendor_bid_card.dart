import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/app_colors.dart';
import '../core/app_text_styles.dart';
import '../models/vendor_model.dart';
import 'glass_card.dart';

class VendorBidCard extends StatefulWidget {
  final VendorBid bid;
  final int slotIndex; // 0-indexed, 0-1 = premium, 2-4 = verified, 5-6 = fresh
  final VoidCallback? onSelect;

  const VendorBidCard({
    super.key,
    required this.bid,
    required this.slotIndex,
    this.onSelect,
  });

  @override
  State<VendorBidCard> createState() => _VendorBidCardState();
}

class _VendorBidCardState extends State<VendorBidCard> {
  bool _priceRevealed = false;

  VendorTier get _tier {
    if (widget.slotIndex <= 1) return VendorTier.premium;
    if (widget.slotIndex <= 4) return VendorTier.verified;
    return VendorTier.freshTalent;
  }

  Widget _buildCard(Widget cardChild) {
    switch (_tier) {
      case VendorTier.premium:
        return GoldGlassCard(
          padding: const EdgeInsets.all(0),
          child: cardChild,
        );
      case VendorTier.freshTalent:
        return FreshTalentGlassCard(
          padding: const EdgeInsets.all(0),
          child: cardChild,
        );
      case VendorTier.verified:
        return GlassCard(
          padding: const EdgeInsets.all(0),
          backgroundColor: Colors.white.withOpacity(0.65),
          borderColor: AppColors.verifiedSilver.withOpacity(0.25),
          child: cardChild,
        );
    }
  }

  Widget _buildTierBadge() {
    switch (_tier) {
      case VendorTier.premium:
        return _Badge(
          label: '★ PREMIUM',
          textColor: AppColors.charcoal,
          backgroundColor: AppColors.gold,
        );
      case VendorTier.verified:
        return _Badge(
          label: '✓ VERIFIED',
          textColor: Colors.white,
          backgroundColor: AppColors.charcoalMid,
        );
      case VendorTier.freshTalent:
        return _Badge(
          label: '✦ FRESH TALENT',
          textColor: Colors.white,
          backgroundColor: AppColors.freshTalent,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendor = widget.bid.vendor;
    final cardContent = _buildCard(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PortfolioStrip(imageUrls: vendor.portfolioImageUrls),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTierBadge(),
                    _RatingChip(rating: vendor.rating),
                  ],
                ),
                const SizedBox(height: 10),
                Text(vendor.name, style: AppTextStyles.headingLarge),
                const SizedBox(height: 4),
                Text(vendor.tagline,
                    style: AppTextStyles.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _InfoChip(icon: Icons.category_rounded, label: vendor.category.label),
                    const SizedBox(width: 8),
                    _InfoChip(icon: Icons.location_on_rounded, label: vendor.location),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Package Includes', style: AppTextStyles.labelLarge),
                const SizedBox(height: 6),
                ...widget.bid.includedServices.take(3).map((service) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(children: [
                        Icon(Icons.check_circle_rounded, size: 13, color: AppColors.success),
                        const SizedBox(width: 6),
                        Expanded(child: Text(service, style: AppTextStyles.bodySmall)),
                      ]),
                    )),
                if (widget.bid.includedServices.length > 3)
                  Text('+${widget.bid.includedServices.length - 3} more services',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.crimson, fontWeight: FontWeight.w600)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _PriceRevealButton(
                        isRevealed: _priceRevealed,
                        price: widget.bid.quotedPrice,
                        onReveal: () => setState(() => _priceRevealed = true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _SelectButton(onTap: widget.onSelect),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return TiltCard(child: cardContent)
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: widget.slotIndex * 120),
          duration: 400.ms,
        )
        .slideY(begin: 0.15, end: 0, curve: Curves.easeOut);
  }
}

class _PortfolioStrip extends StatelessWidget {
  final List<String> imageUrls;
  const _PortfolioStrip({required this.imageUrls});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: Row(
        children: List.generate(
          imageUrls.length.clamp(0, 3),
          (i) => Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 2 ? 2 : 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: i == 0 ? const Radius.circular(20) : Radius.zero,
                  topRight:
                      i == 2 ? const Radius.circular(20) : Radius.zero,
                ),
                color: AppColors.surface,
                image: DecorationImage(
                  image: NetworkImage(imageUrls[i]),
                  fit: BoxFit.cover,
                  onError: (_, __) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color backgroundColor;
  const _Badge(
      {required this.label,
      required this.textColor,
      required this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(
          color: textColor,
          fontSize: 10,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _RatingChip extends StatelessWidget {
  final double rating;
  const _RatingChip({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, size: 14, color: AppColors.gold),
        const SizedBox(width: 3),
        Text(
          rating.toStringAsFixed(1),
          style: AppTextStyles.headingSmall.copyWith(
            fontSize: 13,
            color: AppColors.charcoal,
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

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

class _PriceRevealButton extends StatelessWidget {
  final bool isRevealed;
  final int price;
  final VoidCallback onReveal;
  const _PriceRevealButton(
      {required this.isRevealed,
      required this.price,
      required this.onReveal});

  @override
  Widget build(BuildContext context) {
    if (isRevealed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.crimson.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.crimson.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('৳ ', style: AppTextStyles.bodySmall.copyWith(color: AppColors.crimson)),
            Text(
              _formatBDT(price),
              style: AppTextStyles.currencyMedium.copyWith(fontSize: 16),
            ),
          ],
        ),
      ).animate().scale(begin: const Offset(0.8, 0.8), curve: Curves.elasticOut);
    }
    return GestureDetector(
      onTap: onReveal,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.charcoal.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.charcoal.withOpacity(0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_rounded, size: 13, color: AppColors.charcoalLight),
            const SizedBox(width: 5),
            Text('Reveal Quote', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  String _formatBDT(int amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toString();
  }
}

class _SelectButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _SelectButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.crimson,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.crimson.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          'Select',
          style: AppTextStyles.headingSmall.copyWith(
            color: Colors.white,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

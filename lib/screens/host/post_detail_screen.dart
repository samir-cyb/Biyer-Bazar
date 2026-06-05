import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../models/bid_model.dart';
import '../../models/post_model.dart';
import '../../services/bid_service.dart';
import '../../services/post_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/mesh_background.dart';
import 'package:intl/intl.dart';
import 'rate_vendor_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final EventPost post;
  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  List<Bid> _curatedBids = [];
  final _fmt = NumberFormat('#,##,###', 'en_IN');

  @override
  void initState() {
    super.initState();
    _loadBids();
  }

  Future<void> _loadBids() async {
    final bids = await BidService.getCuratedBidsForHost(
      widget.post.id,
      widget.post.location,
    );
    if (mounted) setState(() => _curatedBids = bids);
  }

  String _slotLabel(int index) {
    if (index <= 1) return '⭐ Premium';
    if (index <= 4) return '✓ Verified';
    return '✦ Fresh Talent';
  }

  Color _slotColor(int index) {
    if (index <= 1) return AppColors.gold;
    if (index <= 4) return AppColors.charcoalMid;
    return AppColors.freshTalent;
  }

  void _acceptBid(Bid bid) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Confirm Selection', style: AppTextStyles.headingLarge),
        content: Text(
          'Select ${bid.vendorBusinessName} for this event? All other bids will be closed.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              PostService.acceptBid(widget.post.id, bid.id);
              Navigator.pop(context);
              Navigator.pop(context); // back to list
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '🎉 ${bid.vendorBusinessName} selected! Deposit request coming soon.'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            child: const Text('✅  Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StaticMeshBackground(child: CustomScrollView(
        slivers: [
          _buildHeader(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _PostInfoCard(post: widget.post, fmt: _fmt),
                const SizedBox(height: 20),
                // ── Rate Vendor Banner (booked posts) ──────────────────────
                if (widget.post.status == PostStatus.booked &&
                    widget.post.selectedBidId != null) ...[
                  _RateVendorBanner(
                    post: widget.post,
                    bids: _curatedBids,
                  ),
                  const SizedBox(height: 16),
                ],
                if (_curatedBids.isEmpty)
                  _EmptyBidsCard()
                else ...[
                  Row(
                    children: [
                      Text('${_curatedBids.length} Curated Bids',
                          style: AppTextStyles.headingLarge),
                      const Spacer(),
                      _LegendRow(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._curatedBids.asMap().entries.map((e) => TiltCard(
                        child: _BidCard(
                          bid: e.value,
                          index: e.key,
                          slotLabel: _slotLabel(e.key),
                          slotColor: _slotColor(e.key),
                          fmt: _fmt,
                          canAccept: widget.post.status == PostStatus.open,
                          onAccept: () => _acceptBid(e.value),
                        ),
                      )),
                ],
              ]),
            ),
          ),
        ],
      )),
    );
  }

  SliverAppBar _buildHeader() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded,
            color: AppColors.charcoal, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(widget.post.serviceCategory,
          style: AppTextStyles.headingLarge),
      actions: [
        if (widget.post.status == PostStatus.open)
          TextButton(
            onPressed: () {
              PostService.cancelPost(widget.post.id);
              Navigator.pop(context);
            },
            child: Text('Cancel Post',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.error)),
          ),
      ],
    );
  }
}

class _PostInfoCard extends StatelessWidget {
  final EventPost post;
  final NumberFormat fmt;
  const _PostInfoCard({required this.post, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      backgroundColor: AppColors.crimson.withOpacity(0.05),
      borderColor: AppColors.crimson.withOpacity(0.15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(post.description,
                    style: AppTextStyles.bodyMedium, maxLines: 3,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Budget Cap', style: AppTextStyles.bodySmall),
                  Text('৳ ${fmt.format(post.budgetCeiling)}',
                      style: AppTextStyles.currencyMedium),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _Chip(Icons.location_on_rounded, post.location),
              _Chip(Icons.people_rounded, '${post.guestCapacity} guests'),
              _Chip(
                Icons.calendar_month_rounded,
                '${post.eventDate.day}/${post.eventDate.month}/${post.eventDate.year}',
              ),
              _Chip(Icons.flag_rounded, '${post.daysUntilEvent} days away'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.overlayDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.charcoalLight),
          const SizedBox(width: 5),
          Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}

class _EmptyBidsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const Text('⏳', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 14),
          Text('Waiting for Bids', style: AppTextStyles.headingMedium),
          const SizedBox(height: 6),
          Text(
            'Vendors are reviewing your post. Bids typically arrive within 24–48 hours.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Dot(color: AppColors.gold, label: 'Prem'),
        const SizedBox(width: 8),
        _Dot(color: AppColors.charcoalMid, label: 'Ver'),
        const SizedBox(width: 8),
        _Dot(color: AppColors.freshTalent, label: 'Fresh'),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final String label;
  const _Dot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7, height: 7,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 3),
        Text(label,
            style: AppTextStyles.bodySmall.copyWith(fontSize: 9)),
      ],
    );
  }
}

class _BidCard extends StatefulWidget {
  final Bid bid;
  final int index;
  final String slotLabel;
  final Color slotColor;
  final NumberFormat fmt;
  final bool canAccept;
  final VoidCallback onAccept;
  const _BidCard({
    required this.bid,
    required this.index,
    required this.slotLabel,
    required this.slotColor,
    required this.fmt,
    required this.canAccept,
    required this.onAccept,
  });

  @override
  State<_BidCard> createState() => _BidCardState();
}

class _BidCardState extends State<_BidCard> {
  bool _priceRevealed = false;

  @override
  Widget build(BuildContext context) {
    final bid = widget.bid;
    final isFresh = widget.index >= 5;
    final isGold = widget.index <= 1;

    Widget card = GlassCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(0),
      backgroundColor: isGold
          ? AppColors.premiumGoldBg
          : isFresh
              ? AppColors.freshTalentBg
              : Colors.white.withOpacity(0.65),
      borderColor: isGold
          ? AppColors.gold.withOpacity(0.4)
          : isFresh
              ? AppColors.freshTalent.withOpacity(0.4)
              : AppColors.charcoal.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header strip
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: widget.slotColor.withOpacity(0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.slotColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.slotLabel,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: isGold
                          ? AppColors.charcoal
                          : Colors.white,
                      fontSize: 9,
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 13, color: AppColors.gold),
                    const SizedBox(width: 3),
                    Text(bid.vendorRating.toStringAsFixed(1),
                        style: AppTextStyles.headingSmall
                            .copyWith(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bid.vendorBusinessName,
                    style: AppTextStyles.headingLarge),
                const SizedBox(height: 2),
                Text(bid.vendorCategory,
                    style: AppTextStyles.bodySmall),
                const SizedBox(height: 10),
                Text(bid.packageDescription,
                    style: AppTextStyles.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: bid.includedServices
                      .take(4)
                      .map((s) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.overlayDark,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('✓ $s',
                                style: AppTextStyles.bodySmall
                                    .copyWith(fontSize: 10)),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _PriceReveal(
                      isRevealed: _priceRevealed,
                      price: bid.quotedPrice,
                      fmt: widget.fmt,
                      onReveal: () => setState(() => _priceRevealed = true),
                    )),
                    const SizedBox(width: 10),
                    if (widget.canAccept)
                      ElevatedButton(
                        onPressed: widget.onAccept,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                        ),
                        child: const Text('Select'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (isFresh) {
      // Wrap fresh talent in animated glow
      return _GlowWrapper(child: card, index: widget.index);
    }

    return card
        .animate(delay: Duration(milliseconds: widget.index * 100))
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.1, end: 0);
  }
}

class _GlowWrapper extends StatefulWidget {
  final Widget child;
  final int index;
  const _GlowWrapper({required this.child, required this.index});

  @override
  State<_GlowWrapper> createState() => _GlowWrapperState();
}

class _GlowWrapperState extends State<_GlowWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.2, end: 0.7)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.freshTalent.withOpacity(_anim.value * 0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: child,
      ),
      child: widget.child
          .animate(delay: Duration(milliseconds: widget.index * 100))
          .fadeIn(duration: 350.ms)
          .slideY(begin: 0.1, end: 0),
    );
  }
}

// ── Rate Vendor Banner ────────────────────────────────────────────────────────
class _RateVendorBanner extends StatelessWidget {
  final EventPost post;
  final List<Bid> bids;
  const _RateVendorBanner({required this.post, required this.bids});

  @override
  Widget build(BuildContext context) {
    final acceptedBid = bids.where((b) => b.id == post.selectedBidId).isNotEmpty
        ? bids.firstWhere((b) => b.id == post.selectedBidId)
        : (bids.isNotEmpty ? bids.first : null);

    return GlassCard(
      backgroundColor: AppColors.gold.withOpacity(0.07),
      borderColor: AppColors.gold.withOpacity(0.25),
      child: Row(children: [
        const Text('⭐', style: TextStyle(fontSize: 28)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Event Completed?', style: AppTextStyles.headingMedium),
          Text('Rate your vendor and help them earn a badge.',
              style: AppTextStyles.bodySmall),
        ])),
        ElevatedButton(
          onPressed: acceptedBid == null ? null : () {
            Navigator.push(context, PageRouteBuilder(
              pageBuilder: (_, __, ___) => RateVendorScreen(
                post: post, acceptedBid: acceptedBid),
              transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
            ));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          child: const Text('Rate Now'),
        ),
      ]),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05, end: 0);
  }
}

class _PriceReveal extends StatelessWidget {
  final bool isRevealed;
  final int price;
  final NumberFormat fmt;
  final VoidCallback onReveal;
  const _PriceReveal(
      {required this.isRevealed, required this.price, required this.fmt, required this.onReveal});

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
            Text('${fmt.format(price)} BDT',
                style: AppTextStyles.currencyMedium.copyWith(fontSize: 15)),
          ],
        ),
      ).animate().scale(
          begin: const Offset(0.8, 0.8), curve: Curves.elasticOut);
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
            const Icon(Icons.lock_rounded,
                size: 13, color: AppColors.charcoalLight),
            const SizedBox(width: 6),
            Text('Reveal Quote',
                style: AppTextStyles.bodySmall
                    .copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

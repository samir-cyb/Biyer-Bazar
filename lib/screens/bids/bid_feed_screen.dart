import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../data/mock_data.dart';
import '../../logic/slot_filter_logic.dart';
import '../../models/event_request_model.dart';
import '../../models/vendor_model.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/vendor_bid_card.dart';

class BidFeedScreen extends StatefulWidget {
  final EventRequest? eventRequest;
  const BidFeedScreen({super.key, this.eventRequest});

  @override
  State<BidFeedScreen> createState() => _BidFeedScreenState();
}

class _BidFeedScreenState extends State<BidFeedScreen>
    with SingleTickerProviderStateMixin {
  late List<VendorBid> _curatedBids;
  late TabController _tabController;
  String _selectedLocation = 'Dhaka';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedLocation =
        widget.eventRequest?.location ?? 'Dhaka';
    _loadBids();
  }

  void _loadBids() {
    final jobId = widget.eventRequest?.id ?? 'demo_job_001';
    final pool = generateMockBids(jobId);
    setState(() {
      _curatedBids = SlotFilterLogic.applySevenSlotFilter(
        pool: pool,
        requestedLocation: _selectedLocation,
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverHeader(innerBoxIsScrolled),
        ],
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _AllBidsTab(bids: _curatedBids),
                  _AllBidsTab(
                    bids: _curatedBids.take(2).toList(),
                    emptyMessage: 'No premium bids yet',
                  ),
                  _AllBidsTab(
                    bids: _curatedBids.skip(5).toList(),
                    emptyMessage: 'No fresh talent bids yet',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildSliverHeader(bool innerBoxIsScrolled) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 180,
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded,
            color: AppColors.charcoal, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.tune_rounded, color: AppColors.charcoal),
          onPressed: () {},
          tooltip: 'Filter',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: _HeaderBanner(
          eventRequest: widget.eventRequest,
          bidCount: _curatedBids.length,
        ),
        titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 14),
        title: AnimatedOpacity(
          opacity: innerBoxIsScrolled ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Text('7 Curated Bids', style: AppTextStyles.headingMedium),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          color: AppColors.background.withOpacity(0.88),
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.crimson,
            unselectedLabelColor: AppColors.charcoalLight,
            indicatorColor: AppColors.crimson,
            indicatorWeight: 2.5,
            labelStyle: AppTextStyles.labelLarge.copyWith(fontSize: 12),
            tabs: const [
              Tab(text: 'ALL 7 BIDS'),
              Tab(text: '⭐ PREMIUM'),
              Tab(text: '✦ FRESH'),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderBanner extends StatelessWidget {
  final EventRequest? eventRequest;
  final int bidCount;
  const _HeaderBanner({this.eventRequest, required this.bidCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C1010), Color(0xFF1C1A17)],
        ),
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                ),
                itemCount: 64,
                itemBuilder: (_, __) => const Icon(
                  Icons.diamond_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 56,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.gold.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.gold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'LIVE BIDS',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.gold,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                        .fadeIn(duration: 800.ms)
                        .then()
                        .fadeOut(duration: 800.ms),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  eventRequest != null
                      ? '${eventRequest!.category.label} Bids'
                      : 'Your Curated Bids',
                  style: AppTextStyles.displaySmall.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  eventRequest != null
                      ? '${eventRequest!.location}  •  ${eventRequest!.guestCapacity} guests  •  ৳${eventRequest!.budgetCeiling}'
                      : 'Dhaka  •  Demo Mode',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AllBidsTab extends StatelessWidget {
  final List<VendorBid> bids;
  final String? emptyMessage;
  const _AllBidsTab({required this.bids, this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    if (bids.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📭', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(emptyMessage ?? 'No bids yet',
                style: AppTextStyles.headingMedium),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: bids.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _SlotLegend();
        final bid = bids[index - 1];
        final slotIndex = index - 1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: VendorBidCard(
            bid: bid,
            slotIndex: slotIndex,
            onSelect: () => _showSelectionDialog(context, bid),
          ),
        );
      },
    );
  }

  void _showSelectionDialog(BuildContext context, VendorBid bid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SelectionModal(bid: bid),
    );
  }
}

class _SlotLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          _LegendDot(color: AppColors.gold, label: 'Premium'),
          const SizedBox(width: 14),
          _LegendDot(color: AppColors.charcoalMid, label: 'Verified'),
          const SizedBox(width: 14),
          _LegendDot(color: AppColors.freshTalent, label: 'Fresh Talent'),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 5),
        Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
      ],
    );
  }
}

class _SelectionModal extends StatelessWidget {
  final VendorBid bid;
  const _SelectionModal({required this.bid});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: GlassCard(
        borderRadius: 24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.charcoal.withOpacity(0.15),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            const SizedBox(height: 20),
            Text('Confirm Selection', style: AppTextStyles.headingLarge),
            const SizedBox(height: 8),
            Text(
              'You\'re about to select ${bid.vendor.name} for this event.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GlassCard(
              padding: const EdgeInsets.all(14),
              backgroundColor: AppColors.gold.withOpacity(0.08),
              child: Row(
                children: [
                  const Text('💡', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'A 10% security deposit will be requested via bKash/Nagad to confirm the booking.',
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              '🎉 ${bid.vendor.name} selected! Deposit link coming soon.'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('✅  Confirm & Pay Deposit'),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }
}

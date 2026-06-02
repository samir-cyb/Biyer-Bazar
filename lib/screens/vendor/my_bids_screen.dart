import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../models/bid_model.dart';
import '../../services/auth_service.dart';
import '../../services/bid_service.dart';
import '../../services/hive_service.dart';
import '../../widgets/glass_card.dart';
import 'package:intl/intl.dart';

class MyBidsScreen extends StatefulWidget {
  const MyBidsScreen({super.key});

  @override
  State<MyBidsScreen> createState() => _MyBidsScreenState();
}

class _MyBidsScreenState extends State<MyBidsScreen> {
  List<Bid> _bids = [];
  final _fmt = NumberFormat('#,##,###', 'en_IN');

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    final user = AuthService.currentUser;
    if (user == null) return;
    setState(() {
      _bids = BidService.getMyBids(user.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('My Bids', style: AppTextStyles.headingLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.charcoal),
            onPressed: _refresh,
          ),
        ],
      ),
      body: _bids.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🎯', style: TextStyle(fontSize: 44)),
                  const SizedBox(height: 14),
                  Text('No bids yet', style: AppTextStyles.headingMedium),
                  const SizedBox(height: 6),
                  Text(
                    'Browse open events and submit your first bid.',
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async => _refresh(),
              color: AppColors.crimson,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: _bids.length,
                itemBuilder: (_, i) =>
                    _BidCard(bid: _bids[i], index: i, fmt: _fmt),
              ),
            ),
    );
  }
}

class _BidCard extends StatelessWidget {
  final Bid bid;
  final int index;
  final NumberFormat fmt;
  const _BidCard(
      {required this.bid, required this.index, required this.fmt});

  Color get _statusColor {
    switch (bid.status) {
      case BidStatus.pending:
        return AppColors.gold;
      case BidStatus.accepted:
        return AppColors.freshTalent;
      case BidStatus.rejected:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = HiveService.getPost(bid.postId);

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      borderColor: bid.status == BidStatus.accepted
          ? AppColors.freshTalent.withOpacity(0.35)
          : null,
      backgroundColor: bid.status == BidStatus.accepted
          ? AppColors.freshTalentBg
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  post?.serviceCategory ?? bid.vendorCategory,
                  style: AppTextStyles.headingMedium,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${bid.status.emoji} ${bid.status.label}',
                  style: AppTextStyles.labelMedium.copyWith(
                      color: _statusColor, fontSize: 10),
                ),
              ),
            ],
          ),
          if (post != null) ...[
            const SizedBox(height: 4),
            Text(
              '${post.location}  ·  ${post.guestCapacity} guests  ·  ${post.eventDate.day}/${post.eventDate.month}/${post.eventDate.year}',
              style: AppTextStyles.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your Quote', style: AppTextStyles.bodySmall),
                    Text(
                      '৳ ${fmt.format(bid.quotedPrice)}',
                      style: AppTextStyles.currencyMedium
                          .copyWith(fontSize: 18),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Submitted', style: AppTextStyles.bodySmall),
                  Text(
                    '${bid.submittedAt.day}/${bid.submittedAt.month}/${bid.submittedAt.year}',
                    style: AppTextStyles.headingSmall
                        .copyWith(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          if (bid.status == BidStatus.accepted) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.freshTalent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.freshTalent.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.celebration_rounded,
                      size: 18, color: AppColors.freshTalent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Congratulations! The host selected your bid. Deposit request incoming.',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.freshTalent,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: index * 80))
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.1, end: 0);
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/service_categories.dart';
import '../../widgets/notification_bell.dart';
import '../../models/bid_model.dart';
import '../../models/post_model.dart';
import '../../services/auth_service.dart';
import '../../services/post_service.dart';
import '../../services/bid_service.dart';
import '../../services/booking_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/mesh_background.dart';
import 'submit_bid_screen.dart';
import '../shell/app_shell.dart';

class VendorHome extends StatefulWidget {
  final ValueChanged<int>? onNavigate;
  const VendorHome({super.key, this.onNavigate});

  @override
  State<VendorHome> createState() => _VendorHomeState();
}

class _VendorHomeState extends State<VendorHome> {
  List<EventPost> _openPosts = [];
  String _filterCategory = 'All';
  int _myBidsCount = 0;
  int _myBookingsCount = 0;
  Timer? _autoRefreshTimer;

  final _categories = ['All', ...ServiceCategories.all];

  @override
  void initState() {
    super.initState();
    _refresh();
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refresh(),
    );
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final user = AuthService.currentUser;
    if (user == null) return;
    final results = await Future.wait([
      PostService.getOpenPosts(),
      BidService.getMyBids(user.id),
      BookingService.getVendorBookings(user.id),
    ]);
    final all      = results[0] as List<EventPost>;
    final myBids   = results[1] as List<Bid>;
    final bookings = results[2] as List;
    if (mounted) {
      setState(() {
        _myBidsCount     = myBids.length;
        _myBookingsCount = bookings.length;
        _openPosts = _filterCategory == 'All'
            ? all
            : all.where((p) => p.serviceCategory == _filterCategory).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final myBidsCount = _myBidsCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StaticMeshBackground(child: RefreshIndicator(
        onRefresh: () async => _refresh(),
        color: AppColors.crimson,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(user?.name ?? 'Vendor'),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _VendorBanner(
                    businessName: user?.businessName ?? user?.name ?? 'My Studio',
                    category: user?.vendorCategory ?? 'Service Provider',
                    myBidsCount: myBidsCount,
                    openPosts: _openPosts.length,
                    myBookingsCount: _myBookingsCount,
                  ),
                  const SizedBox(height: 20),
                  _CategoryFilter(
                    categories: _categories,
                    selected: _filterCategory,
                    onSelect: (c) {
                      setState(() => _filterCategory = c);
                      _refresh();
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Open Events (${_openPosts.length})',
                          style: AppTextStyles.headingLarge),
                      TextButton(
                        onPressed: () {
                          if (widget.onNavigate != null) {
                            widget.onNavigate!.call(2); // Bookings tab
                          } else {
                            AppShell.of(context)?.goToTab(2);
                          }
                        },
                        child: Text('My Bids',
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.crimson,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_openPosts.isEmpty)
                    _EmptyState()
                  else
                    ..._openPosts.asMap().entries.map((e) => TiltCard(child: _OpenPostCard(
                          post: e.value,
                          index: e.key,
                          onBid: () async {
                            final vendorUser = AuthService.currentUser;
                            if (vendorUser == null) return;
                            final canBid = await BidService.canVendorBid(
                                vendorUser.id, e.value.id);
                            if (!canBid) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                      'You already submitted a bid for this event.'),
                                  backgroundColor: AppColors.warning,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                ),
                              );
                              return;
                            }
                            await Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (_, __, ___) =>
                                    SubmitBidScreen(post: e.value),
                                transitionsBuilder: (_, a, __, c) =>
                                    FadeTransition(opacity: a, child: c),
                              ),
                            );
                            _refresh();
                          },
                        ))),
                ]),
              ),
            ),
          ],
        ),
      )),
    );
  }

  SliverAppBar _buildAppBar(String name) {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                  colors: [AppColors.gold, AppColors.freshTalent]),
            ),
            child: Center(
              child: Text(
                name.substring(0, 1).toUpperCase(),
                style: AppTextStyles.headingSmall
                    .copyWith(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${name.split(' ').first}\'s Dashboard',
                  style:
                      AppTextStyles.headingSmall.copyWith(fontSize: 14)),
              Text('Vendor Portal',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.charcoalLight)),
            ],
          ),
        ],
      ),
      actions: [
        const NotificationBell(),
        Container(
          margin: const EdgeInsets.only(right: 16, left: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.gold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('📸', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text('Vendor',
                  style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.gold, fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }
}

class _VendorBanner extends StatelessWidget {
  final String businessName;
  final String category;
  final int myBidsCount;
  final int openPosts;
  final int myBookingsCount;
  const _VendorBanner(
      {required this.businessName,
      required this.category,
      required this.myBidsCount,
      required this.openPosts,
      required this.myBookingsCount});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      backgroundColor: AppColors.gold.withOpacity(0.06),
      borderColor: AppColors.gold.withOpacity(0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(businessName,
                        style: AppTextStyles.displaySmall),
                    Text(category, style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
              const Text('📸', style: TextStyle(fontSize: 36)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Chip(
                value: '$openPosts',
                label: 'Open Events',
                color: AppColors.crimson,
              ),
              const SizedBox(width: 10),
              _Chip(
                value: '$myBidsCount',
                label: 'My Bids',
                color: AppColors.gold,
              ),
              const SizedBox(width: 10),
              _Chip(
                value: '$myBookingsCount',
                label: 'Bookings',
                color: AppColors.freshTalent,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}

class _Chip extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _Chip(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: AppTextStyles.headingMedium.copyWith(color: color)),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelect;
  const _CategoryFilter(
      {required this.categories,
      required this.selected,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = categories[i];
          final sel = cat == selected;
          return GestureDetector(
            onTap: () => onSelect(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: sel
                    ? AppColors.charcoal
                    : Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: sel
                      ? AppColors.charcoal
                      : AppColors.charcoal.withOpacity(0.15),
                ),
              ),
              child: Text(
                cat,
                style: AppTextStyles.bodySmall.copyWith(
                  color:
                      sel ? Colors.white : AppColors.charcoalMid,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const Text('🔍', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 14),
          Text('No open events right now',
              style: AppTextStyles.headingMedium),
          const SizedBox(height: 6),
          Text(
            'Pull down to refresh, or check back soon. Hosts post events daily.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OpenPostCard extends StatelessWidget {
  final EventPost post;
  final int index;
  final VoidCallback onBid;
  const _OpenPostCard(
      {required this.post, required this.index, required this.onBid});

  @override
  Widget build(BuildContext context) {
    final daysLeft = post.daysUntilEvent;
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.serviceCategory,
                        style: AppTextStyles.headingMedium),
                    Text('by ${post.hostName}',
                        style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: daysLeft < 7
                      ? AppColors.error.withOpacity(0.1)
                      : AppColors.freshTalent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$daysLeft days left',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: daysLeft < 7
                        ? AppColors.error
                        : AppColors.freshTalent,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(post.description,
              style: AppTextStyles.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoPill(Icons.location_on_rounded, post.location),
              const SizedBox(width: 8),
              _InfoPill(Icons.people_rounded,
                  '${post.guestCapacity} guests'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Budget Ceiling',
                        style: AppTextStyles.bodySmall),
                    Text('৳ ${post.budgetCeiling}',
                        style: AppTextStyles.currencyMedium
                            .copyWith(fontSize: 17)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: onBid,
                icon: const Icon(Icons.gavel_rounded, size: 16),
                label: const Text('Submit Bid'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: index * 80))
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.1, end: 0);
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoPill(this.icon, this.label);

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

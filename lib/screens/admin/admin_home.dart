import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../models/bid_model.dart';
import '../../services/hive_service.dart';
import '../../widgets/glass_card.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  List<AppUser> _users = [];
  List<EventPost> _posts = [];
  List<Bid> _bids = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _refresh();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _users = HiveService.getAllUsers();
      _posts = HiveService.getAllPosts();
      _bids = HiveService.getAllBids();
    });
  }

  @override
  Widget build(BuildContext context) {
    final hosts = _users.where((u) => u.role == UserRole.host).length;
    final vendors = _users.where((u) => u.role == UserRole.vendor).length;
    final openPosts =
        _posts.where((p) => p.status == PostStatus.open).length;
    final bookedPosts =
        _posts.where((p) => p.status == PostStatus.booked).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Row(
          children: [
            const Text('⚙️', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text('Admin Dashboard', style: AppTextStyles.headingLarge),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.charcoal),
            onPressed: _refresh,
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.crimson,
          unselectedLabelColor: AppColors.charcoalLight,
          indicatorColor: AppColors.crimson,
          labelStyle: AppTextStyles.labelLarge.copyWith(fontSize: 11),
          tabs: const [
            Tab(text: 'OVERVIEW'),
            Tab(text: 'USERS'),
            Tab(text: 'POSTS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // Overview Tab
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              children: [
                _StatGrid(stats: [
                  ('👤', '${_users.length}', 'Total Users', AppColors.crimson),
                  ('👰', '$hosts', 'Hosts', AppColors.gold),
                  ('📸', '$vendors', 'Vendors', AppColors.freshTalent),
                  ('📋', '${_posts.length}', 'Total Posts', AppColors.charcoalMid),
                  ('🟢', '$openPosts', 'Open Posts', AppColors.freshTalent),
                  ('✅', '$bookedPosts', 'Booked', AppColors.charcoal),
                  ('🎯', '${_bids.length}', 'Total Bids', AppColors.crimson),
                  ('⏳', '${_bids.where((b) => b.status == BidStatus.pending).length}', 'Pending Bids', AppColors.gold),
                ]),
                const SizedBox(height: 20),
                _RecentActivity(posts: _posts.take(5).toList()),
              ],
            ),
          ),

          // Users Tab
          RefreshIndicator(
            onRefresh: () async => _refresh(),
            color: AppColors.crimson,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: _users.length,
              itemBuilder: (_, i) =>
                  _UserCard(user: _users[i], index: i),
            ),
          ),

          // Posts Tab
          RefreshIndicator(
            onRefresh: () async => _refresh(),
            color: AppColors.crimson,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: _posts.length,
              itemBuilder: (_, i) => _AdminPostCard(
                  post: _posts[i],
                  bidCount: HiveService.getBidsForPost(_posts[i].id).length,
                  index: i),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  final List<(String, String, String, Color)> stats;
  const _StatGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.9,
      ),
      itemCount: stats.length,
      itemBuilder: (_, i) {
        final s = stats[i];
        return GlassCard(
          padding: const EdgeInsets.all(10),
          backgroundColor: s.$4.withOpacity(0.07),
          borderColor: s.$4.withOpacity(0.15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(s.$1, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Text(s.$2,
                  style: AppTextStyles.currencyMedium.copyWith(
                      color: s.$4, fontSize: 18)),
              Text(s.$3,
                  style: AppTextStyles.bodySmall
                      .copyWith(fontSize: 9),
                  textAlign: TextAlign.center,
                  maxLines: 2),
            ],
          ),
        )
            .animate(delay: Duration(milliseconds: i * 50))
            .fadeIn(duration: 300.ms)
            .scale(begin: const Offset(0.9, 0.9));
      },
    );
  }
}

class _RecentActivity extends StatelessWidget {
  final List<EventPost> posts;
  const _RecentActivity({required this.posts});

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Posts', style: AppTextStyles.headingLarge),
        const SizedBox(height: 12),
        ...posts.map((p) => GlassCard(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Text(p.status.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.serviceCategory,
                            style: AppTextStyles.headingSmall),
                        Text('${p.hostName}  ·  ${p.location}',
                            style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                  Text('৳${p.budgetCeiling}',
                      style: AppTextStyles.currencyMedium
                          .copyWith(fontSize: 13)),
                ],
              ),
            )),
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  final AppUser user;
  final int index;
  const _UserCard({required this.user, required this.index});

  @override
  Widget build(BuildContext context) {
    final roleColor = user.role == UserRole.host
        ? AppColors.crimson
        : user.role == UserRole.vendor
            ? AppColors.gold
            : AppColors.freshTalent;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: roleColor.withOpacity(0.12),
            ),
            child: Center(
              child: Text(
                user.role.emoji,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.businessName ?? user.name,
                    style: AppTextStyles.headingSmall),
                Text('+88 ${user.phone}',
                    style: AppTextStyles.bodySmall),
                if (user.vendorCategory != null)
                  Text(user.vendorCategory!,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.charcoalLight)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(user.role.label,
                style: AppTextStyles.labelMedium.copyWith(
                    color: roleColor, fontSize: 10)),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: index * 60))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.05, end: 0);
  }
}

class _AdminPostCard extends StatelessWidget {
  final EventPost post;
  final int bidCount;
  final int index;
  const _AdminPostCard(
      {required this.post, required this.bidCount, required this.index});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Text(post.status.emoji,
              style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.serviceCategory,
                    style: AppTextStyles.headingSmall),
                Text('${post.hostName}  ·  ${post.location}',
                    style: AppTextStyles.bodySmall),
                Text(
                    '$bidCount bid${bidCount != 1 ? 's' : ''}  ·  ${post.status.label}',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.charcoalLight)),
              ],
            ),
          ),
          Text('৳${post.budgetCeiling}',
              style: AppTextStyles.currencyMedium
                  .copyWith(fontSize: 13)),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: index * 60))
        .fadeIn(duration: 300.ms);
  }
}

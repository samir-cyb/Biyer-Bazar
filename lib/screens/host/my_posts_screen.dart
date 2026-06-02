import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../models/post_model.dart';
import '../../services/auth_service.dart';
import '../../services/post_service.dart';
import '../../services/hive_service.dart';
import '../../widgets/glass_card.dart';
import '../request/request_creation_screen.dart';
import 'post_detail_screen.dart';

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<EventPost> _allPosts = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _refresh();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _refresh() {
    final user = AuthService.currentUser;
    if (user == null) return;
    setState(() {
      _allPosts = PostService.getMyPosts(user.id);
    });
  }

  List<EventPost> _filter(PostStatus? status) =>
      status == null ? _allPosts : _allPosts.where((p) => p.status == status).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('My Posts', style: AppTextStyles.headingLarge),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.charcoal),
            onPressed: _refresh,
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.crimson,
          unselectedLabelColor: AppColors.charcoalLight,
          indicatorColor: AppColors.crimson,
          isScrollable: true,
          labelStyle: AppTextStyles.labelLarge.copyWith(fontSize: 11),
          tabs: const [
            Tab(text: 'ALL'),
            Tab(text: '🟢 OPEN'),
            Tab(text: '✅ BOOKED'),
            Tab(text: '❌ CANCELLED'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _PostList(posts: _filter(null), onRefresh: _refresh),
          _PostList(posts: _filter(PostStatus.open), onRefresh: _refresh),
          _PostList(posts: _filter(PostStatus.booked), onRefresh: _refresh),
          _PostList(posts: _filter(PostStatus.cancelled), onRefresh: _refresh),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const RequestCreationScreen(),
              transitionsBuilder: (_, a, __, c) =>
                  FadeTransition(opacity: a, child: c),
            ),
          );
          _refresh();
        },
        backgroundColor: AppColors.crimson,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('New Post',
            style: AppTextStyles.headingSmall.copyWith(color: Colors.white)),
      ),
    );
  }
}

class _PostList extends StatelessWidget {
  final List<EventPost> posts;
  final VoidCallback onRefresh;
  const _PostList({required this.posts, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📭', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 14),
            Text('No posts here', style: AppTextStyles.headingMedium),
            const SizedBox(height: 6),
            Text('Posts you create will appear here.',
                style: AppTextStyles.bodySmall),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppColors.crimson,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: posts.length,
        itemBuilder: (ctx, i) => _PostDetailCard(
          post: posts[i],
          index: i,
          onTap: () async {
            await Navigator.push(
              ctx,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) =>
                    PostDetailScreen(post: posts[i]),
                transitionsBuilder: (_, a, __, c) =>
                    FadeTransition(opacity: a, child: c),
              ),
            );
            onRefresh();
          },
        ),
      ),
    );
  }
}

class _PostDetailCard extends StatelessWidget {
  final EventPost post;
  final int index;
  final VoidCallback onTap;
  const _PostDetailCard(
      {required this.post, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bidCount = HiveService.getBidsForPost(post.id).length;
    final daysLeft = post.daysUntilEvent;

    return GlassCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(post.serviceCategory,
                    style: AppTextStyles.headingMedium),
              ),
              _StatusBadge(status: post.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(post.description,
              style: AppTextStyles.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _InfoChip(Icons.location_on_rounded, post.location),
              _InfoChip(Icons.people_rounded, '${post.guestCapacity} guests'),
              _InfoChip(Icons.payments_rounded, '৳${post.budgetCeiling}'),
              _InfoChip(
                Icons.calendar_month_rounded,
                '${post.eventDate.day}/${post.eventDate.month}/${post.eventDate.year}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (bidCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.crimson.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppColors.crimson.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.gavel_rounded,
                          size: 13, color: AppColors.crimson),
                      const SizedBox(width: 5),
                      Text(
                        '$bidCount bid${bidCount > 1 ? 's' : ''} received',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.crimson,
                            fontWeight: FontWeight.w700,
                            fontSize: 11),
                      ),
                    ],
                  ),
                )
              else
                Text('No bids yet — vendors are reviewing',
                    style: AppTextStyles.bodySmall),
              const Spacer(),
              if (daysLeft > 0)
                Text('$daysLeft days away',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: daysLeft < 7
                            ? AppColors.error
                            : AppColors.charcoalLight)),
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip(this.icon, this.label);

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

class _StatusBadge extends StatelessWidget {
  final PostStatus status;
  const _StatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case PostStatus.open:
        return AppColors.freshTalent;
      case PostStatus.reviewing:
        return AppColors.gold;
      case PostStatus.booked:
        return AppColors.charcoalMid;
      case PostStatus.cancelled:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${status.emoji} ${status.label}',
        style: AppTextStyles.labelMedium
            .copyWith(color: _color, fontSize: 10),
      ),
    );
  }
}

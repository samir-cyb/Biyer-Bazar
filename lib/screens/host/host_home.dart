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

class HostHome extends StatefulWidget {
  final ValueChanged<int>? onNavigate;
  const HostHome({super.key, this.onNavigate});

  @override
  State<HostHome> createState() => _HostHomeState();
}

class _HostHomeState extends State<HostHome> {
  List<EventPost> _myPosts = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    final user = AuthService.currentUser;
    if (user == null) return;
    setState(() {
      _myPosts = PostService.getMyPosts(user.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final openPosts = _myPosts.where((p) => p.status == PostStatus.open).length;
    final totalBids = _myPosts.fold<int>(
        0, (sum, p) => sum + HiveService.getBidsForPost(p.id).length);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        color: AppColors.crimson,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(user?.name ?? 'Host'),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _WelcomeBanner(
                    name: user?.name ?? 'Host',
                    openPosts: openPosts,
                    totalBids: totalBids,
                  ),
                  const SizedBox(height: 24),
                  _QuickActionRow(onNavigate: widget.onNavigate),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Posts', style: AppTextStyles.headingLarge),
                      TextButton(
                        onPressed: () => widget.onNavigate?.call(1),
                        child: Text('See All',
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.crimson,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_myPosts.isEmpty)
                    _EmptyPostsCard(
                      onPost: () async {
                        await Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) =>
                                const RequestCreationScreen(),
                            transitionsBuilder: (_, a, __, c) =>
                                FadeTransition(opacity: a, child: c),
                          ),
                        );
                        _refresh();
                      },
                    )
                  else
                    ..._myPosts.take(3).map((post) => _PostCard(
                          post: post,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (_, __, ___) =>
                                    PostDetailScreen(post: post),
                                transitionsBuilder: (_, a, __, c) =>
                                    FadeTransition(opacity: a, child: c),
                              ),
                            );
                            _refresh();
                          },
                        )),
                ]),
              ),
            ),
          ],
        ),
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
        label: Text('New Post', style: AppTextStyles.headingSmall.copyWith(color: Colors.white)),
        elevation: 4,
      ),
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
                  colors: [AppColors.gold, AppColors.crimson]),
            ),
            child: Center(
              child: Text(
                AuthService.currentUser?.name.substring(0, 1).toUpperCase() ??
                    'H',
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
              Text('Good day, ${name.split(' ').first}!',
                  style: AppTextStyles.headingSmall.copyWith(fontSize: 14)),
              Text('Host Dashboard',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.charcoalLight)),
            ],
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.crimson.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('👰', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text('Host',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.crimson, fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  final String name;
  final int openPosts;
  final int totalBids;
  const _WelcomeBanner(
      {required this.name, required this.openPosts, required this.totalBids});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      backgroundColor: AppColors.crimson.withOpacity(0.06),
      borderColor: AppColors.crimson.withOpacity(0.15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Plan Your\nDream Wedding', style: AppTextStyles.displaySmall),
                    const SizedBox(height: 8),
                    Text(
                      'Post events, collect bids from the best vendors, pay fair.',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              const Text('💍', style: TextStyle(fontSize: 44)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatChip(value: '$openPosts', label: 'Open Posts', color: AppColors.freshTalent),
              const SizedBox(width: 10),
              _StatChip(value: '$totalBids', label: 'Total Bids', color: AppColors.crimson),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatChip({required this.value, required this.label, required this.color});

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

class _QuickActionRow extends StatelessWidget {
  final ValueChanged<int>? onNavigate;
  const _QuickActionRow({this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickAction(
            icon: '📋',
            label: 'My Posts',
            color: AppColors.crimson,
            onTap: () => onNavigate?.call(1),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
            icon: '🧮',
            label: 'Budget',
            color: AppColors.gold,
            onTap: () => onNavigate?.call(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
            icon: '👤',
            label: 'Profile',
            color: AppColors.freshTalent,
            onTap: () => onNavigate?.call(3),
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        backgroundColor: color.withOpacity(0.07),
        borderColor: color.withOpacity(0.15),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 6),
            Text(label, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _EmptyPostsCard extends StatelessWidget {
  final VoidCallback onPost;
  const _EmptyPostsCard({required this.onPost});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const Text('📭', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 14),
          Text("No posts yet", style: AppTextStyles.headingMedium),
          const SizedBox(height: 6),
          Text(
            'Post your first wedding event and start receiving bids from verified vendors.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onPost,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Post Your First Event'),
          ),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn(duration: 400.ms);
  }
}

class _PostCard extends StatelessWidget {
  final EventPost post;
  final VoidCallback onTap;
  const _PostCard({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bidCount = HiveService.getBidsForPost(post.id).length;
    return GlassCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.crimson.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(post.status.emoji,
                  style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.serviceCategory,
                    style: AppTextStyles.headingSmall),
                const SizedBox(height: 3),
                Text(
                  '${post.location}  ·  ${post.guestCapacity} guests  ·  ৳${post.budgetCeiling}',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _StatusBadge(status: post.status),
                    const SizedBox(width: 8),
                    if (bidCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.freshTalent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('$bidCount bid${bidCount > 1 ? 's' : ''}',
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.freshTalent,
                                fontWeight: FontWeight.w700,
                                fontSize: 10)),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.charcoalLight),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0);
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _color.withOpacity(0.2)),
      ),
      child: Text(
        '${status.emoji} ${status.label}',
        style: AppTextStyles.bodySmall.copyWith(
            color: _color, fontWeight: FontWeight.w700, fontSize: 10),
      ),
    );
  }
}

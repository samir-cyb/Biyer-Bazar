import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../models/post_model.dart';
import '../../widgets/notification_bell.dart';
import '../../services/auth_service.dart';
import '../../services/post_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/mesh_background.dart';
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
  int _totalBids = 0;
  Timer? _autoRefreshTimer;

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
    dev.log('[HostHome] Refreshing data...', name: 'BiyerBajar');
    final posts = await PostService.getMyPosts(user.id);
    int bidTotal = 0;
    if (posts.isNotEmpty) {
      final counts = await Future.wait(posts.map((p) => PostService.getBidCount(p.id)));
      bidTotal = counts.fold(0, (a, b) => a + b);
    }
    if (mounted) setState(() { _myPosts = posts; _totalBids = bidTotal; });
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final openPosts = _myPosts.where((p) => p.status == PostStatus.open).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StaticMeshBackground(
        child: RefreshIndicator(
          onRefresh: () async => _refresh(),
          color: AppColors.crimson,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              _buildAppBar(user?.name ?? 'Host'),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _WelcomeBanner(
                      name: user?.name ?? 'Host',
                      openPosts: openPosts,
                      totalBids: _totalBids,
                    ),
                    const SizedBox(height: 22),
                    _QuickActionRow(onNavigate: widget.onNavigate),
                    const SizedBox(height: 20),
                    _NewPostBanner(onPost: () async {
                      await Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => const RequestCreationScreen(),
                          transitionsBuilder: (_, a, __, c) =>
                              FadeTransition(opacity: a, child: c),
                        ),
                      );
                      _refresh();
                    }),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent Posts', style: AppTextStyles.headingLarge),
                        TextButton(
                          onPressed: () => widget.onNavigate?.call(1),
                          child: Text('See All',
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.crimson, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_myPosts.isEmpty)
                      _EmptyPostsCard(onPost: () async {
                        await Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => const RequestCreationScreen(),
                            transitionsBuilder: (_, a, __, c) =>
                                FadeTransition(opacity: a, child: c),
                          ),
                        );
                        _refresh();
                      })
                    else
                      ..._myPosts.take(3).map((post) => TiltCard(
                            child: _PostCard(
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
                            ),
                          )),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(String name) {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [AppColors.gold, AppColors.crimson]),
              boxShadow: [
                BoxShadow(
                  color: AppColors.crimson.withOpacity(0.30),
                  blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Center(
              child: Text(
                AuthService.currentUser?.name.substring(0, 1).toUpperCase() ?? 'H',
                style: AppTextStyles.headingSmall.copyWith(color: Colors.white, fontSize: 14),
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
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.charcoalLight)),
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
            color: AppColors.crimson.withOpacity(0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('👰', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text('Host',
                style: AppTextStyles.labelMedium.copyWith(color: AppColors.crimson, fontSize: 10)),
          ]),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _WelcomeBanner extends StatelessWidget {
  final String name;
  final int openPosts;
  final int totalBids;
  const _WelcomeBanner({required this.name, required this.openPosts, required this.totalBids});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF800020), Color(0xFF4A0018)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.crimson.withOpacity(0.35),
            blurRadius: 30,
            offset: const Offset(0, 10),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Decorative orb
            Positioned(
              right: -24, top: -24,
              child: Container(
                width: 140, height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              right: 20, bottom: -30,
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold.withOpacity(0.12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Plan Your\nDream Wedding',
                              style: AppTextStyles.displaySmall.copyWith(
                                color: Colors.white, height: 1.2, fontSize: 24)),
                          const SizedBox(height: 8),
                          Text(
                            'Browse vendors · Chat · Book & pay',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white.withOpacity(0.75)),
                          ),
                        ],
                      ),
                    ),
                    const Text('💍', style: TextStyle(fontSize: 44)),
                  ]),
                  const SizedBox(height: 18),
                  Row(children: [
                    _StatPill(value: '$openPosts', label: 'Open Posts',
                        color: const Color(0xFF4ADE80)),
                    const SizedBox(width: 10),
                    _StatPill(value: '$totalBids', label: 'Total Bids',
                        color: AppColors.gold),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 450.ms)
        .slideY(begin: 0.10, end: 0, curve: Curves.easeOutCubic);
  }
}

class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatPill({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.30)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(value,
            style: AppTextStyles.headingMedium.copyWith(color: color, fontSize: 18)),
        const SizedBox(width: 6),
        Text(label,
            style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white.withOpacity(0.80), fontSize: 11)),
      ]),
    );
  }
}

class _QuickActionRow extends StatelessWidget {
  final ValueChanged<int>? onNavigate;
  const _QuickActionRow({this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final actions = [
      ('📋', 'My Posts',  AppColors.crimson,      1),
      ('🔍', 'Find Vendors', AppColors.gold,       2),
      ('🧮', 'Budget',    AppColors.charcoalMid,   3),
      ('👤', 'Profile',   AppColors.freshTalent,   6),
    ];
    return Row(
      children: actions.asMap().entries.map((e) {
        final (icon, label, color, idx) = e.value;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: e.key < 2 ? 10 : 0),
            child: PressableCard(
              onTap: () => onNavigate?.call(idx),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: color.withOpacity(0.15)),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.12),
                      blurRadius: 18, offset: const Offset(0, 6), spreadRadius: -2),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: Text(icon, style: const TextStyle(fontSize: 20))),
                  ),
                  const SizedBox(height: 8),
                  Text(label, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ),
        );
      }).toList(),
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
      child: Column(children: [
        const Text('📭', style: TextStyle(fontSize: 44)),
        const SizedBox(height: 14),
        Text('No posts yet', style: AppTextStyles.headingMedium),
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
      ]),
    ).animate(delay: 200.ms).fadeIn(duration: 400.ms);
  }
}

class _PostCard extends StatelessWidget {
  final EventPost post;
  final VoidCallback onTap;
  const _PostCard({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(post.status);
    return GlassCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      borderRadius: 20,
      boxShadow: [
        BoxShadow(
          color: statusColor.withOpacity(0.10),
          blurRadius: 20,
          offset: const Offset(0, 6),
          spreadRadius: -2,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: Colors.white.withOpacity(0.80),
          blurRadius: 1,
          offset: const Offset(0, -1),
        ),
      ],
      child: Column(
        children: [
          // Color accent strip
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [statusColor, statusColor.withOpacity(0.4)]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(post.status.emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(post.serviceCategory, style: AppTextStyles.headingSmall),
                  const SizedBox(height: 3),
                  Text(
                    '${post.location}  ·  ${post.guestCapacity} guests  ·  ৳${post.budgetCeiling}',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  _StatusBadge(status: post.status),
                ]),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: AppColors.charcoalLight.withOpacity(0.60)),
            ]),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0);
  }

  Color _statusColor(PostStatus s) {
    switch (s) {
      case PostStatus.open: return AppColors.freshTalent;
      case PostStatus.reviewing: return AppColors.gold;
      case PostStatus.booked: return AppColors.charcoalMid;
      case PostStatus.cancelled: return AppColors.error;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final PostStatus status;
  const _StatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case PostStatus.open: return AppColors.freshTalent;
      case PostStatus.reviewing: return AppColors.gold;
      case PostStatus.booked: return AppColors.charcoalMid;
      case PostStatus.cancelled: return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _color.withOpacity(0.20)),
      ),
      child: Text(
        '${status.emoji} ${status.label}',
        style: AppTextStyles.bodySmall.copyWith(
            color: _color, fontWeight: FontWeight.w700, fontSize: 10),
      ),
    );
  }
}

class _NewPostBanner extends StatelessWidget {
  final VoidCallback onPost;
  const _NewPostBanner({required this.onPost});

  @override
  Widget build(BuildContext context) {
    return PressableCard(
      onTap: onPost,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.crimson, Color(0xFFD4005A)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.crimson.withOpacity(0.40),
              blurRadius: 22,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Post a New Event',
                  style: AppTextStyles.headingMedium.copyWith(
                      color: Colors.white, fontSize: 17)),
              const SizedBox(height: 3),
              Text('Tap to get vendor bids for your wedding',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.80))),
            ]),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
        ]),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.08, end: 0)
        .then()
        .shimmer(duration: 1400.ms, color: Colors.white.withOpacity(0.12));
  }
}


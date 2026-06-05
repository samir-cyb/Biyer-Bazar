import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/app_colors.dart';
import '../../core/app_strings.dart';
import '../../core/app_text_styles.dart';
import '../../core/service_categories.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/mesh_background.dart';
import '../auth/welcome_screen.dart';
import '../vendor/vendor_profile_setup.dart';
import '../../services/notification_service.dart';
import '../../services/chat_service.dart';
import '../chat/chat_screen.dart';

class ProfileScreen extends StatefulWidget {
  final AppUser? user;
  const ProfileScreen({super.key, this.user});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AppUser? _user;
  bool _uploading = false;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _user = widget.user ?? AuthService.currentUser;
    _loadUnread();
  }

  Future<void> _loadUnread() async {
    final u = _user;
    if (u == null) return;
    final count = await NotificationService.unreadCount(u.id);
    if (mounted) setState(() => _unreadNotifications = count);
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null || _user == null) return;

    setState(() => _uploading = true);
    final url = await ProfileService.uploadAvatar(File(picked.path), _user!.id);
    if (url != null) {
      await AuthService.loadCurrentUser();
      setState(() { _user = AuthService.currentUser; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('✅ Profile picture updated!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
    setState(() => _uploading = false);
  }

  @override
  Widget build(BuildContext context) {
    final u = _user;
    if (u == null) return const Center(child: Text('Not logged in'));

    final roleColor = u.role == UserRole.host
        ? AppColors.crimson
        : u.role == UserRole.vendor
            ? AppColors.gold
            : AppColors.freshTalent;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StaticMeshBackground(child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppColors.charcoal,
            flexibleSpace: FlexibleSpaceBar(
              background: _ProfileHero(
                user: u,
                roleColor: roleColor,
                uploading: _uploading,
                onPickPhoto: _pickAndUploadAvatar,
              ),
            ),
            actions: [
              // Notification bell — visible for vendors and hosts
              if (u.role != UserRole.admin)
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_rounded, color: Colors.white),
                      tooltip: 'Notifications',
                      onPressed: () => _showNotificationsSheet(context, u.id),
                    ),
                    if (_unreadNotifications > 0)
                      Positioned(
                        right: 8, top: 8,
                        child: Container(
                          width: 16, height: 16,
                          decoration: const BoxDecoration(
                            color: AppColors.gold, shape: BoxShape.circle),
                          child: Center(
                            child: Text('$_unreadNotifications',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 9,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                  ],
                ),
              if (u.role == UserRole.vendor)
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: Colors.white),
                  tooltip: 'Edit Profile',
                  onPressed: () => Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const VendorProfileSetupScreen(),
                      transitionsBuilder: (_, a, __, c) =>
                          FadeTransition(opacity: a, child: c),
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                tooltip: 'Sign Out',
                onPressed: () => _confirmLogout(context),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _LanguageToggleCard(),
                const SizedBox(height: 16),
                _InfoCard(user: u),
                if (u.role == UserRole.vendor) ...[
                  const SizedBox(height: 16),
                  _BadgeCard(user: u),
                  const SizedBox(height: 16),
                  _VendorInfoCard(user: u),
                  if (u.portfolioUrls.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _PortfolioCard(urls: u.portfolioUrls),
                  ],
                ],
                const SizedBox(height: 16),
                _AccountCard(user: u),
                if (u.role != UserRole.admin) ...[
                  const SizedBox(height: 16),
                  _HelpSupportCard(userId: u.id),
                ],
              ]),
            ),
          ),
        ],
      )),
    );
  }

  Future<void> _showNotificationsSheet(BuildContext context, String userId) async {
    final notifs = await NotificationService.getMyNotifications(userId);
    await NotificationService.markAllRead(userId);
    setState(() => _unreadNotifications = 0);

    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColors.charcoal.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Text('Notifications', style: AppTextStyles.headingMedium),
                const Spacer(),
                if (notifs.isNotEmpty)
                  Text('${notifs.length} total',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.charcoalLight)),
              ]),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: notifs.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('🔔', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 12),
                      Text('No notifications yet', style: AppTextStyles.headingSmall),
                    ]))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                      itemCount: notifs.length,
                      itemBuilder: (_, i) {
                        final n = notifs[i];
                        final color = n.type == 'approval'
                            ? AppColors.freshTalent
                            : n.type == 'rejection'
                                ? AppColors.error
                                : n.type == 'booking'
                                    ? AppColors.gold
                                    : AppColors.charcoalMid;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: color.withOpacity(0.2)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  shape: BoxShape.circle),
                                child: Center(child: Text(
                                  n.type == 'approval' ? '✅'
                                  : n.type == 'rejection' ? '❌'
                                  : n.type == 'booking' ? '📅' : '🔔',
                                  style: const TextStyle(fontSize: 16))),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(n.title, style: AppTextStyles.headingSmall),
                                  const SizedBox(height: 3),
                                  Text(n.body, style: AppTextStyles.bodySmall),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${n.createdAt.day}/${n.createdAt.month}/${n.createdAt.year}',
                                    style: AppTextStyles.bodySmall.copyWith(
                                        fontSize: 9, color: AppColors.charcoalLight)),
                                ],
                              )),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign Out?', style: AppTextStyles.headingLarge),
        content: Text('You will be returned to the welcome screen.', style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              AuthService.logout();
              Navigator.of(context).pushAndRemoveUntil(
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const WelcomeScreen(),
                  transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
                  transitionDuration: const Duration(milliseconds: 400),
                ),
                (_) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

// ── Profile Hero ──────────────────────────────────────────────────────────────
class _ProfileHero extends StatelessWidget {
  final AppUser user;
  final Color roleColor;
  final bool uploading;
  final VoidCallback onPickPhoto;
  const _ProfileHero({required this.user, required this.roleColor,
      required this.uploading, required this.onPickPhoto});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [AppColors.charcoal, roleColor.withOpacity(0.7)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Stack(children: [
                    // Avatar circle
                    GestureDetector(
                      onTap: onPickPhoto,
                      child: Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: roleColor.withOpacity(0.35),
                          border: Border.all(color: Colors.white.withOpacity(0.4), width: 2.5),
                        ),
                        child: uploading
                            ? const Center(child: SizedBox(width: 24, height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                            : user.profilePictureUrl != null
                                ? ClipOval(child: CachedNetworkImage(
                                    imageUrl: user.profilePictureUrl!,
                                    fit: BoxFit.cover, width: 80, height: 80,
                                    placeholder: (_, __) => Center(child: Text(user.initials,
                                        style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold))),
                                    errorWidget: (_, __, ___) => Center(child: Text(user.initials,
                                        style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold))),
                                  ))
                                : Center(child: Text(user.initials,
                                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold))),
                      ),
                    ),
                    // Camera badge
                    Positioned(
                      right: 0, bottom: 0,
                      child: GestureDetector(
                        onTap: onPickPhoto,
                        child: Container(
                          width: 26, height: 26,
                          decoration: BoxDecoration(
                            color: roleColor, shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, size: 13, color: Colors.white),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(width: 16),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.businessName ?? user.name,
                          style: AppTextStyles.displaySmall.copyWith(color: Colors.white, fontSize: 20)),
                      if (user.email.isNotEmpty)
                        Text(user.email,
                            style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withOpacity(0.65))),
                      const SizedBox(height: 6),
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('${user.role.emoji}  ${user.role.label}',
                              style: AppTextStyles.labelMedium.copyWith(color: Colors.white, fontSize: 11)),
                        ),
                        if (user.role == UserRole.vendor) ...[
                          const SizedBox(width: 8),
                          _BadgePill(tier: user.badgeTier),
                        ],
                      ]),
                    ],
                  )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  final VendorBadgeTier tier;
  const _BadgePill({required this.tier});
  @override
  Widget build(BuildContext context) {
    final c = Color(int.parse(tier.color.replaceFirst('#', 'FF'), radix: 16));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.withOpacity(0.22), borderRadius: BorderRadius.circular(20)),
      child: Text('${tier.emoji} ${tier.label}',
          style: AppTextStyles.labelMedium.copyWith(color: Colors.white, fontSize: 11)),
    );
  }
}

// ── Info Card ─────────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final AppUser user;
  const _InfoCard({required this.user});
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Account Info', style: AppTextStyles.headingMedium),
        const SizedBox(height: 14),
        _Row('Name', user.name),
        _Row('Phone', '+88 ${user.phone}'),
        _Row('Email', user.email),
        _Row('Role', user.role.label),
        if (user.city != null) _Row('City', user.city!),
        if (user.nidNumber != null) _Row('NID', '${user.nidNumber!.substring(0, 4)}••••'),
      ]),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}

// ── Badge Card ────────────────────────────────────────────────────────────────
class _BadgeCard extends StatelessWidget {
  final AppUser user;
  const _BadgeCard({required this.user});
  @override
  Widget build(BuildContext context) {
    final tier = user.badgeTier;
    final color = Color(int.parse(tier.color.replaceFirst('#', 'FF'), radix: 16));
    return GlassCard(
      backgroundColor: color.withOpacity(0.06),
      borderColor: color.withOpacity(0.25),
      child: Row(children: [
        Text(tier.emoji, style: const TextStyle(fontSize: 36)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(tier.label, style: AppTextStyles.headingLarge.copyWith(color: color)),
            const SizedBox(width: 8),
            Text('Vendor Rank', style: AppTextStyles.bodySmall),
          ]),
          const SizedBox(height: 4),
          Text(tier.description, style: AppTextStyles.bodySmall),
          const SizedBox(height: 8),
          Row(children: [
            _StatChip(
              user.totalReviews == 0 ? 'N/A' : '${user.rating.toStringAsFixed(1)} ⭐',
              'Rating', color),
            const SizedBox(width: 10),
            _StatChip('${user.totalReviews}', 'Reviews', color),
            const SizedBox(width: 10),
            _StatChip('${user.totalBookings}', 'Bookings', color),
          ]),
        ])),
      ]),
    ).animate(delay: 50.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatChip(this.value, this.label, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Text(value, style: AppTextStyles.headingSmall.copyWith(color: color, fontSize: 13)),
        Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 9)),
      ]),
    );
  }
}

// ── Vendor Info Card ──────────────────────────────────────────────────────────
class _VendorInfoCard extends StatelessWidget {
  final AppUser user;
  const _VendorInfoCard({required this.user});
  @override
  Widget build(BuildContext context) {
    final avail = user.availabilityStatus;
    final availColor = avail == 'available' ? AppColors.success
        : avail == 'busy' ? AppColors.warning : AppColors.error;
    return GlassCard(
      backgroundColor: AppColors.gold.withOpacity(0.06),
      borderColor: AppColors.gold.withOpacity(0.2),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Vendor Profile', style: AppTextStyles.headingMedium),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: availColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20),
                border: Border.all(color: availColor.withOpacity(0.3))),
            child: Text('● ${avail[0].toUpperCase()}${avail.substring(1)}',
                style: AppTextStyles.bodySmall.copyWith(color: availColor, fontWeight: FontWeight.w700, fontSize: 11)),
          ),
        ]),
        const SizedBox(height: 14),
        if (user.vendorCategory != null) _Row('Category', ServiceCategories.iconFor(user.vendorCategory!) + '  ${user.vendorCategory!}'),
        if (user.location != null) _Row('Base City', user.location!),
        if (user.yearsExperience > 0) _Row('Experience', '${user.yearsExperience} years'),
        if (user.priceRangeMin != null && user.priceRangeMax != null)
          _Row('Price Range', '৳${user.priceRangeMin} – ৳${user.priceRangeMax}'),
        if (user.serviceAreas.isNotEmpty)
          _Row('Service Areas', user.serviceAreas.join(', ')),
        if (user.bio != null && user.bio!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Bio', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(user.bio!, style: AppTextStyles.bodyMedium),
            ]),
          ),
        _Row('Verified', user.isVerified ? '✅ Verified' : '⏳ Pending'),
        _Row('Subscription', user.subscriptionTier == 'premium' ? '⭐ Premium' : '🆓 Free'),
      ]),
    ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}

// ── Portfolio Card ────────────────────────────────────────────────────────────
class _PortfolioCard extends StatelessWidget {
  final List<String> urls;
  const _PortfolioCard({required this.urls});
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Portfolio', style: AppTextStyles.headingMedium),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: urls.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: urls[i],
                width: 100, height: 100, fit: BoxFit.cover,
                placeholder: (_, __) => Container(width: 100, height: 100,
                    color: AppColors.charcoal.withOpacity(0.08),
                    child: const Icon(Icons.image_rounded, color: AppColors.charcoalLight)),
                errorWidget: (_, __, ___) => Container(width: 100, height: 100,
                    color: AppColors.charcoal.withOpacity(0.08),
                    child: const Icon(Icons.broken_image_rounded, color: AppColors.charcoalLight)),
              ),
            ),
          ),
        ),
      ]),
    ).animate(delay: 150.ms).fadeIn(duration: 400.ms);
  }
}

// ── Account Card ──────────────────────────────────────────────────────────────
class _AccountCard extends StatelessWidget {
  final AppUser user;
  const _AccountCard({required this.user});
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      backgroundColor: AppColors.charcoal.withOpacity(0.04),
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        const Text('🔒', style: TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(child: Text(
          'Account connected to Supabase. Data is securely stored in the cloud.',
          style: AppTextStyles.bodySmall,
        )),
      ]),
    ).animate(delay: 200.ms).fadeIn(duration: 400.ms);
  }
}

// ── Shared row widget ─────────────────────────────────────────────────────────
class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        SizedBox(width: 110,
            child: Text(label, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600))),
        Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
      ]),
    );
  }
}

// ── Help & Support Card ───────────────────────────────────────────────────────
class _HelpSupportCard extends StatefulWidget {
  final String userId;
  const _HelpSupportCard({required this.userId});
  @override
  State<_HelpSupportCard> createState() => _HelpSupportCardState();
}

class _HelpSupportCardState extends State<_HelpSupportCard> {
  bool _loading = false;

  Future<void> _openSupportChat() async {
    setState(() => _loading = true);
    final convo = await ChatService.getOrCreateSupportConversation(widget.userId);
    setState(() => _loading = false);

    if (!mounted) return;
    if (convo == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not open support chat. Please try again.'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ChatScreen(
          conversationId: convo.id,
          otherUserName: 'Admin Support',
        ),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      backgroundColor: const Color(0xFF6C63FF).withOpacity(0.05),
      borderColor: const Color(0xFF6C63FF).withOpacity(0.2),
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.support_agent_rounded,
                color: Color(0xFF6C63FF), size: 22),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Help & Support',
                style: AppTextStyles.headingSmall.copyWith(
                    color: const Color(0xFF6C63FF))),
            Text('Chat directly with an admin',
                style: AppTextStyles.bodySmall),
          ],
        )),
        _loading
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFF6C63FF)))
            : GestureDetector(
                onTap: _openSupportChat,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Chat',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
      ]),
    ).animate(delay: 250.ms).fadeIn(duration: 400.ms);
  }
}

// ── Language Toggle Card ───────────────────────────────────────────────────────
class _LanguageToggleCard extends StatefulWidget {
  @override
  State<_LanguageToggleCard> createState() => _LanguageToggleCardState();
}

class _LanguageToggleCardState extends State<_LanguageToggleCard> {
  @override
  void initState() {
    super.initState();
    AppStrings.languageNotifier.addListener(_rebuild);
  }

  @override
  void dispose() {
    AppStrings.languageNotifier.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final isBn = AppStrings.isBengali;
    return GlassCard(
      child: Row(children: [
        const Icon(Icons.language_rounded, color: AppColors.charcoalMid, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Language / ভাষা', style: AppTextStyles.headingSmall),
            Text(isBn ? 'বাংলা চালু আছে' : 'English is active',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.charcoalLight)),
          ],
        )),
        GestureDetector(
          onTap: () => AppStrings.setLanguage(isBn ? 'en' : 'bn'),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 72, height: 32,
            decoration: BoxDecoration(
              color: isBn ? AppColors.crimson : AppColors.charcoal.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: isBn ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(3),
                  width: 26, height: 26,
                  decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                  child: Center(
                    child: Text(isBn ? 'বা' : 'En',
                        style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: isBn ? AppColors.crimson : AppColors.charcoalMid)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

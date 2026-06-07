import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/service_categories.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_guard.dart';
import '../request/request_creation_screen.dart';
import '../shell/app_shell.dart';
import '../vendor/vendor_home.dart';
import '../vendor/vendor_profile_setup.dart';
import 'public_vendor_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Stock images (Unsplash — freely usable)
// ─────────────────────────────────────────────────────────────────────────────
const _heroImage =
    'https://images.unsplash.com/photo-1519741497674-611481863552?w=1600&q=80';

const _serviceSlides = [
  (
    'https://images.unsplash.com/photo-1520854221256-17451cc331bf?w=900&q=80',
    'Photography & Video',
    'Capture every cherished moment in cinematic quality'
  ),
  (
    'https://images.unsplash.com/photo-1464366400600-7168b8af9bc3?w=900&q=80',
    'Venue & Decor',
    'Transform any space into the wedding of your dreams'
  ),
  (
    'https://images.unsplash.com/photo-1567532939604-b6b5b0db2604?w=900&q=80',
    'Bridal Makeup',
    'Look radiant on your most important day'
  ),
  (
    'https://images.unsplash.com/photo-1525772764200-be829a350797?w=900&q=80',
    'Catering & Food',
    'Delight guests with exquisite culinary experiences'
  ),
];

const _lastWorksImages = [
  'https://images.unsplash.com/photo-1606216794074-735e91aa2c92?w=600&q=80',
  'https://images.unsplash.com/photo-1591604466107-ec97de577aff?w=600&q=80',
  'https://images.unsplash.com/photo-1583939003579-730e3918a45a?w=600&q=80',
  'https://images.unsplash.com/photo-1511285560929-80b456fea0bc?w=600&q=80',
  'https://images.unsplash.com/photo-1519225421980-715cb0215aed?w=600&q=80',
  'https://images.unsplash.com/photo-1549417229-aa67d3263c09?w=600&q=80',
];

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE 3D TILT CARD — wraps any child with gyroscope-style depth on drag
// ─────────────────────────────────────────────────────────────────────────────
class _TiltCard extends StatefulWidget {
  final Widget child;
  final double maxTilt;
  const _TiltCard({required this.child, this.maxTilt = 0.25});
  @override
  State<_TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<_TiltCard> {
  double _rotX = 0;
  double _rotY = 0;
  bool _hovered = false;

  void _onPan(DragUpdateDetails d, BoxConstraints c) {
    setState(() {
      _rotY = ((d.localPosition.dx / c.maxWidth) - 0.5) * widget.maxTilt;
      _rotX = -(((d.localPosition.dy / c.maxHeight) - 0.5) * widget.maxTilt);
    });
  }

  void _reset() => setState(() { _rotX = 0; _rotY = 0; });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) { setState(() => _hovered = false); _reset(); },
        child: GestureDetector(
          onPanUpdate: (d) => _onPan(d, constraints),
          onPanEnd: (_) => _reset(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(_rotX)
              ..rotateY(_rotY),
            transformAlignment: Alignment.center,
            child: widget.child,
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class LandingHomeScreen extends StatefulWidget {
  /// Called when the user taps "Browse Vendors" — switches the shell to the
  /// Vendors tab instead of pushing a new route on top.
  final VoidCallback? onNavigateToVendors;
  const LandingHomeScreen({super.key, this.onNavigateToVendors});
  @override
  State<LandingHomeScreen> createState() => _LandingHomeScreenState();
}

class _LandingHomeScreenState extends State<LandingHomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _meshCtrl;
  late final PageController _slideCtrl;
  int _slideIndex = 0;
  Timer? _slideTimer;

  @override
  void initState() {
    super.initState();
    _meshCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 10))
      ..repeat(reverse: true);
    _slideCtrl = PageController(viewportFraction: 0.92);
    _slideTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_slideIndex + 1) % _serviceSlides.length;
      _slideCtrl.animateToPage(next,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic);
      setState(() => _slideIndex = next);
    });
  }

  @override
  void dispose() {
    _meshCtrl.dispose();
    _slideCtrl.dispose();
    _slideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // ── Hero ──────────────────────────────────────────────────────────
          SliverToBoxAdapter(child: _HeroSection(
            meshCtrl: _meshCtrl,
            onNavigateToVendors: widget.onNavigateToVendors,
          )),
          // ── Category Circles ──────────────────────────────────────────────
          SliverToBoxAdapter(child: _CategorySection()),
          // ── Service Auto-slider ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: _ServiceSlider(
              ctrl: _slideCtrl,
              currentIndex: _slideIndex,
              onPageChanged: (i) => setState(() => _slideIndex = i),
            ),
          ),
          // ── Stats Counter ─────────────────────────────────────────────────
          SliverToBoxAdapter(child: _StatsSection()),
          // ── About Utsob ───────────────────────────────────────────────────
          SliverToBoxAdapter(child: _AboutSection()),
          // ── Trusted Network ───────────────────────────────────────────────
          SliverToBoxAdapter(child: _TrustedNetworkSection()),
          // ── Last Works Gallery ────────────────────────────────────────────
          SliverToBoxAdapter(child: _LastWorksSection()),
          // ── Final CTA ────────────────────────────────────────────────────
          SliverToBoxAdapter(child: _FinalCTA()),
          // ── Footer ──────────────────────────────────────────────────────
          SliverToBoxAdapter(child: _FooterSection()),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _HeroSection extends StatefulWidget {
  final AnimationController meshCtrl;
  final VoidCallback? onNavigateToVendors;
  const _HeroSection({required this.meshCtrl, this.onNavigateToVendors});
  @override
  State<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<_HeroSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatCtrl;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final isWide = MediaQuery.of(context).size.width >= 720;

    return SizedBox(
      height: isWide ? h * 0.85 : h * 0.88,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background image ──────────────────────────────────────────────
          CachedNetworkImage(
            imageUrl: _heroImage,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: const Color(0xFF2A0A10)),
            errorWidget: (_, __, ___) =>
                Container(color: const Color(0xFF2A0A10)),
          ),

          // ── Gradient overlay ──────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x55000000),
                  Color(0x99000000),
                  Color(0xCC000000),
                  Color(0xEE1A0008),
                ],
                stops: [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),

          // ── Animated mesh orbs ────────────────────────────────────────────
          AnimatedBuilder(
            animation: widget.meshCtrl,
            builder: (_, __) {
              final t = widget.meshCtrl.value;
              return Stack(children: [
                Positioned(
                  top: -80 + t * 40,
                  right: -60 + t * 30,
                  child: Container(
                    width: 280, height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        AppColors.gold.withOpacity(0.18 + t * 0.08),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 100 - t * 30,
                  left: -40 + t * 20,
                  child: Container(
                    width: 200, height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        AppColors.crimson.withOpacity(0.22 + t * 0.08),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),
              ]);
            },
          ),

          // ── Floating decorative rings ─────────────────────────────────────
          AnimatedBuilder(
            animation: _floatCtrl,
            builder: (_, __) {
              final t = _floatCtrl.value;
              return Stack(children: [
                Positioned(
                  top: 80 + t * 12,
                  right: 30,
                  child: _FloatingRing(size: 60, color: AppColors.gold, t: t),
                ),
                Positioned(
                  top: 160 + t * 8,
                  left: 20,
                  child: _FloatingRing(size: 40, color: Colors.white, t: t, delay: 0.5),
                ),
              ]);
            },
          ),

          // ── Content ───────────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 60 : 28, vertical: 20),
              child: isWide
                  ? _HeroContentWide(onNavigateToVendors: widget.onNavigateToVendors)
                  : _HeroContentMobile(onNavigateToVendors: widget.onNavigateToVendors),
            ),
          ),

          // ── Scroll hint ───────────────────────────────────────────────────
          Positioned(
            bottom: 24,
            left: 0, right: 0,
            child: Column(children: [
              AnimatedBuilder(
                animation: _floatCtrl,
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, _floatCtrl.value * 6),
                  child: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: Colors.white54, size: 28),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _FloatingRing extends StatelessWidget {
  final double size;
  final Color color;
  final double t;
  final double delay;
  const _FloatingRing({
    required this.size, required this.color,
    required this.t, this.delay = 0,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = 0.15 + 0.10 * math.sin((t + delay) * math.pi);
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(opacity), width: 1.5),
      ),
    );
  }
}

class _HeroContentMobile extends StatelessWidget {
  final VoidCallback? onNavigateToVendors;
  const _HeroContentMobile({this.onNavigateToVendors});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(flex: 2),
        // Bengali headline
        Text('উৎসব',
            style: AppTextStyles.displaySmall.copyWith(
              color: AppColors.gold,
              fontSize: 64,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              height: 1.0,
              shadows: [
                Shadow(color: AppColors.gold.withOpacity(0.5), blurRadius: 20),
              ],
            )
        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0),

        const SizedBox(height: 4),

        Text('Bangladesh\'s Premier\nWedding Marketplace',
            style: AppTextStyles.displaySmall.copyWith(
              color: Colors.white,
              fontSize: 26,
              height: 1.25,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            )
        ).animate(delay: 150.ms).fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),

        const SizedBox(height: 14),
        Text(
          'Connect with verified vendors · Get competitive bids\nBook your dream celebration with confidence',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white.withOpacity(0.72),
            height: 1.55,
          ),
        ).animate(delay: 300.ms).fadeIn(duration: 500.ms),

        const SizedBox(height: 32),

        // CTA row — adapts to user role
        Builder(builder: (context) {
          final isVendor = AuthService.currentUser?.role == UserRole.vendor;
          return Row(children: [
            _HeroCTA(
              label: isVendor ? 'My Dashboard' : 'Browse Vendors',
              icon: isVendor ? Icons.dashboard_rounded : Icons.storefront_rounded,
              gradient: const LinearGradient(
                colors: [AppColors.crimson, Color(0xFF950025)],
              ),
              onTap: isVendor
                  ? () => Navigator.push(context, PageRouteBuilder(
                        pageBuilder: (_, __, ___) => const VendorHome(),
                        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
                      ))
                  : () => AppShell.of(context)?.goToVendors(),
            ),
            const SizedBox(width: 12),
            _HeroCTA(
              label: isVendor ? 'My Packages' : 'Post Event',
              icon: isVendor ? Icons.inventory_2_rounded : Icons.add_circle_rounded,
              gradient: LinearGradient(
                colors: isVendor
                    ? [const Color(0xFF3B6BDD), const Color(0xFF5585F0)]
                    : [AppColors.gold, AppColors.goldLight],
              ),
              onTap: isVendor
                  ? () => Navigator.push(context, PageRouteBuilder(
                        pageBuilder: (_, __, ___) => const VendorProfileSetupScreen(),
                        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
                      ))
                  : () => AuthGuard.check(
                        context,
                        message: 'Sign in to post your event and receive bids from vendors.',
                        onAuthenticated: () => Navigator.push(context, PageRouteBuilder(
                          pageBuilder: (_, __, ___) => const RequestCreationScreen(),
                          transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
                        )),
                      ),
              darkText: !isVendor,
            ),
          ]).animate(delay: 450.ms).fadeIn(duration: 500.ms).slideY(begin: 0.15, end: 0);
        }),

        const Spacer(flex: 1),

        // Trust pills
        Wrap(spacing: 8, runSpacing: 6, children: [
          _TrustPill('✅ Verified Vendors'),
          _TrustPill('🔒 Secure Payments'),
          _TrustPill('⭐ Rated & Reviewed'),
        ]).animate(delay: 600.ms).fadeIn(duration: 400.ms),

        const SizedBox(height: 40),
      ],
    );
  }
}

class _HeroContentWide extends StatelessWidget {
  final VoidCallback? onNavigateToVendors;
  const _HeroContentWide({this.onNavigateToVendors});
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left text column
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('উৎসব',
                  style: AppTextStyles.displaySmall.copyWith(
                    color: AppColors.gold,
                    fontSize: 96,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -2,
                    height: 1.0,
                    shadows: [
                      Shadow(color: AppColors.gold.withOpacity(0.5), blurRadius: 30),
                    ],
                  )
              ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.15, end: 0),

              const SizedBox(height: 8),
              Text('Bangladesh\'s Premier\nWedding Marketplace',
                  style: AppTextStyles.displaySmall.copyWith(
                    color: Colors.white, fontSize: 42,
                    height: 1.2, fontWeight: FontWeight.w700, letterSpacing: -0.5,
                  )
              ).animate(delay: 150.ms).fadeIn(duration: 500.ms),

              const SizedBox(height: 18),
              Text(
                'Connect with verified vendors · Get competitive bids\nBook your dream celebration with full confidence',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white.withOpacity(0.72),
                  height: 1.6, fontSize: 16,
                ),
              ).animate(delay: 280.ms).fadeIn(duration: 500.ms),

              const SizedBox(height: 40),
              Builder(builder: (context) {
                final isVendor = AuthService.currentUser?.role == UserRole.vendor;
                return Row(children: [
                  _HeroCTA(
                    label: isVendor ? 'My Dashboard' : 'Browse Vendors',
                    icon: isVendor ? Icons.dashboard_rounded : Icons.storefront_rounded,
                    gradient: const LinearGradient(
                      colors: [AppColors.crimson, Color(0xFF950025)],
                    ),
                    onTap: isVendor
                        ? () => Navigator.push(context, PageRouteBuilder(
                              pageBuilder: (_, __, ___) => const VendorHome(),
                              transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
                            ))
                        : () => AppShell.of(context)?.goToVendors(),
                    large: true,
                  ),
                  const SizedBox(width: 14),
                  _HeroCTA(
                    label: isVendor ? 'View My Packages' : 'Post Your Event',
                    icon: isVendor ? Icons.inventory_2_rounded : Icons.add_circle_rounded,
                    gradient: LinearGradient(
                      colors: isVendor
                          ? [const Color(0xFF3B6BDD), const Color(0xFF5585F0)]
                          : [AppColors.gold, AppColors.goldLight],
                    ),
                    onTap: isVendor
                        ? () => Navigator.push(context, PageRouteBuilder(
                              pageBuilder: (_, __, ___) => const VendorProfileSetupScreen(),
                              transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
                            ))
                        : () => AuthGuard.check(
                              context,
                              message: 'Sign in to post your event.',
                              onAuthenticated: () => Navigator.push(context, PageRouteBuilder(
                                pageBuilder: (_, __, ___) => const RequestCreationScreen(),
                                transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
                              )),
                            ),
                    darkText: !isVendor,
                    large: true,
                  ),
                ]).animate(delay: 400.ms).fadeIn(duration: 500.ms);
              }),

              const SizedBox(height: 28),
              Wrap(spacing: 10, runSpacing: 8, children: [
                _TrustPill('✅ Verified Vendors'),
                _TrustPill('🔒 Secure Payments'),
                _TrustPill('⭐ Rated & Reviewed'),
                _TrustPill('🇧🇩 Bangladesh\'s #1'),
              ]).animate(delay: 550.ms).fadeIn(duration: 400.ms),
            ],
          ),
        ),
        const Spacer(flex: 1),
      ],
    );
  }
}

class _HeroCTA extends StatefulWidget {
  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;
  final bool darkText;
  final bool large;
  const _HeroCTA({
    required this.label, required this.icon,
    required this.gradient, required this.onTap,
    this.darkText = false, this.large = false,
  });
  @override
  State<_HeroCTA> createState() => _HeroCTAState();
}

class _HeroCTAState extends State<_HeroCTA>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  bool _hovered = false;
  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.94 : _hovered ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 140),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: widget.large ? 26 : 20,
              vertical: widget.large ? 16 : 13,
            ),
            decoration: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: widget.gradient.colors.first
                      .withOpacity(_pressed ? 0.20 : _hovered ? 0.55 : 0.40),
                  blurRadius: _hovered ? 28 : 20,
                  offset: Offset(0, _pressed ? 2 : _hovered ? 8 : 6),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(widget.icon,
                          color: widget.darkText ? AppColors.charcoal : Colors.white,
                          size: widget.large ? 18 : 16),
                      const SizedBox(width: 8),
                      Text(widget.label,
                          style: AppTextStyles.headingSmall.copyWith(
                            color: widget.darkText ? AppColors.charcoal : Colors.white,
                            fontSize: widget.large ? 15 : 13,
                            letterSpacing: 0.2,
                          )),
                    ],
                  ),
                  // Shimmer sweep
                  AnimatedBuilder(
                    animation: _shimmerCtrl,
                    builder: (_, __) => Positioned.fill(
                      child: FractionalTranslation(
                        translation: Offset(_shimmerCtrl.value * 3 - 0.8, 0),
                        child: Container(
                          width: 36,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              Colors.white.withOpacity(0),
                              Colors.white.withOpacity(
                                  widget.darkText ? 0.35 : 0.28),
                              Colors.white.withOpacity(0),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrustPill extends StatelessWidget {
  final String text;
  const _TrustPill(this.text);
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.20)),
          ),
          child: Text(text,
              style: const TextStyle(
                  color: Colors.white, fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CATEGORY CIRCLES SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _CategorySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cats = ServiceCategories.all;
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.only(top: 56, bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionChip('সার্ভিস ক্যাটাগরি'),
                const SizedBox(height: 8),
                Text('Browse by Category',
                    style: AppTextStyles.displaySmall.copyWith(fontSize: 26)),
                const SizedBox(height: 6),
                Text(
                  'Everything you need for the perfect celebration',
                  style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.charcoalLight),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          // Horizontal scroll of circles
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: cats.length,
              itemBuilder: (_, i) => _CategoryCircle(
                category: cats[i],
                index: i,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Category gradient pairs
const _catGradients = [
  [Color(0xFFFFECD2), Color(0xFFFFB347)],
  [Color(0xFFFFE0E0), Color(0xFFFF6B6B)],
  [Color(0xFFE8F5E9), Color(0xFF66BB6A)],
  [Color(0xFFE3F2FD), Color(0xFF42A5F5)],
  [Color(0xFFF3E5F5), Color(0xFFAB47BC)],
  [Color(0xFFFFF8E1), Color(0xFFFFCA28)],
  [Color(0xFFE0F7FA), Color(0xFF26C6DA)],
  [Color(0xFFFCE4EC), Color(0xFFEC407A)],
];

class _CategoryCircle extends StatefulWidget {
  final String category;
  final int index;
  const _CategoryCircle({required this.category, required this.index});
  @override
  State<_CategoryCircle> createState() => _CategoryCircleState();
}

class _CategoryCircleState extends State<_CategoryCircle> {
  bool _pressed = false;
  bool _hovered = false;
  double _rotX = 0;
  double _rotY = 0;

  void _onPan(DragUpdateDetails d) {
    setState(() {
      _rotY = ((d.localPosition.dx / 72) - 0.5) * 0.45;
      _rotX = -(((d.localPosition.dy / 72) - 0.5) * 0.45);
    });
  }

  void _resetTilt() => setState(() { _rotX = 0; _rotY = 0; });

  @override
  Widget build(BuildContext context) {
    final emoji = ServiceCategories.iconFor(widget.category);
    final gi = widget.index % _catGradients.length;
    final colors = _catGradients[gi];

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) { setState(() => _hovered = false); _resetTilt(); },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          AppShell.of(context)?.goToVendorsWithCategory(widget.category);
        },
        onTapCancel: () => setState(() => _pressed = false),
        onPanUpdate: _onPan,
        onPanEnd: (_) => _resetTilt(),
        child: AnimatedScale(
          scale: _pressed ? 0.88 : 1.0,
          duration: const Duration(milliseconds: 130),
          child: Container(
            width: 86,
            margin: const EdgeInsets.only(right: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glow ring — visible on hover
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: _hovered ? 80 : 72,
                  height: _hovered ? 80 : 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _hovered
                        ? RadialGradient(colors: [
                            colors.last.withOpacity(0.35),
                            colors.last.withOpacity(0),
                          ])
                        : null,
                    boxShadow: _hovered
                        ? [BoxShadow(
                            color: colors.last.withOpacity(0.45),
                            blurRadius: 24, spreadRadius: 2,
                          )]
                        : [],
                  ),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateX(_rotX)
                        ..rotateY(_rotY),
                      transformAlignment: Alignment.center,
                      child: Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: colors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: _hovered
                              ? Border.all(
                                  color: Colors.white.withOpacity(0.75),
                                  width: 2.5)
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: colors.last.withOpacity(
                                  _hovered ? 0.50 : 0.30),
                              blurRadius: _hovered ? 20 : 12,
                              offset: const Offset(0, 5),
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(emoji,
                              style: TextStyle(
                                  fontSize: _hovered ? 30 : 28)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 10,
                      fontWeight: _hovered ? FontWeight.w700 : FontWeight.w600,
                      color: _hovered
                          ? colors.last
                          : AppColors.charcoalMid),
                  child: Text(
                    widget.category.split(' ').take(2).join(' '),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      )
          .animate(delay: Duration(milliseconds: widget.index * 55))
          .fadeIn(duration: 400.ms)
          .slideX(begin: 0.15, end: 0, curve: Curves.easeOutCubic)
          .scale(begin: const Offset(0.85, 0.85), end: const Offset(1, 1),
              duration: 400.ms, curve: Curves.easeOutBack),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVICE AUTO-SLIDER
// ─────────────────────────────────────────────────────────────────────────────
class _ServiceSlider extends StatelessWidget {
  final PageController ctrl;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;
  const _ServiceSlider({
    required this.ctrl, required this.currentIndex,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F2EB),
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionChip('আমাদের সেবা'),
                const SizedBox(height: 8),
                Text('Our Services',
                    style: AppTextStyles.displaySmall.copyWith(fontSize: 26)),
                const SizedBox(height: 6),
                Text('Premium services for every wedding need',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.charcoalLight)),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 240,
            child: PageView.builder(
              controller: ctrl,
              onPageChanged: onPageChanged,
              itemCount: _serviceSlides.length,
              itemBuilder: (_, i) {
                final (img, title, subtitle) = _serviceSlides[i];
                return AnimatedScale(
                  scale: i == currentIndex ? 1.0 : 0.94,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  child: _ServiceSlide(
                    imageUrl: img, title: title, subtitle: subtitle),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          // Dot indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_serviceSlides.length, (i) {
              final sel = i == currentIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: sel ? 24 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: sel ? AppColors.crimson : AppColors.charcoal.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ServiceSlide extends StatelessWidget {
  final String imageUrl, title, subtitle;
  const _ServiceSlide({
    required this.imageUrl, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return _TiltCard(
      maxTilt: 0.12,
      child: RepaintBoundary(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.16),
                blurRadius: 28, offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6, offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: imageUrl, fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppColors.surface),
                  errorWidget: (_, __, ___) => Container(
                      color: AppColors.surface,
                      child: const Icon(Icons.image_rounded,
                          color: AppColors.charcoalLight)),
                ),
                // Dark gradient vignette
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.55),
                        Colors.black.withOpacity(0.80),
                      ],
                      stops: const [0.35, 0.70, 1.0],
                    ),
                  ),
                ),
                // Glossy glass text bar at bottom
                Positioned(
                  left: 16, right: 16, bottom: 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.18),
                            width: 1,
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.16),
                              Colors.white.withOpacity(0.04),
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(title,
                                style: AppTextStyles.headingLarge.copyWith(
                                    color: Colors.white, fontSize: 17,
                                    shadows: [
                                      Shadow(color: Colors.black38,
                                          blurRadius: 8),
                                    ])),
                            const SizedBox(height: 3),
                            Text(subtitle,
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.white.withOpacity(0.82))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATS SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _StatsSection extends StatefulWidget {
  @override
  State<_StatsSection> createState() => _StatsSectionState();
}

class _StatsSectionState extends State<_StatsSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));
    _progress = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    // Trigger once when visible — simple delayed start
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 600;
    final stats = [
      ('500+', 'Verified\nVendors', AppColors.crimson, '🏆'),
      ('2,000+', 'Events\nHosted', AppColors.gold, '🎊'),
      ('22', 'Service\nCategories', const Color(0xFF5C6BC0), '📦'),
      ('98%', 'Happy\nCouples', AppColors.freshTalent, '💍'),
    ];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1A0008), Color(0xFF2C0018), Color(0xFF3D1000)],
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
      child: Column(
        children: [
          _SectionChip('আমাদের পরিসংখ্যান', light: true),
          const SizedBox(height: 10),
          Text('Numbers That\nSpeak for Themselves',
              style: AppTextStyles.displaySmall.copyWith(
                  color: Colors.white, fontSize: 28, height: 1.2),
              textAlign: TextAlign.center),
          const SizedBox(height: 40),
          isWide
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: stats
                      .map((s) => Expanded(child: _StatCard(
                          value: s.$1, label: s.$2,
                          color: s.$3, emoji: s.$4,
                          progress: _progress)))
                      .toList(),
                )
              : GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.3,
                  children: stats
                      .map((s) => _StatCard(
                          value: s.$1, label: s.$2,
                          color: s.$3, emoji: s.$4,
                          progress: _progress))
                      .toList(),
                ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value, label, emoji;
  final Color color;
  final Animation<double> progress;
  const _StatCard({
    required this.value, required this.label, required this.emoji,
    required this.color, required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (_, __) => RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.14),
                    Colors.white.withOpacity(0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: color.withOpacity(0.30),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.20),
                    blurRadius: 28, offset: const Offset(0, 8),
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(height: 10),
                  Transform.scale(
                    scale: 0.6 + 0.4 * progress.value,
                    child: Opacity(
                      opacity: progress.value.clamp(0.0, 1.0),
                      child: Text(value,
                          style: AppTextStyles.displaySmall.copyWith(
                            color: color, fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            shadows: [
                              Shadow(
                                color: color.withOpacity(0.50),
                                blurRadius: 16,
                              ),
                            ],
                          )),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(label,
                      style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.70), height: 1.4),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate(delay: const Duration(milliseconds: 150))
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.20, end: 0, curve: Curves.easeOutCubic)
        .scale(begin: const Offset(0.90, 0.90), end: const Offset(1, 1),
            duration: 600.ms, curve: Curves.easeOutBack);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ABOUT SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _AboutSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 720;
    return Container(
      color: AppColors.background,
      padding: EdgeInsets.symmetric(
          horizontal: isWide ? 60 : 24, vertical: 56),
      child: isWide ? _AboutWide() : _AboutMobile(),
    );
  }
}

class _AboutMobile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionChip('আমাদের সম্পর্কে'),
        const SizedBox(height: 10),
        Text('The Smartest Way to Plan\nYour Wedding',
            style: AppTextStyles.displaySmall.copyWith(fontSize: 26, height: 1.25)),
        const SizedBox(height: 16),
        Text(
          'Utsob is Bangladesh\'s first reverse-bidding wedding marketplace. '
          'Instead of you searching endlessly, verified vendors bid on your event — '
          'giving you competitive prices and the best talent, guaranteed.',
          style: AppTextStyles.bodyMedium.copyWith(
              height: 1.7, color: AppColors.charcoalMid),
        ),
        const SizedBox(height: 28),
        ..._aboutPoints.asMap().entries.map((e) => _AboutPoint(
            icon: e.value.$1, title: e.value.$2, desc: e.value.$3,
            index: e.key)),
      ],
    );
  }
}

class _AboutWide extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionChip('আমাদের সম্পর্কে'),
              const SizedBox(height: 10),
              Text('The Smartest Way\nto Plan Your Wedding',
                  style: AppTextStyles.displaySmall.copyWith(
                      fontSize: 34, height: 1.2)),
              const SizedBox(height: 16),
              Text(
                'Utsob is Bangladesh\'s first reverse-bidding wedding marketplace. '
                'Instead of you searching endlessly, verified vendors bid on your event — '
                'giving you competitive prices and the best talent, guaranteed.',
                style: AppTextStyles.bodyMedium.copyWith(
                    height: 1.75, fontSize: 16, color: AppColors.charcoalMid),
              ),
            ],
          ),
        ),
        const SizedBox(width: 60),
        Expanded(
          flex: 5,
          child: Column(
            children: _aboutPoints.asMap().entries
                .map((e) => _AboutPoint(
                    icon: e.value.$1, title: e.value.$2,
                    desc: e.value.$3, index: e.key))
                .toList(),
          ),
        ),
      ],
    );
  }
}

const _aboutPoints = [
  ('🎯', 'Reverse Bidding', 'Post your event once, vendors come to you with their best offers.'),
  ('🛡️', 'Verified Only', 'Every vendor passes our strict verification and review system.'),
  ('💬', 'Direct Chat', 'Communicate with vendors in real-time before making any decision.'),
  ('📊', 'Budget Tracking', 'Built-in budget planner keeps every cost under control.'),
];

class _AboutPoint extends StatefulWidget {
  final String icon, title, desc;
  final int index;
  const _AboutPoint({
    required this.icon, required this.title,
    required this.desc, this.index = 0,
  });
  @override
  State<_AboutPoint> createState() => _AboutPointState();
}

class _AboutPointState extends State<_AboutPoint> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _hovered ? Colors.white : Colors.white.withOpacity(0.90),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _hovered
                ? AppColors.crimson.withOpacity(0.20)
                : AppColors.charcoal.withOpacity(0.06),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? AppColors.crimson.withOpacity(0.10)
                  : Colors.black.withOpacity(0.04),
              blurRadius: _hovered ? 24 : 16,
              offset: Offset(0, _hovered ? 8 : 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: _hovered
                    ? AppColors.crimson.withOpacity(0.12)
                    : AppColors.crimson.withOpacity(0.07),
                borderRadius: BorderRadius.circular(14),
                boxShadow: _hovered
                    ? [BoxShadow(
                        color: AppColors.crimson.withOpacity(0.20),
                        blurRadius: 12, offset: const Offset(0, 3),
                      )]
                    : [],
              ),
              child: Center(child: Text(widget.icon,
                  style: TextStyle(fontSize: _hovered ? 24 : 22))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: AppTextStyles.headingSmall.copyWith(
                    color: _hovered ? AppColors.crimson : AppColors.charcoal,
                  ),
                  child: Text(widget.title),
                ),
                const SizedBox(height: 4),
                Text(widget.desc,
                    style: AppTextStyles.bodySmall.copyWith(height: 1.55)),
              ],
            )),
            if (_hovered)
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 13, color: AppColors.crimson),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 100 + widget.index * 80))
        .fadeIn(duration: 450.ms)
        .slideX(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TRUSTED NETWORK SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _TrustedNetworkSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 600;
    final tiers = [
      (
        '🏆',
        'Premium Gold',
        'Top-rated vendors with 50+ bookings and 4.5+ stars. The best in Bangladesh.',
        AppColors.premiumGold,
        AppColors.premiumGoldBg,
      ),
      (
        '✦',
        'Verified Silver',
        'Established vendors with proven track record and verified credentials.',
        AppColors.verifiedSilver,
        AppColors.verifiedSilverBg,
      ),
      (
        '🌱',
        'Fresh Talent',
        'Rising stars with competitive pricing and a hunger to impress.',
        AppColors.freshTalent,
        AppColors.freshTalentBg,
      ),
    ];

    return Container(
      color: const Color(0xFFF5F2EB),
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 60 : 24,
        vertical: 56,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionChip('বিশ্বস্ত নেটওয়ার্ক'),
          const SizedBox(height: 10),
          Text('Our Trusted Vendor Network',
              style: AppTextStyles.displaySmall.copyWith(fontSize: 26)),
          const SizedBox(height: 6),
          Text('Every vendor on Utsob is verified and ranked by performance',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.charcoalLight)),
          const SizedBox(height: 32),
          isWide
              ? Row(
                  children: tiers.asMap().entries
                      .map((e) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: _TierCard(
                              emoji: e.value.$1, title: e.value.$2,
                              desc: e.value.$3, color: e.value.$4,
                              bgColor: e.value.$5, index: e.key),
                          )))
                      .toList(),
                )
              : Column(
                  children: tiers.asMap().entries
                      .map((e) => _TierCard(
                          emoji: e.value.$1, title: e.value.$2,
                          desc: e.value.$3, color: e.value.$4,
                          bgColor: e.value.$5, index: e.key))
                      .toList(),
                ),
        ],
      ),
    );
  }
}

class _TierCard extends StatefulWidget {
  final String emoji, title, desc;
  final Color color, bgColor;
  final int index;
  const _TierCard({
    required this.emoji, required this.title, required this.desc,
    required this.color, required this.bgColor, this.index = 0,
  });
  @override
  State<_TierCard> createState() => _TierCardState();
}

class _TierCardState extends State<_TierCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: _TiltCard(
        maxTilt: 0.10,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _hovered
                  ? widget.color.withOpacity(0.45)
                  : widget.color.withOpacity(0.20),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color
                    .withOpacity(_hovered ? 0.22 : 0.08),
                blurRadius: _hovered ? 32 : 18,
                offset: Offset(0, _hovered ? 12 : 6),
                spreadRadius: _hovered ? -2 : -4,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: widget.bgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.color.withOpacity(
                        _hovered ? 0.50 : 0.20)),
                  boxShadow: _hovered
                      ? [BoxShadow(
                          color: widget.color.withOpacity(0.25),
                          blurRadius: 14, offset: const Offset(0, 4),
                        )]
                      : [],
                ),
                child: Center(child: Text(widget.emoji,
                    style: TextStyle(fontSize: _hovered ? 28 : 26))),
              ),
              const SizedBox(height: 16),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: AppTextStyles.headingMedium.copyWith(
                  color: widget.color,
                  fontWeight: _hovered ? FontWeight.w700 : FontWeight.w600,
                ),
                child: Text(widget.title),
              ),
              const SizedBox(height: 6),
              Text(widget.desc,
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.charcoalMid, height: 1.60)),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 80 + widget.index * 100))
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic)
        .scale(begin: const Offset(0.94, 0.94), end: const Offset(1, 1),
            duration: 500.ms, curve: Curves.easeOutBack);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LAST WORKS GALLERY
// ─────────────────────────────────────────────────────────────────────────────
class _LastWorksSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 600;
    return Container(
      color: AppColors.background,
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 60 : 24,
        vertical: 56,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionChip('আমাদের কাজ'),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Last Works',
                  style: AppTextStyles.displaySmall.copyWith(fontSize: 26)),
              Text('View All →',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.crimson, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          Text('Real weddings powered by our vendor network',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.charcoalLight)),
          const SizedBox(height: 28),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isWide ? 3 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: _lastWorksImages.length,
            itemBuilder: (_, i) => _WorkCard(
                imageUrl: _lastWorksImages[i], index: i),
          ),
        ],
      ),
    );
  }
}

class _WorkCard extends StatefulWidget {
  final String imageUrl;
  final int index;
  const _WorkCard({required this.imageUrl, required this.index});
  @override
  State<_WorkCard> createState() => _WorkCardState();
}

class _WorkCardState extends State<_WorkCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: _TiltCard(
        maxTilt: 0.12,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_hovered ? 0.22 : 0.07),
                blurRadius: _hovered ? 28 : 12,
                offset: Offset(0, _hovered ? 10 : 4),
                spreadRadius: -2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedScale(
                  scale: _hovered ? 1.07 : 1.0,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AppColors.surface),
                    errorWidget: (_, __, ___) => Container(color: AppColors.surface),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(_hovered ? 0.60 : 0.20),
                      ],
                    ),
                  ),
                ),
                if (_hovered)
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 9),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.35)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.zoom_in_rounded,
                                  color: Colors.white, size: 16),
                              SizedBox(width: 5),
                              Text('View',
                                  style: TextStyle(
                                    color: Colors.white, fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: widget.index * 80))
        .fadeIn(duration: 450.ms)
        .scale(
          begin: const Offset(0.90, 0.90),
          end: const Offset(1, 1),
          duration: 450.ms,
          curve: Curves.easeOutBack,
        );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FINAL CTA
// ─────────────────────────────────────────────────────────────────────────────
class _FinalCTA extends StatefulWidget {
  @override
  State<_FinalCTA> createState() => _FinalCTAState();
}

class _FinalCTAState extends State<_FinalCTA>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, child) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [
              const Color(0xFF800020),
              Color.lerp(const Color(0xFF4A0018), const Color(0xFF5A0020),
                  _pulseCtrl.value)!,
              const Color(0xFF2C0A00),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.crimson
                  .withOpacity(0.35 + 0.12 * _pulseCtrl.value),
              blurRadius: 40 + 12 * _pulseCtrl.value,
              offset: const Offset(0, 14),
              spreadRadius: -6,
            ),
          ],
        ),
        child: child,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Decorative orb
            Positioned(
              right: -40, top: -40,
              child: Container(
                width: 200, height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppColors.gold.withOpacity(0.18),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
            Positioned(
              left: -20, bottom: -30,
              child: Container(
                width: 130, height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    Colors.white.withOpacity(0.06),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 44),
              child: Column(
                children: [
                  const Text('💍', style: TextStyle(fontSize: 44))
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        begin: const Offset(1.0, 1.0),
                        end: const Offset(1.08, 1.08),
                        duration: 1200.ms,
                        curve: Curves.easeInOut,
                      ),
                  const SizedBox(height: 20),
                  Text('Start Planning Your\nDream Wedding Today',
                      style: AppTextStyles.displaySmall.copyWith(
                        color: Colors.white, fontSize: 28,
                        height: 1.2, fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center
                  ).animate().fadeIn(duration: 500.ms),

                  const SizedBox(height: 12),
                  Text(
                    'Join thousands of couples who trusted Utsob\nfor their most important day',
                    style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.72), height: 1.6),
                    textAlign: TextAlign.center,
                  ).animate(delay: 150.ms).fadeIn(duration: 400.ms),

                  const SizedBox(height: 32),
                  Builder(builder: (ctx) {
                    final user = AuthService.currentUser;
                    final isVendor = user?.role == UserRole.vendor;
                    final isLoggedIn = user != null;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isVendor) ...[
                          _FinalCTAButton(
                            label: 'My Dashboard',
                            onTap: () => Navigator.push(ctx, PageRouteBuilder(
                              pageBuilder: (_, __, ___) => const VendorHome(),
                              transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
                            )),
                            primary: true,
                          ),
                          const SizedBox(width: 12),
                          _FinalCTAButton(
                            label: 'View Packages',
                            onTap: () => Navigator.push(ctx, PageRouteBuilder(
                              pageBuilder: (_, __, ___) => const VendorProfileSetupScreen(),
                              transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
                            )),
                            primary: false,
                          ),
                        ] else ...[
                          _FinalCTAButton(
                            label: 'Browse Vendors',
                            onTap: () => AppShell.of(ctx)?.goToVendors(),
                            primary: true,
                          ),
                          if (!isLoggedIn) ...[
                            const SizedBox(width: 12),
                            _FinalCTAButton(
                              label: 'Sign Up Free',
                              onTap: () => Navigator.pushNamed(ctx, '/signup'),
                              primary: false,
                            ),
                          ] else ...[
                            const SizedBox(width: 12),
                            _FinalCTAButton(
                              label: 'Post Event',
                              onTap: () => Navigator.push(ctx, PageRouteBuilder(
                                pageBuilder: (_, __, ___) => const RequestCreationScreen(),
                                transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
                              )),
                              primary: false,
                            ),
                          ],
                        ],
                      ],
                    ).animate(delay: 300.ms).fadeIn(duration: 400.ms)
                        .slideY(begin: 0.1, end: 0);
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinalCTAButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool primary;
  const _FinalCTAButton({
    required this.label, required this.onTap, required this.primary});
  @override
  State<_FinalCTAButton> createState() => _FinalCTAButtonState();
}

class _FinalCTAButtonState extends State<_FinalCTAButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  bool _hovered = false;
  late final AnimationController _shimCtrl;

  @override
  void initState() {
    super.initState();
    _shimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat();
  }

  @override
  void dispose() {
    _shimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.93 : _hovered ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 140),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
            decoration: BoxDecoration(
              color: widget.primary
                  ? AppColors.gold
                  : Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(26),
              border: widget.primary
                  ? null
                  : Border.all(
                      color: Colors.white.withOpacity(_hovered ? 0.50 : 0.30)),
              boxShadow: widget.primary
                  ? [BoxShadow(
                      color: AppColors.gold
                          .withOpacity(_hovered ? 0.65 : 0.45),
                      blurRadius: _hovered ? 28 : 18,
                      offset: Offset(0, _hovered ? 10 : 6),
                    )]
                  : _hovered
                      ? [BoxShadow(
                          color: Colors.white.withOpacity(0.15),
                          blurRadius: 16, offset: const Offset(0, 4),
                        )]
                      : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(widget.label,
                      style: AppTextStyles.headingSmall.copyWith(
                        color: widget.primary
                            ? AppColors.charcoal
                            : Colors.white,
                        fontSize: 14,
                      )),
                  if (widget.primary)
                    AnimatedBuilder(
                      animation: _shimCtrl,
                      builder: (_, __) => Positioned.fill(
                        child: FractionalTranslation(
                          translation: Offset(_shimCtrl.value * 3 - 0.8, 0),
                          child: Container(
                            width: 32,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                Colors.white.withOpacity(0),
                                Colors.white.withOpacity(0.30),
                                Colors.white.withOpacity(0),
                              ]),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────
class _SectionChip extends StatelessWidget {
  final String text;
  final bool light;
  const _SectionChip(this.text, {this.light = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: light
            ? Colors.white.withOpacity(0.10)
            : AppColors.crimson.withOpacity(0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: light
              ? Colors.white.withOpacity(0.20)
              : AppColors.crimson.withOpacity(0.22),
        ),
      ),
      child: Text(text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: light ? Colors.white.withOpacity(0.80) : AppColors.crimson,
            letterSpacing: 0.3,
          )),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FOOTER
// ─────────────────────────────────────────────────────────────────────────────
class _FooterSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 720;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        border: Border(top: BorderSide(color: AppColors.gold.withOpacity(0.25), width: 1)),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 80 : 28,
        vertical: 56,
      ),
      child: isWide ? _FooterWide() : _FooterMobile(),
    );
  }
}

class _FooterWide extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Brand column
            Expanded(flex: 2, child: _FooterBrand()),
            const SizedBox(width: 60),
            // Links columns
            Expanded(child: _FooterLinks(
              title: 'Platform',
              links: ['Home', 'Browse Vendors', 'Post an Event', 'How It Works', 'Pricing'],
            )),
            const SizedBox(width: 40),
            Expanded(child: _FooterLinks(
              title: 'Company',
              links: ['About Utsob', 'Blog', 'Careers', 'Press', 'Contact Us'],
            )),
            const SizedBox(width: 40),
            Expanded(child: _FooterLinks(
              title: 'Support',
              links: ['Help Center', 'Privacy Policy', 'Terms of Service', 'Refund Policy', 'Safety'],
            )),
          ],
        ),
        const SizedBox(height: 48),
        _FooterBottom(),
      ],
    );
  }
}

class _FooterMobile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FooterBrand(),
        const SizedBox(height: 36),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _FooterLinks(
              title: 'Platform',
              links: ['Home', 'Browse Vendors', 'Post an Event', 'How It Works'],
            )),
            const SizedBox(width: 20),
            Expanded(child: _FooterLinks(
              title: 'Support',
              links: ['Help Center', 'Privacy Policy', 'Terms', 'Contact Us'],
            )),
          ],
        ),
        const SizedBox(height: 36),
        _FooterBottom(),
      ],
    );
  }
}

class _FooterBrand extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo row
        Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.gold, AppColors.crimson],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [BoxShadow(
                color: AppColors.crimson.withOpacity(0.35),
                blurRadius: 14, offset: const Offset(0, 4),
              )],
            ),
            child: const Center(
              child: Text('উ', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('Utsob', style: AppTextStyles.headingLarge.copyWith(color: Colors.white, fontSize: 20)),
            Text('উৎসব', style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          ]),
        ]),
        const SizedBox(height: 16),
        Text(
          "Bangladesh's reverse-bidding wedding\nmarketplace. Connect, compare & celebrate.",
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white.withOpacity(0.55), height: 1.6),
        ),
        const SizedBox(height: 20),
        // Social pills
        Wrap(spacing: 10, runSpacing: 10, children: [
          _SocialPill('📘 Facebook',  'https://facebook.com/utsobbd'),
          _SocialPill('📸 Instagram', 'https://instagram.com/utsobbd'),
          _SocialPill('🎵 TikTok',    'https://tiktok.com/@utsobbd'),
        ]),
        const SizedBox(height: 20),
        // Contact info
        _ContactRow(Icons.email_outlined, 'hello@utsob.com.bd'),
        const SizedBox(height: 6),
        _ContactRow(Icons.phone_outlined, '+880 1700-000000'),
        const SizedBox(height: 6),
        _ContactRow(Icons.location_on_outlined, 'Dhaka, Bangladesh'),
      ],
    );
  }
}

class _SocialPill extends StatefulWidget {
  final String label;
  final String url;
  const _SocialPill(this.label, this.url);
  @override
  State<_SocialPill> createState() => _SocialPillState();
}

class _SocialPillState extends State<_SocialPill> {
  bool _hovered = false;

  Future<void> _launch() async {
    final uri = Uri.parse(widget.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: _launch,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: _hovered
                ? Colors.white.withOpacity(0.15)
                : Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hovered
                  ? AppColors.gold.withOpacity(0.55)
                  : Colors.white.withOpacity(0.12),
            ),
            boxShadow: _hovered
                ? [BoxShadow(color: AppColors.gold.withOpacity(0.2), blurRadius: 10)]
                : [],
          ),
          child: Text(widget.label, style: AppTextStyles.bodySmall.copyWith(
              color: _hovered ? Colors.white : Colors.white.withOpacity(0.75),
              fontSize: 11)),
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ContactRow(this.icon, this.text);
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: AppColors.gold.withOpacity(0.70)),
      const SizedBox(width: 8),
      Text(text, style: AppTextStyles.bodySmall.copyWith(
          color: Colors.white.withOpacity(0.60), fontSize: 12)),
    ]);
  }
}

class _FooterLinks extends StatelessWidget {
  final String title;
  final List<String> links;
  const _FooterLinks({required this.title, required this.links});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.headingSmall.copyWith(
            color: Colors.white, fontSize: 13, letterSpacing: 0.5)),
        const SizedBox(height: 14),
        ...links.map((l) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(l, style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.50), fontSize: 12)),
        )),
      ],
    );
  }
}

class _FooterBottom extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Divider(color: Colors.white.withOpacity(0.10), height: 1),
      const SizedBox(height: 20),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '© ${DateTime.now().year} Utsob (উৎসব). All rights reserved.',
            style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white.withOpacity(0.35), fontSize: 11),
          ),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('Made in Bangladesh 🇧🇩',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.gold.withOpacity(0.80), fontSize: 10)),
            ),
          ]),
        ],
      ),
    ]);
  }
}

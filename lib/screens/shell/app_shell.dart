import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../screens/public/landing_home_screen.dart';
import '../../screens/public/public_vendor_page.dart';
import '../../screens/chat/chat_list_screen.dart';
import '../../screens/booking/my_bookings_screen.dart';
import '../../screens/shared/profile_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';

/// Single adaptive shell for ALL users — guests and every logged-in role.
///
/// Guest   →  Home | Vendors | [Login pill]
/// LoggedIn →  Home | Vendors | Chat | Bookings | Profile
///
/// Expose [AppShell.of(context)?.refresh()] to update after login.
/// Expose [AppShell.of(context)?.logout()]  to update after logout.
class AppShell extends StatefulWidget {
  final AppUser? initialUser;
  const AppShell({super.key, this.initialUser});

  static _AppShellState? of(BuildContext context) =>
      context.findAncestorStateOfType<_AppShellState>();

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  AppUser? _user;
  String? _vendorCategory; // category filter passed through from home page

  @override
  void initState() {
    super.initState();
    _user = widget.initialUser ?? AuthService.currentUser;
  }

  // ── Public API ─────────────────────────────────────────────────────────────
  void refresh() => setState(() {
        _user = AuthService.currentUser;
        _index = _index.clamp(0, _screens.length - 1);
      });

  void logout() => setState(() {
        _user = null;
        _index = 0;
        _vendorCategory = null;
      });

  /// Switch to any tab by index (clamps to valid range)
  void goToTab(int idx) => setState(() => _index = idx.clamp(0, _screens.length - 1));

  /// Switch to Vendors tab (not available for vendor role)
  void goToVendors() {
    if (!_isVendor) setState(() => _index = 1);
  }

  /// Switch to Vendors tab AND pre-select a category filter
  void goToVendorsWithCategory(String category) {
    if (_isVendor) return;
    setState(() {
      _vendorCategory = category;
      _index = 1;
    });
  }

  bool get _loggedIn => _user != null;
  bool get _isVendor => _user?.role == UserRole.vendor;

  // Dynamic tab indices — vendor has no Vendors tab so indices shift
  int get _chatIdx    => _isVendor ? 1 : 2;
  int get _bookingsIdx => _isVendor ? 2 : 3;
  int get _profileIdx  => _isVendor ? 3 : 4;

  // ── Screen list ────────────────────────────────────────────────────────────
  List<Widget> get _screens {
    final home = LandingHomeScreen(onNavigateToVendors: goToVendors);
    // Use a ValueKey so the vendor page fully rebuilds when the category changes
    final vendorPage = PublicVendorPage(
      key: ValueKey(_vendorCategory ?? 'all'),
      initialCategory: _vendorCategory,
    );

    if (!_loggedIn) return [home, vendorPage];

    if (_isVendor) {
      // Vendor role: no Vendors marketplace tab
      return [home, const ChatListScreen(), const MyBookingsScreen(), ProfileScreen(user: _user)];
    }

    // Host / all other roles
    return [home, vendorPage, const ChatListScreen(), const MyBookingsScreen(), ProfileScreen(user: _user)];
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 720;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isWide ? _buildWebBar(context) : null,
      bottomNavigationBar: isWide ? null : _buildMobileNav(context),
      extendBody: !isWide,
      body: IndexedStack(
        index: _index.clamp(0, _screens.length - 1),
        children: _screens,
      ),
    );
  }

  // ── Web top bar ─────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildWebBar(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final hPad = w > 1400 ? 120.0 : w > 1100 ? 80.0 : w > 800 ? 56.0 : 32.0;
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              // Glossy effect: white shimmer layer over cream background
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.88),
                  AppColors.background.withOpacity(0.92),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.gold.withOpacity(0.15),
                  width: 1.2,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.60),
                  blurRadius: 0,
                  offset: const Offset(0, 1),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 24, offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(horizontal: hPad),
            child: SafeArea(
              child: Row(
                children: [
                  // Logo — tapping takes you home
                  GestureDetector(
                    onTap: () => setState(() => _index = 0),
                    child: _WebLogo(),
                  ),
                  const Spacer(),
                  // Home tab
                  _WebNavItem(
                    label: 'Home', icon: Icons.home_rounded,
                    selected: _index == 0,
                    onTap: () => setState(() => _index = 0),
                  ),
                  // Vendors tab — hidden for vendor role
                  if (!_isVendor) ...[
                    const SizedBox(width: 6),
                    _WebNavItem(
                      label: 'Vendors', icon: Icons.storefront_rounded,
                      selected: _index == 1,
                      onTap: () => setState(() => _index = 1),
                    ),
                  ],
                  if (_loggedIn) ...[
                    const SizedBox(width: 6),
                    _WebNavItem(
                      label: 'Chat', icon: Icons.chat_bubble_rounded,
                      selected: _index == _chatIdx,
                      onTap: () => setState(() => _index = _chatIdx),
                    ),
                    const SizedBox(width: 6),
                    _WebNavItem(
                      label: 'Bookings', icon: Icons.calendar_month_rounded,
                      selected: _index == _bookingsIdx,
                      onTap: () => setState(() => _index = _bookingsIdx),
                    ),
                    const SizedBox(width: 6),
                    _WebNavItem(
                      label: 'Profile', icon: Icons.person_rounded,
                      selected: _index == _profileIdx,
                      onTap: () => setState(() => _index = _profileIdx),
                    ),
                  ] else ...[
                    const SizedBox(width: 36),
                    _WebNavItem(
                      label: 'Log In',
                      icon: Icons.login_rounded,
                      selected: false,
                      onTap: () => _doLogin(context),
                    ),
                    const SizedBox(width: 16),
                    _GradientPill(
                      label: 'Sign Up Free',
                      onTap: () => _doSignup(context),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Mobile bottom nav ───────────────────────────────────────────────────────
  Widget _buildMobileNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20, offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: AppColors.background.withOpacity(0.90),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                child: _loggedIn
                    ? _LoggedInNav(
                        index: _index,
                        isVendor: _isVendor,
                        onTap: (i) => setState(() => _index = i),
                      )
                    : _GuestNav(
                        index: _index,
                        onHomeTap: () => setState(() => _index = 0),
                        onVendorsTap: () => setState(() => _index = 1),
                        onLoginTap: () => _doLogin(context),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Auth helpers ────────────────────────────────────────────────────────────
  Future<void> _doLogin(BuildContext context) async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, a, __, c) =>
            FadeTransition(opacity: a, child: c),
      ),
    );
    if (AuthService.currentUser != null) refresh();
  }

  Future<void> _doSignup(BuildContext context) async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const SignupScreen(),
        transitionsBuilder: (_, a, __, c) =>
            FadeTransition(opacity: a, child: c),
      ),
    );
    if (AuthService.currentUser != null) refresh();
  }
}

// ── Guest bottom nav ──────────────────────────────────────────────────────────
class _GuestNav extends StatelessWidget {
  final int index;
  final VoidCallback onHomeTap, onVendorsTap, onLoginTap;
  const _GuestNav({
    required this.index, required this.onHomeTap,
    required this.onVendorsTap, required this.onLoginTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _MobileNavItem(
          icon: Icons.home_rounded, label: 'Home',
          selected: index == 0, onTap: onHomeTap,
        ),
        _MobileNavItem(
          icon: Icons.storefront_rounded, label: 'Vendors',
          selected: index == 1, onTap: onVendorsTap,
        ),
        _GradientPill(label: 'Log In', onTap: onLoginTap, compact: true),
      ],
    );
  }
}

// ── Logged-in bottom nav ──────────────────────────────────────────────────────
class _LoggedInNav extends StatelessWidget {
  final int index;
  final bool isVendor;
  final ValueChanged<int> onTap;
  const _LoggedInNav({required this.index, required this.isVendor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Vendor: Home | Chat | Bookings | Profile  (no Vendors tab)
    // Host:   Home | Vendors | Chat | Bookings | Profile
    final items = isVendor
        ? [
            (Icons.home_rounded, 'Home'),
            (Icons.chat_bubble_rounded, 'Chat'),
            (Icons.calendar_month_rounded, 'Bookings'),
            (Icons.person_rounded, 'Profile'),
          ]
        : [
            (Icons.home_rounded, 'Home'),
            (Icons.storefront_rounded, 'Vendors'),
            (Icons.chat_bubble_rounded, 'Chat'),
            (Icons.calendar_month_rounded, 'Bookings'),
            (Icons.person_rounded, 'Profile'),
          ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: items.asMap().entries.map((e) => _MobileNavItem(
        icon: e.value.$1,
        label: e.value.$2,
        selected: index == e.key,
        onTap: () => onTap(e.key),
      )).toList(),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────
class _WebLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.gold, AppColors.crimson],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(
            color: AppColors.crimson.withOpacity(0.28),
            blurRadius: 12, offset: const Offset(0, 4),
          )],
        ),
        child: const Center(
          child: Text('উ', style: TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
        ),
      ),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text('Utsob', style: AppTextStyles.headingLarge.copyWith(
            fontSize: 18, color: AppColors.charcoal, letterSpacing: -0.3)),
        Text('উৎসব', style: AppTextStyles.bodySmall.copyWith(
            fontSize: 10, color: AppColors.gold,
            fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      ]),
    ]);
  }
}

class _WebNavItem extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _WebNavItem({
    required this.label, required this.icon,
    required this.selected, required this.onTap,
  });
  @override
  State<_WebNavItem> createState() => _WebNavItemState();
}

class _WebNavItemState extends State<_WebNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.selected;
    final highlight = active || _hovered;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: active
                ? AppColors.crimson.withOpacity(0.09)
                : _hovered
                    ? AppColors.charcoal.withOpacity(0.04)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            boxShadow: active
                ? [BoxShadow(
                    color: AppColors.crimson.withOpacity(0.18),
                    blurRadius: 16, offset: const Offset(0, 2),
                  )]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    widget.icon, size: 16, key: ValueKey(highlight),
                    color: active
                        ? AppColors.crimson
                        : _hovered
                            ? AppColors.charcoal
                            : AppColors.charcoalLight,
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  style: AppTextStyles.headingSmall.copyWith(
                    fontSize: 14,
                    color: active
                        ? AppColors.crimson
                        : _hovered
                            ? AppColors.charcoal
                            : AppColors.charcoalLight,
                    fontWeight: active
                        ? FontWeight.w700
                        : _hovered
                            ? FontWeight.w600
                            : FontWeight.w500,
                  ),
                  child: Text(widget.label),
                ),
              ]),
              const SizedBox(height: 4),
              // Glowing underline indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                height: 2,
                width: active ? 22 : 0,
                decoration: BoxDecoration(
                  gradient: active
                      ? const LinearGradient(
                          colors: [AppColors.crimson, AppColors.gold])
                      : null,
                  borderRadius: BorderRadius.circular(1),
                  boxShadow: active
                      ? [BoxShadow(
                          color: AppColors.crimson.withOpacity(0.55),
                          blurRadius: 8,
                        )]
                      : [],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _MobileNavItem({
    required this.icon, required this.label,
    required this.selected, required this.onTap,
  });
  @override
  State<_MobileNavItem> createState() => _MobileNavItemState();
}

class _MobileNavItemState extends State<_MobileNavItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _springCtrl;
  late final Animation<double> _springAnim;

  @override
  void initState() {
    super.initState();
    _springCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _springAnim = CurvedAnimation(
        parent: _springCtrl, curve: Curves.elasticOut);
    if (widget.selected) _springCtrl.value = 1;
  }

  @override
  void didUpdateWidget(_MobileNavItem old) {
    super.didUpdateWidget(old);
    if (widget.selected && !old.selected) {
      _springCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _springCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _springAnim,
        builder: (_, __) {
          final scale = widget.selected
              ? (1.0 + 0.12 * math.sin(_springAnim.value * math.pi))
              : 1.0;
          return Transform.scale(
            scale: scale,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: widget.selected
                      ? AppColors.crimson.withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: widget.selected
                      ? [BoxShadow(
                          color: AppColors.crimson.withOpacity(0.22),
                          blurRadius: 12, offset: const Offset(0, 2),
                        )]
                      : [],
                ),
                child: Icon(widget.icon, size: 22,
                    color: widget.selected
                        ? AppColors.crimson
                        : AppColors.charcoalLight),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w400,
                  color: widget.selected ? AppColors.crimson : AppColors.charcoalLight,
                ),
                child: Text(widget.label),
              ),
              const SizedBox(height: 3),
              // Animated glow dot
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: widget.selected ? 5 : 0,
                height: widget.selected ? 5 : 0,
                decoration: BoxDecoration(
                  color: AppColors.crimson,
                  shape: BoxShape.circle,
                  boxShadow: widget.selected
                      ? [BoxShadow(
                          color: AppColors.crimson.withOpacity(0.65),
                          blurRadius: 8,
                        )]
                      : [],
                ),
              ),
            ]),
          );
        },
      ),
    );
  }
}

class _GradientPill extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool compact;
  const _GradientPill({
    required this.label, required this.onTap, this.compact = false});
  @override
  State<_GradientPill> createState() => _GradientPillState();
}

class _GradientPillState extends State<_GradientPill>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  bool _hovered = false;
  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
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
          scale: _pressed ? 0.93 : _hovered ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 140),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 18 : 22,
              vertical: widget.compact ? 10 : 11,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.crimson, Color(0xFF950025)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(
                color: AppColors.crimson.withOpacity(_hovered ? 0.55 : 0.35),
                blurRadius: _hovered ? 22 : 14,
                offset: Offset(0, _hovered ? 6 : 4),
              )],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Content
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    if (widget.compact) ...[
                      const Icon(Icons.person_rounded, color: Colors.white, size: 15),
                      const SizedBox(width: 6),
                    ],
                    Text(widget.label, style: AppTextStyles.headingSmall.copyWith(
                        fontSize: 13, color: Colors.white)),
                  ]),
                  // Shimmer sweep overlay
                  AnimatedBuilder(
                    animation: _shimmerCtrl,
                    builder: (_, __) {
                      return Positioned.fill(
                        child: FractionalTranslation(
                          translation: Offset(_shimmerCtrl.value * 3 - 1, 0),
                          child: Container(
                            width: 30,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0),
                                  Colors.white.withOpacity(0.22),
                                  Colors.white.withOpacity(0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
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

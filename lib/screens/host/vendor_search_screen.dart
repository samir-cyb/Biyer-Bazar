import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/app_strings.dart';
import '../../models/vendor_package_model.dart';
import '../../services/booking_service.dart';
import '../../widgets/glass_card.dart';
import 'vendor_detail_screen.dart';

class VendorSearchScreen extends StatefulWidget {
  final int? initialBudget;
  const VendorSearchScreen({super.key, this.initialBudget});

  @override
  State<VendorSearchScreen> createState() => _VendorSearchScreenState();
}

class _VendorSearchScreenState extends State<VendorSearchScreen> {
  final _searchCtrl = TextEditingController();
  String _selectedCategory = 'All';
  String _sortBy = 'rating';
  int? _maxBudget;
  bool _loading = false;
  List<RichVendorProfile> _vendors = [];

  static const _categories = [
    'All', 'Venue', 'Catering', 'Photography', 'Decor', 'Makeup', 'Attire', 'Logistics',
  ];

  static const _categoryEmojis = {
    'All': '🔍',
    'Venue': '🏛️',
    'Catering': '🍽️',
    'Photography': '📸',
    'Decor': '✨',
    'Makeup': '💄',
    'Attire': '💍',
    'Logistics': '🚐',
  };

  // ilike wildcard patterns — must match what vendors save from ServiceCategories.all
  static const _categoryDbPatterns = <String, String>{
    'Venue':       '%Venue%',
    'Catering':    '%Catering%',
    'Photography': '%Photo%',   // Photography & Video, Drone Photography, Videography
    'Decor':       '%Decor%',
    'Makeup':      '%Makeup%',
    'Attire':      '%Attire%',
    'Logistics':   '%Logistics%',
  };

  @override
  void initState() {
    super.initState();
    _maxBudget = widget.initialBudget;
    _search();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() => _loading = true);
    final pattern = _selectedCategory == 'All'
        ? null
        : _categoryDbPatterns[_selectedCategory]; // e.g. '%Photo%'
    final results = await VendorPackageService.searchVendors(
      category: pattern,
      maxBudget: _maxBudget,
      sortBy: _sortBy,
    );
    if (mounted) setState(() { _vendors = results; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090F),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _DarkBudgetFilter(
                  initialBudget: _maxBudget,
                  onBudgetChanged: (b) {
                    setState(() => _maxBudget = b);
                    _search();
                  },
                ),
                const SizedBox(height: 14),
                _DarkCategoryRow(
                  categories: _categories,
                  emojis: _categoryEmojis,
                  selected: _selectedCategory,
                  onSelect: (c) {
                    setState(() => _selectedCategory = c);
                    _search();
                  },
                ),
                const SizedBox(height: 14),
                _DarkSortBar(
                  selected: _sortBy,
                  onSelect: (s) {
                    setState(() => _sortBy = s);
                    _search();
                  },
                ),
                const SizedBox(height: 18),
                if (_loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: AppColors.crimson, strokeWidth: 2),
                    ),
                  )
                else if (_vendors.isEmpty)
                  _EmptyState(category: _selectedCategory)
                else ...[
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.crimson.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.crimson.withOpacity(0.3)),
                      ),
                      child: Text(
                        '${_vendors.length} vendor${_vendors.length == 1 ? '' : 's'} found',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.crimson, fontWeight: FontWeight.w700, fontSize: 11),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  ..._vendors.asMap().entries.map((e) => _VendorCard(
                    vendor: e.value,
                    index: e.key,
                    onTap: () => Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) =>
                            VendorDetailScreen(vendor: e.value),
                        transitionsBuilder: (_, a, __, c) =>
                            FadeTransition(opacity: a, child: c),
                      ),
                    ),
                  )),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: const Color(0xFF09090F),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70, size: 20),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppStrings.findVendors,
              style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
          if (_maxBudget != null)
            Text(
              'Budget: ৳${_maxBudget! ~/ 1000}k max',
              style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.crimson, fontSize: 10),
            ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: const Icon(Icons.tune_rounded, color: Colors.white70, size: 18),
          ),
        ),
      ],
    );
  }
}

// ── Dark Budget Filter ─────────────────────────────────────────────────────────

class _DarkBudgetFilter extends StatefulWidget {
  final int? initialBudget;
  final ValueChanged<int?> onBudgetChanged;
  const _DarkBudgetFilter({this.initialBudget, required this.onBudgetChanged});

  @override
  State<_DarkBudgetFilter> createState() => _DarkBudgetFilterState();
}

class _DarkBudgetFilterState extends State<_DarkBudgetFilter>
    with SingleTickerProviderStateMixin {
  late double _value;
  late bool _active;
  late final AnimationController _glowCtrl;
  static const _min = 0.0;
  static const _max = 1000000.0;

  @override
  void initState() {
    super.initState();
    _active = widget.initialBudget != null;
    _value = (widget.initialBudget?.toDouble() ?? 500000.0).clamp(_min, _max);
    _glowCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _glowCtrl.dispose(); super.dispose(); }

  String _label(double v) {
    if (v == 0) return '৳0';
    if (v >= 1000000) return '৳10 lakh';
    if (v >= 100000) return '৳${(v / 100000).toStringAsFixed(1)} lakh';
    return '৳${(v ~/ 1000)}k';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, child) {
        final t = _glowCtrl.value;
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF141428),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _active
                  ? AppColors.crimson.withOpacity(0.25 + t * 0.15)
                  : Colors.white.withOpacity(0.07)),
            boxShadow: _active ? [
              BoxShadow(
                color: AppColors.crimson.withOpacity(0.12 + t * 0.06),
                blurRadius: 20, offset: const Offset(0, 6)),
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 16, offset: const Offset(0, 4)),
            ] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 16, offset: const Offset(0, 4)),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.account_balance_wallet_rounded,
                size: 14, color: Colors.white54),
            const SizedBox(width: 7),
            Text(AppStrings.filterByBudget,
                style: AppTextStyles.headingSmall.copyWith(
                    color: Colors.white, fontSize: 13)),
            const Spacer(),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: _active
                    ? AppColors.crimson.withOpacity(0.15)
                    : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _active
                      ? AppColors.crimson.withOpacity(0.4)
                      : Colors.white.withOpacity(0.08)),
              ),
              child: Text(
                _active ? _label(_value) : 'Any budget',
                style: AppTextStyles.bodySmall.copyWith(
                    color: _active ? AppColors.crimson : Colors.white54,
                    fontWeight: FontWeight.w700, fontSize: 11),
              ),
            ),
            if (_active) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() => _active = false);
                  widget.onBudgetChanged(null);
                },
                child: Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Icon(Icons.close_rounded,
                      size: 13, color: Colors.white54),
                ),
              ),
            ],
          ]),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: _active ? AppColors.crimson : Colors.white24,
              inactiveTrackColor: Colors.white.withOpacity(0.08),
              thumbColor: _active ? AppColors.crimson : Colors.white38,
              overlayColor: AppColors.crimson.withOpacity(0.15),
              trackHeight: 3.5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: _value,
              min: _min,
              max: _max,
              divisions: 100,
              onChanged: (v) => setState(() {
                _value = v;
                _active = true;
              }),
              onChangeEnd: (v) => widget.onBudgetChanged(_active ? v.toInt() : null),
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('৳0', style: TextStyle(fontSize: 9, color: Colors.white38)),
            Text('৳10 lakh', style: TextStyle(fontSize: 9, color: Colors.white38)),
          ]),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.06, end: 0);
  }
}

// ── Dark Category Row ──────────────────────────────────────────────────────────

class _DarkCategoryRow extends StatelessWidget {
  final List<String> categories;
  final Map<String, String> emojis;
  final String selected;
  final ValueChanged<String> onSelect;
  const _DarkCategoryRow({
    required this.categories, required this.emojis,
    required this.selected, required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = categories[i];
          final sel = cat == selected;
          final emoji = emojis[cat] ?? '📦';
          return GestureDetector(
            onTap: () => onSelect(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: sel
                    ? const LinearGradient(
                        colors: [AppColors.crimson, Color(0xFF950025)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight)
                    : null,
                color: sel ? null : Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: sel
                      ? AppColors.crimson.withOpacity(0.6)
                      : Colors.white.withOpacity(0.10),
                  width: sel ? 1.5 : 1.0),
                boxShadow: sel ? [
                  BoxShadow(
                    color: AppColors.crimson.withOpacity(0.40),
                    blurRadius: 14, spreadRadius: -2, offset: const Offset(0, 4)),
                ] : [],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(emoji, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 6),
                Text(
                  cat == 'All' ? AppStrings.all : cat,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: sel ? Colors.white : Colors.white60,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ]),
            ),
          )
              .animate(delay: Duration(milliseconds: i * 40))
              .fadeIn(duration: 280.ms)
              .slideX(begin: 0.08, end: 0);
        },
      ),
    );
  }
}

// ── Dark Sort Bar ──────────────────────────────────────────────────────────────

class _DarkSortBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const _DarkSortBar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final options = [
      ('rating', '⭐', 'Rating'),
      ('price_asc', '↑', 'Low–High'),
      ('price_desc', '↓', 'High–Low'),
      ('experience', '🏅', 'Exp'),
    ];
    return Row(
      children: [
        const Text('Sort  ',
            style: TextStyle(fontSize: 11, color: Colors.white38,
                fontWeight: FontWeight.w500)),
        ...options.map((opt) {
          final sel = opt.$1 == selected;
          return GestureDetector(
            onTap: () => onSelect(opt.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: sel
                    ? AppColors.gold.withOpacity(0.15)
                    : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: sel
                      ? AppColors.gold.withOpacity(0.5)
                      : Colors.white.withOpacity(0.08)),
                boxShadow: sel ? [
                  BoxShadow(
                    color: AppColors.gold.withOpacity(0.20),
                    blurRadius: 8, offset: const Offset(0, 3)),
                ] : [],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(opt.$2,
                    style: TextStyle(fontSize: sel ? 11 : 10)),
                const SizedBox(width: 4),
                Text(opt.$3,
                    style: TextStyle(
                      fontSize: 11,
                      color: sel ? AppColors.gold : Colors.white38,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                    )),
              ]),
            ),
          );
        }),
      ],
    );
  }
}

// ── 3D Vendor Card ─────────────────────────────────────────────────────────────

class _VendorCard extends StatefulWidget {
  final RichVendorProfile vendor;
  final int index;
  final VoidCallback onTap;
  const _VendorCard({required this.vendor, required this.index, required this.onTap});
  @override
  State<_VendorCard> createState() => _VendorCardState();
}

class _VendorCardState extends State<_VendorCard>
    with SingleTickerProviderStateMixin {
  double _rotX = 0, _rotY = 0;
  late final AnimationController _liq;

  // Category → pair of rich dark gradient colors
  static Color _c1(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('photo') || c.contains('video') || c.contains('drone')) return const Color(0xFF0A1535);
    if (c.contains('cater') || c.contains('food') || c.contains('cake'))   return const Color(0xFF2A0800);
    if (c.contains('venue') || c.contains('hall') || c.contains('stage'))  return const Color(0xFF061A10);
    if (c.contains('decor') || c.contains('light') || c.contains('flower'))return const Color(0xFF1A0528);
    if (c.contains('makeup') || c.contains('mehendi') || c.contains('beauty')) return const Color(0xFF28031A);
    if (c.contains('attire') || c.contains('jewel') || c.contains('bridal')) return const Color(0xFF1C0D00);
    return const Color(0xFF0E0720);
  }

  static Color _c2(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('photo') || c.contains('video') || c.contains('drone')) return const Color(0xFF1A3D8F);
    if (c.contains('cater') || c.contains('food') || c.contains('cake'))   return const Color(0xFF8C2200);
    if (c.contains('venue') || c.contains('hall') || c.contains('stage'))  return const Color(0xFF0E4D25);
    if (c.contains('decor') || c.contains('light') || c.contains('flower'))return const Color(0xFF5C1A85);
    if (c.contains('makeup') || c.contains('mehendi') || c.contains('beauty')) return const Color(0xFF8C1560);
    if (c.contains('attire') || c.contains('jewel') || c.contains('bridal')) return const Color(0xFF7A3A00);
    return const Color(0xFF3D1575);
  }

  @override
  void initState() {
    super.initState();
    _liq = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() { _liq.dispose(); super.dispose(); }

  void _onPan(DragUpdateDetails d, BoxConstraints box) => setState(() {
    _rotY = ((d.localPosition.dx / box.maxWidth) - 0.5) * 0.20;
    _rotX = -((d.localPosition.dy / 200) - 0.5) * 0.13;
  });

  void _reset() => setState(() { _rotX = 0; _rotY = 0; });

  @override
  Widget build(BuildContext context) {
    final v = widget.vendor;
    final hasDiscount = v.discounts.any((d) => d.isActive && !d.isExpired);
    final avatarUrl = v.coverPhotoUrl ??
        (v.portfolioUrls.isNotEmpty ? v.portfolioUrls.first : null);
    final c1 = _c1(v.category);
    final c2 = _c2(v.category);

    return LayoutBuilder(builder: (_, box) {
      return GestureDetector(
        onTap: widget.onTap,
        onPanUpdate: (d) => _onPan(d, box),
        onPanEnd: (_) => _reset(),
        child: AnimatedContainer(
          duration: _rotX == 0
              ? const Duration(milliseconds: 480)
              : const Duration(milliseconds: 55),
          curve: _rotX == 0 ? Curves.elasticOut : Curves.linear,
          margin: const EdgeInsets.only(bottom: 22),
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(_rotX)
            ..rotateY(_rotY),
          transformAlignment: Alignment.center,
          child: AnimatedBuilder(
            animation: _liq,
            builder: (_, __) {
              final t = _liq.value; // 0.0 → 1.0 → 0.0 (reverse)
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  // Animated liquid gradient: alignment shifts like a slow tide
                  gradient: LinearGradient(
                    begin: Alignment(-1.0 + t * 0.8, -1.0 + t * 0.4),
                    end:   Alignment( 0.8 + t * 0.4,  1.0 - t * 0.3),
                    colors: [c1, c2, Color.lerp(c1, c2, 0.6)!],
                    stops:  [0.0, 0.5 + t * 0.25, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: c2.withOpacity(0.35 + t * 0.15),
                      blurRadius: 28 + t * 10, spreadRadius: -4,
                      offset: const Offset(0, 10)),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.22),
                      blurRadius: 18, offset: const Offset(0, 6)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      // ── Floating liquid orb 1 (top-right) ─────────────
                      Positioned(
                        top: -40 + t * 30,
                        right: -30 + t * 25,
                        child: _LiquidOrb(size: 160, color: c2, opacity: 0.28 + t * 0.12),
                      ),
                      // ── Floating liquid orb 2 (bottom-left) ───────────
                      Positioned(
                        bottom: -30 + t * 20,
                        left: 10 + t * 35,
                        child: _LiquidOrb(size: 100, color: c1, opacity: 0.22 + t * 0.08),
                      ),
                      // ── Subtle shimmer line ────────────────────────────
                      Positioned(
                        top: 30 + t * 80,
                        left: -60 + t * 400,
                        child: Transform.rotate(
                          angle: -0.35,
                          child: Container(
                            width: 120, height: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                Colors.transparent,
                                Colors.white.withOpacity(0.10),
                                Colors.transparent,
                              ]),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      // ── Content ────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ── Avatar + Name + Rating row ────────────────
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 3D floating avatar — counter-tilts vs card
                                Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()
                                    ..setEntry(3, 2, 0.001)
                                    ..rotateX(-_rotX * 1.4)
                                    ..rotateY(-_rotY * 1.4)
                                    ..translate(
                                      _rotY * 6.0,
                                      _rotX * -6.0,
                                      8.0 + t * 4, // slight Z float
                                    ),
                                  child: _VendorAvatar(
                                    imageUrl: avatarUrl,
                                    name: v.businessName,
                                    accentColor: c2,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                // Name + badges
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 2),
                                      Text(v.businessName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            height: 1.25,
                                            letterSpacing: 0.1,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 7),
                                      Wrap(spacing: 5, runSpacing: 4, children: [
                                        _CategoryBadge(v.category),
                                        if (v.isVerified) _VerifiedBadge(),
                                        if (hasDiscount)
                                          _DiscountBadge(v.discounts.first.displayValue),
                                      ]),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _RatingBadge(v.rating, v.totalReviews),
                              ],
                            ),

                            const SizedBox(height: 14),
                            // ── Divider ───────────────────────────────────
                            Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  Colors.white.withOpacity(0.0),
                                  Colors.white.withOpacity(0.18),
                                  Colors.white.withOpacity(0.0),
                                ]),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // ── Meta row ──────────────────────────────────
                            Row(children: [
                              if (v.location != null) ...[
                                const Icon(Icons.location_on_rounded,
                                    size: 12, color: Colors.white70),
                                const SizedBox(width: 3),
                                Flexible(child: Text(v.location!,
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 11),
                                    overflow: TextOverflow.ellipsis)),
                                const SizedBox(width: 10),
                              ],
                              const Icon(Icons.shopping_bag_rounded,
                                  size: 12, color: Colors.white70),
                              const SizedBox(width: 3),
                              Text('${v.totalBookings} bookings',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 11)),
                              if (v.yearsExperience > 0) ...[
                                const SizedBox(width: 10),
                                const Icon(Icons.workspace_premium_rounded,
                                    size: 12, color: Colors.white70),
                                const SizedBox(width: 3),
                                Text('${v.yearsExperience}y exp',
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 11)),
                              ],
                            ]),

                            const SizedBox(height: 12),
                            // ── Price + CTA ───────────────────────────────
                            Row(children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Price Range',
                                        style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.white.withOpacity(0.5),
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.5)),
                                    const SizedBox(height: 2),
                                    Text(v.priceRangeDisplay,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.2)),
                                  ],
                                ),
                              ),
                              // Glowing CTA — uses category accent color
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(22),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      c2.withOpacity(0.95),
                                      Color.lerp(c2, Colors.white, 0.15)!,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: c2.withOpacity(0.55 + t * 0.15),
                                      blurRadius: 18 + t * 6,
                                      offset: const Offset(0, 4),
                                      spreadRadius: -2),
                                  ],
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.2), width: 1),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: widget.onTap,
                                    borderRadius: BorderRadius.circular(22),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 18, vertical: 10),
                                      child: Text('View Profile',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.3)),
                                    ),
                                  ),
                                ),
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      )
          .animate(delay: Duration(milliseconds: widget.index * 90))
          .fadeIn(duration: 500.ms, curve: Curves.easeOut)
          .slideY(begin: 0.14, end: 0, duration: 500.ms, curve: Curves.easeOutCubic)
          .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1),
              duration: 500.ms, curve: Curves.easeOutCubic);
    });
  }
}

// ── Liquid orb helper ──────────────────────────────────────────────────────────
class _LiquidOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;
  const _LiquidOrb({required this.size, required this.color, required this.opacity});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [color.withOpacity(opacity), Colors.transparent],
        stops: const [0.0, 1.0],
      ),
    ),
  );
}

// ── Vendor Avatar ──────────────────────────────────────────────────────────────
class _VendorAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final Color accentColor;
  const _VendorAvatar({this.imageUrl, required this.name, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty ? '?'
        : name.trim().split(RegExp(r'\s+')).take(2)
            .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
            .join();

    return Container(
      width: 60, height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Gradient ring that matches the card accent
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.45),
            accentColor.withOpacity(0.6),
          ],
        ),
        boxShadow: [
          // Main glow
          BoxShadow(
            color: accentColor.withOpacity(0.65),
            blurRadius: 22, spreadRadius: -2, offset: const Offset(0, 8)),
          // Deep shadow for 3D lift
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 14, offset: const Offset(0, 5)),
          // Top rim highlight
          BoxShadow(
            color: Colors.white.withOpacity(0.12),
            blurRadius: 0, spreadRadius: 1, offset: const Offset(-1, -1)),
        ],
      ),
      padding: const EdgeInsets.all(2.5), // gap between gradient ring + inner circle
      child: ClipOval(
        child: imageUrl != null
            ? Image.network(imageUrl!, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _Initials(initials, accentColor))
            : _Initials(initials, accentColor),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  final String text;
  final Color accent;
  const _Initials(this.text, this.accent);
  @override
  Widget build(BuildContext context) => Container(
    color: accent.withOpacity(0.25),
    child: Center(
      child: Text(text,
          style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              shadows: [Shadow(color: accent, blurRadius: 10)])),
    ),
  );
}

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge(this.category);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.gold.withOpacity(0.12),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(category,
        style: AppTextStyles.bodySmall.copyWith(
            fontSize: 10, color: AppColors.gold, fontWeight: FontWeight.w600)),
  );
}

class _VerifiedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.freshTalent.withOpacity(0.12),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.verified_rounded, size: 10, color: AppColors.freshTalent),
      const SizedBox(width: 3),
      Text('Verified',
          style: AppTextStyles.bodySmall.copyWith(
              fontSize: 10, color: AppColors.freshTalent, fontWeight: FontWeight.w600)),
    ]),
  );
}

class _DiscountBadge extends StatelessWidget {
  final String label;
  const _DiscountBadge(this.label);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.error.withOpacity(0.10),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(label,
        style: AppTextStyles.bodySmall.copyWith(
            fontSize: 10, color: AppColors.error, fontWeight: FontWeight.w700)),
  );
}

class _RatingBadge extends StatelessWidget {
  final double rating;
  final int reviews;
  const _RatingBadge(this.rating, this.reviews);

  @override
  Widget build(BuildContext context) {
    final hasRating = reviews > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: hasRating
                ? AppColors.gold.withOpacity(0.12)
                : AppColors.charcoal.withOpacity(0.07),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.star_rounded, size: 13,
                color: hasRating ? AppColors.gold : AppColors.charcoalLight),
            const SizedBox(width: 3),
            Text(
              hasRating ? rating.toStringAsFixed(1) : 'N/A',
              style: AppTextStyles.headingSmall.copyWith(
                  fontSize: 13,
                  color: hasRating ? AppColors.gold : AppColors.charcoalLight),
            ),
          ]),
        ),
        const SizedBox(height: 2),
        Text(hasRating ? '$reviews reviews' : 'No reviews yet',
            style: AppTextStyles.bodySmall.copyWith(fontSize: 9)),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoPill(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.overlayDark,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: AppColors.charcoalLight),
      const SizedBox(width: 4),
      Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
    ]),
  );
}

class _EmptyState extends StatelessWidget {
  final String category;
  const _EmptyState({required this.category});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(30),
    decoration: BoxDecoration(
      color: const Color(0xFF141428),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white.withOpacity(0.07)),
    ),
    child: Column(children: [
      const Text('🔍', style: TextStyle(fontSize: 44)),
      const SizedBox(height: 14),
      Text(AppStrings.noVendorsFound,
          style: AppTextStyles.headingMedium.copyWith(color: Colors.white),
          textAlign: TextAlign.center),
      const SizedBox(height: 6),
      const Text(
        'Try adjusting your budget or selecting a different category.',
        style: TextStyle(color: Colors.white54, fontSize: 13),
        textAlign: TextAlign.center,
      ),
    ]),
  ).animate(delay: 200.ms).fadeIn(duration: 400.ms);
}

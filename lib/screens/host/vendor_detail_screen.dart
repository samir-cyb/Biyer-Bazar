import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/app_strings.dart';
import '../../core/vendor_category_config.dart';
import '../../models/vendor_package_model.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/booking_service.dart';
import '../chat/chat_screen.dart';

class VendorDetailScreen extends StatelessWidget {
  final RichVendorProfile vendor;
  const VendorDetailScreen({super.key, required this.vendor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          _buildHeroAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _PriceLocationCard(vendor: vendor),
                const SizedBox(height: 14),
                if (vendor.bio != null) ...[
                  _BioCard(bio: vendor.bio!),
                  const SizedBox(height: 14),
                ],
                if (vendor.categoryDetails.isNotEmpty) ...[
                  _CategoryDetailsCard(vendor: vendor),
                  const SizedBox(height: 14),
                ],
                if (vendor.packages.isNotEmpty) ...[
                  _SectionHeader(title: AppStrings.myPackages, icon: '📦'),
                  const SizedBox(height: 10),
                  ...vendor.packages.asMap().entries.map((e) =>
                      _PackageCard(package: e.value, index: e.key)),
                  const SizedBox(height: 14),
                ],
                if (vendor.discounts.any((d) => d.isActive && !d.isExpired)) ...[
                  _SectionHeader(title: AppStrings.discountsOffers, icon: '🏷️'),
                  const SizedBox(height: 10),
                  ...vendor.discounts
                      .where((d) => d.isActive && !d.isExpired)
                      .map((d) => _DiscountCard(discount: d)),
                  const SizedBox(height: 14),
                ],
                if (vendor.portfolioUrls.isNotEmpty) ...[
                  _SectionHeader(title: AppStrings.portfolio, icon: '🖼️'),
                  const SizedBox(height: 10),
                  _TappablePortfolioGrid(urls: vendor.portfolioUrls),
                  const SizedBox(height: 14),
                ],
                if (vendor.specialtyTags.isNotEmpty) ...[
                  _SectionHeader(title: AppStrings.specialties, icon: '✨'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 6,
                    children: vendor.specialtyTags.map((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.gold.withOpacity(0.30)),
                      ),
                      child: Text(t, style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 11, color: AppColors.gold,
                          fontWeight: FontWeight.w600)),
                    )).toList(),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _ChatBookingBar(vendor: vendor),
    );
  }

  SliverAppBar _buildHeroAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 340,
      pinned: true,
      backgroundColor: _HeroHeader.catBgColor(vendor.category),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.maybePop(context),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 8, offset: const Offset(0, 2),
              )],
            ),
            child: const Icon(Icons.arrow_back_ios_rounded,
                color: AppColors.charcoal, size: 16),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: _HeroHeader(vendor: vendor),
      ),
    );
  }
}

// ── Light Hero Header ─────────────────────────────────────────────────────────
class _HeroHeader extends StatefulWidget {
  final RichVendorProfile vendor;
  const _HeroHeader({required this.vendor});

  /// Light pastel background tint per category
  static Color catBgColor(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('photo') || c.contains('video') || c.contains('drone'))
      return const Color(0xFFEEF4FF);
    if (c.contains('cater') || c.contains('food') || c.contains('cake'))
      return const Color(0xFFFFF3EC);
    if (c.contains('venue') || c.contains('hall') || c.contains('stage'))
      return const Color(0xFFEDF7F0);
    if (c.contains('decor') || c.contains('light') || c.contains('flower'))
      return const Color(0xFFF7F0FF);
    if (c.contains('makeup') || c.contains('mehendi') || c.contains('beauty'))
      return const Color(0xFFFFF0F6);
    if (c.contains('attire') || c.contains('jewel') || c.contains('bridal'))
      return const Color(0xFFFFF8EC);
    return AppColors.background;
  }

  /// Accent color per category (used for orbs, borders, highlights)
  static Color catAccent(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('photo') || c.contains('video') || c.contains('drone'))
      return const Color(0xFF3B6BDD);
    if (c.contains('cater') || c.contains('food') || c.contains('cake'))
      return AppColors.crimson;
    if (c.contains('venue') || c.contains('hall') || c.contains('stage'))
      return const Color(0xFF2E8B57);
    if (c.contains('decor') || c.contains('light') || c.contains('flower'))
      return const Color(0xFF7B4FBF);
    if (c.contains('makeup') || c.contains('mehendi') || c.contains('beauty'))
      return const Color(0xFFBF3B8A);
    if (c.contains('attire') || c.contains('jewel') || c.contains('bridal'))
      return AppColors.gold;
    return AppColors.crimson;
  }

  @override
  State<_HeroHeader> createState() => _HeroHeaderState();
}

class _HeroHeaderState extends State<_HeroHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 5000))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final v = widget.vendor;
    final bg  = _HeroHeader.catBgColor(v.category);
    final accent = _HeroHeader.catAccent(v.category);
    final imgUrl = v.coverPhotoUrl ??
        (v.portfolioUrls.isNotEmpty ? v.portfolioUrls.first : null);
    final initials = v.businessName.trim().isEmpty
        ? '?'
        : v.businessName.trim().split(RegExp(r'\s+')).take(2)
            .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.0 + t * 0.6, -1.0),
              end: Alignment(0.8 + t * 0.2, 1.0),
              colors: [
                bg,
                Color.lerp(bg, accent.withOpacity(0.12), 0.6 + t * 0.2)!,
                bg,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Animated soft orb 1
              Positioned(
                top: -30 + t * 25, right: -10 + t * 20,
                child: _Orb(size: 200,
                    color: accent, opacity: 0.08 + t * 0.05),
              ),
              // Animated soft orb 2
              Positioned(
                bottom: 30 + t * 20, left: -20 + t * 15,
                child: _Orb(size: 140,
                    color: accent, opacity: 0.06 + t * 0.04),
              ),
              // Gold shimmer orb
              Positioned(
                top: 60 + t * 15, left: 40,
                child: _Orb(size: 80,
                    color: AppColors.gold, opacity: 0.06 + t * 0.03),
              ),
              // Content
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 56, 20, 32),
                  child: Column(
                    children: [
                      // Avatar with glossy ring
                      Container(
                        width: 96, height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.white,
                              accent.withOpacity(0.25 + t * 0.10),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withOpacity(0.22 + t * 0.10),
                              blurRadius: 24 + t * 8, spreadRadius: -2,
                              offset: const Offset(0, 8)),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 12, offset: const Offset(0, 4)),
                          ],
                        ),
                        padding: const EdgeInsets.all(3),
                        child: ClipOval(
                          child: imgUrl != null
                              ? Image.network(imgUrl, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _InitialsBox(initials, accent))
                              : _InitialsBox(initials, accent),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Business name
                      Text(v.businessName,
                          style: AppTextStyles.headingLarge.copyWith(
                            color: AppColors.charcoal,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 10),
                      // Badges
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 6, runSpacing: 4,
                        children: [
                          _HChip(v.category, accent),
                          if (v.isVerified)
                            _HChip('✓ Verified', AppColors.freshTalent),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Stats row — glass pill
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.80),
                                  width: 1.2),
                              boxShadow: [BoxShadow(
                                color: accent.withOpacity(0.08),
                                blurRadius: 12,
                              )],
                            ),
                            child: IntrinsicHeight(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _HStat(
                                    v.totalReviews > 0
                                        ? v.rating.toStringAsFixed(1) : 'N/A',
                                    v.totalReviews > 0
                                        ? '${v.totalReviews} reviews' : 'No reviews',
                                    Icons.star_rounded,
                                    v.totalReviews > 0
                                        ? AppColors.gold : AppColors.charcoalLight,
                                  ),
                                  _VSep(),
                                  _HStat('${v.totalBookings}', 'bookings',
                                      Icons.shopping_bag_rounded,
                                      AppColors.charcoalLight),
                                  if (v.yearsExperience > 0) ...[
                                    _VSep(),
                                    _HStat('${v.yearsExperience}y', 'experience',
                                        Icons.workspace_premium_rounded,
                                        accent),
                                  ],
                                  if (v.capacity != null) ...[
                                    _VSep(),
                                    _HStat('${v.capacity}', AppStrings.capacity,
                                        Icons.people_rounded,
                                        AppColors.charcoalLight),
                                  ],
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
            ],
          ),
        );
      },
    );
  }
}

class _Orb extends StatelessWidget {
  final double size; final Color color; final double opacity;
  const _Orb({required this.size, required this.color, required this.opacity});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [color.withOpacity(opacity), Colors.transparent]),
    ),
  );
}

class _InitialsBox extends StatelessWidget {
  final String text; final Color accent;
  const _InitialsBox(this.text, this.accent);
  @override
  Widget build(BuildContext context) => Container(
    color: accent.withOpacity(0.12),
    child: Center(
      child: Text(text, style: TextStyle(
          color: accent, fontSize: 28, fontWeight: FontWeight.w800)),
    ),
  );
}

class _HChip extends StatelessWidget {
  final String label; final Color color;
  const _HChip(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.35)),
    ),
    child: Text(label, style: TextStyle(
        color: color, fontSize: 11, fontWeight: FontWeight.w700)),
  );
}

class _HStat extends StatelessWidget {
  final String value, label; final IconData icon; final Color color;
  const _HStat(this.value, this.label, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(value, style: AppTextStyles.headingSmall.copyWith(
            fontSize: 15, color: AppColors.charcoal,
            fontWeight: FontWeight.w800)),
      ]),
      const SizedBox(height: 2),
      Text(label, style: AppTextStyles.bodySmall.copyWith(
          fontSize: 9, color: AppColors.charcoalLight)),
    ]),
  );
}

class _VSep extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1, height: 28,
    margin: const EdgeInsets.symmetric(horizontal: 2),
    color: AppColors.charcoal.withOpacity(0.10),
  );
}

// ── Section Header ─────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title, icon;
  const _SectionHeader({required this.title, required this.icon});
  @override
  Widget build(BuildContext context) => Row(children: [
    Text(icon, style: const TextStyle(fontSize: 16)),
    const SizedBox(width: 8),
    Text(title, style: AppTextStyles.headingMedium),
  ]).animate().fadeIn(duration: 300.ms).slideX(begin: -0.04, end: 0);
}

// ── Price + Location Card ──────────────────────────────────────────────────────
class _PriceLocationCard extends StatelessWidget {
  final RichVendorProfile vendor;
  const _PriceLocationCard({required this.vendor});

  @override
  Widget build(BuildContext context) {
    final accent = _HeroHeader.catAccent(vendor.category);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.charcoal.withOpacity(0.07)),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        // Price
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Price Range', style: AppTextStyles.bodySmall.copyWith(
                fontSize: 10, letterSpacing: 0.5,
                color: AppColors.charcoalLight,
                fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(vendor.priceRangeDisplay,
                style: AppTextStyles.currencyMedium.copyWith(
                    color: accent, fontSize: 20)),
          ]),
        ),
        Container(width: 1, height: 40,
            color: AppColors.charcoal.withOpacity(0.08)),
        // Location
        if (vendor.location != null)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Location', style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 10, letterSpacing: 0.5,
                    color: AppColors.charcoalLight,
                    fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.location_on_rounded,
                      size: 13, color: AppColors.crimson),
                  const SizedBox(width: 4),
                  Flexible(child: Text(vendor.location!,
                      style: AppTextStyles.headingSmall.copyWith(fontSize: 13),
                      overflow: TextOverflow.ellipsis)),
                ]),
              ]),
            ),
          ),
      ]),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.06, end: 0);
  }
}

// ── Bio Card ───────────────────────────────────────────────────────────────────
class _BioCard extends StatelessWidget {
  final String bio;
  const _BioCard({required this.bio});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.charcoal.withOpacity(0.07)),
      boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 14, offset: const Offset(0, 3))],
    ),
    child: Text(bio,
        style: AppTextStyles.bodyMedium.copyWith(height: 1.70)),
  ).animate().fadeIn(duration: 350.ms);
}

// ── Category Details Card ──────────────────────────────────────────────────────
class _CategoryDetailsCard extends StatelessWidget {
  final RichVendorProfile vendor;
  const _CategoryDetailsCard({required this.vendor});

  @override
  Widget build(BuildContext context) {
    final config = VendorCategoryConfig.forCategory(vendor.category);
    final details = vendor.categoryDetails;
    if (config == null || details.isEmpty) return const SizedBox.shrink();

    // Build display rows for each field that has a non-empty value
    final rows = <Widget>[];
    for (final field in config.fields) {
      final val = details[field.key];
      if (val == null) continue;

      Widget valueWidget;
      if (field.type == CatFieldType.bool_) {
        final isTrue = val == true;
        valueWidget = Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            isTrue ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 14,
            color: isTrue ? AppColors.freshTalent : AppColors.charcoalLight,
          ),
          const SizedBox(width: 4),
          Text(isTrue ? 'Yes' : 'No',
              style: AppTextStyles.bodySmall.copyWith(
                  color: isTrue ? AppColors.freshTalent : AppColors.charcoalLight,
                  fontWeight: FontWeight.w600)),
        ]);
      } else if (val is List && (val as List).isNotEmpty) {
        valueWidget = Wrap(
          spacing: 6,
          runSpacing: 4,
          children: (val as List<dynamic>).map((item) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.charcoal.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.charcoal.withOpacity(0.10)),
            ),
            child: Text(item.toString(),
                style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
          )).toList(),
        );
      } else {
        final str = val.toString().trim();
        if (str.isEmpty || str == 'null') continue;
        valueWidget = Text(str,
            style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.charcoal, fontWeight: FontWeight.w600));
      }

      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
              child: Text(field.label,
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.charcoalLight, height: 1.5)),
            ),
            const SizedBox(width: 8),
            Expanded(child: valueWidget),
          ],
        ),
      ));
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    final accent = _HeroHeader.catAccent(vendor.category);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.charcoal.withOpacity(0.07)),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.09),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(config.sectionTitle,
                  style: AppTextStyles.bodySmall.copyWith(
                      color: accent, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 14),
          Divider(color: AppColors.charcoal.withOpacity(0.07), height: 1),
          const SizedBox(height: 14),
          ...rows,
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05, end: 0);
  }
}

// ── Package Card ───────────────────────────────────────────────────────────────
class _PackageCard extends StatefulWidget {
  final VendorPackage package;
  final int index;
  const _PackageCard({required this.package, required this.index});
  @override
  State<_PackageCard> createState() => _PackageCardState();
}

class _PackageCardState extends State<_PackageCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimCtrl;
  double _rotX = 0, _rotY = 0;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _shimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2500))
      ..repeat();
  }

  @override
  void dispose() { _shimCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final p = widget.package;
    final accent = p.isPopular ? AppColors.gold : AppColors.crimson;
    final accentLight = p.isPopular
        ? const Color(0xFFFFF3CC)
        : AppColors.crimson.withOpacity(0.08);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() { _hovered = false; _rotX = 0; _rotY = 0; }),
      child: LayoutBuilder(builder: (_, box) {
        return GestureDetector(
          onPanUpdate: (d) => setState(() {
            _rotY = ((d.localPosition.dx / box.maxWidth) - 0.5) * 0.18;
            _rotX = -((d.localPosition.dy / 120) - 0.5) * 0.12;
          }),
          onPanEnd: (_) => setState(() { _rotX = 0; _rotY = 0; }),
          child: AnimatedContainer(
            duration: _rotX == 0
                ? const Duration(milliseconds: 400)
                : const Duration(milliseconds: 60),
            curve: _rotX == 0 ? Curves.elasticOut : Curves.linear,
            margin: const EdgeInsets.only(bottom: 12),
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(_rotX)
              ..rotateY(_rotY),
            transformAlignment: Alignment.center,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _hovered
                      ? accent.withOpacity(0.40)
                      : p.isPopular
                          ? AppColors.gold.withOpacity(0.25)
                          : AppColors.charcoal.withOpacity(0.07),
                  width: 1.2,
                ),
                boxShadow: [
                  if (p.isPopular)
                    BoxShadow(
                      color: AppColors.gold
                          .withOpacity(_hovered ? 0.20 : 0.10),
                      blurRadius: _hovered ? 28 : 18,
                      offset: const Offset(0, 6),
                      spreadRadius: -3,
                    ),
                  BoxShadow(
                    color: Colors.black.withOpacity(_hovered ? 0.08 : 0.04),
                    blurRadius: _hovered ? 24 : 14,
                    offset: Offset(0, _hovered ? 8 : 3),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(child: Row(children: [
                          Flexible(child: Text(p.name,
                              style: AppTextStyles.headingMedium)),
                          if (p.isPopular) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.gold,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [BoxShadow(
                                    color: AppColors.gold.withOpacity(0.4),
                                    blurRadius: 8)],
                              ),
                              child: const Text('⭐ Popular',
                                  style: TextStyle(fontSize: 9,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ])),
                        // Price badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: p.isPopular
                                  ? [AppColors.gold, const Color(0xFFB8860B)]
                                  : [AppColors.crimson, const Color(0xFF950025)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(
                                color: accent.withOpacity(0.30),
                                blurRadius: 10,
                                offset: const Offset(0, 3))],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Text(p.priceLabel,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 13,
                                        fontWeight: FontWeight.w800)),
                                // Shimmer
                                AnimatedBuilder(
                                  animation: _shimCtrl,
                                  builder: (_, __) => Positioned.fill(
                                    child: FractionalTranslation(
                                      translation: Offset(
                                          _shimCtrl.value * 3 - 0.5, 0),
                                      child: Container(
                                        width: 20,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(colors: [
                                            Colors.white.withOpacity(0),
                                            Colors.white.withOpacity(0.25),
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
                      ]),
                      if (p.description != null) ...[
                        const SizedBox(height: 8),
                        Text(p.description!,
                            style: AppTextStyles.bodySmall.copyWith(height: 1.55),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                      if (p.includes.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Divider(
                          color: AppColors.charcoal.withOpacity(0.08),
                          height: 1,
                        ),
                        const SizedBox(height: 10),
                        Wrap(spacing: 8, runSpacing: 5,
                            children: p.includes.map((item) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: accentLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: accent.withOpacity(0.18)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.check_circle_rounded, size: 11,
                                color: accent),
                            const SizedBox(width: 4),
                            Text(item, style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 10,
                                color: AppColors.charcoal,
                                fontWeight: FontWeight.w600)),
                          ]),
                        )).toList()),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    )
        .animate(delay: Duration(milliseconds: widget.index * 70))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.08, end: 0)
        .scale(begin: const Offset(0.97, 0.97), end: const Offset(1, 1),
            duration: 400.ms, curve: Curves.easeOutBack);
  }
}

// ── Discount Card ──────────────────────────────────────────────────────────────
class _DiscountCard extends StatelessWidget {
  final VendorDiscount discount;
  const _DiscountCard({required this.discount});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.crimson.withOpacity(0.18)),
        boxShadow: [BoxShadow(
            color: AppColors.crimson.withOpacity(0.06),
            blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Container(
          width: 54, height: 54,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.crimson.withOpacity(0.12),
                AppColors.crimson.withOpacity(0.06),
              ]),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.crimson.withOpacity(0.20)),
          ),
          child: Center(child: Text(discount.displayValue,
              style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.crimson, fontSize: 12),
              textAlign: TextAlign.center)),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(discount.title, style: AppTextStyles.headingSmall),
          if (discount.description != null)
            Text(discount.description!,
                style: AppTextStyles.bodySmall, maxLines: 2),
          if (discount.validUntil != null) ...[
            const SizedBox(height: 4),
            Text(
              'Valid till ${discount.validUntil!.day}/${discount.validUntil!.month}/${discount.validUntil!.year}',
              style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 10, color: AppColors.charcoalLight)),
          ],
        ])),
      ]),
    );
  }
}

// ── Tappable Portfolio Grid ───────────────────────────────────────────────────
class _TappablePortfolioGrid extends StatelessWidget {
  final List<String> urls;
  const _TappablePortfolioGrid({required this.urls});

  void _openGallery(BuildContext context, int index) {
    Navigator.push(context, PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, __, ___) =>
          _FullscreenGallery(urls: urls, initialIndex: index),
      transitionsBuilder: (_, a, __, c) =>
          FadeTransition(opacity: a, child: c),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
      itemCount: urls.length.clamp(0, 9),
      itemBuilder: (_, i) {
        final isLast = i == 8 && urls.length > 9;
        return GestureDetector(
          onTap: () => _openGallery(context, i),
          child: Hero(
            tag: 'portfolio_${urls[i]}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(fit: StackFit.expand, children: [
                Image.network(urls[i], fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.surface,
                      child: const Icon(Icons.image_rounded,
                          color: AppColors.charcoalLight))),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.30),
                        Colors.transparent,
                      ])),
                ),
                if (isLast)
                  Container(
                    color: Colors.black.withOpacity(0.60),
                    child: Center(child: Text('+${urls.length - 9}',
                        style: const TextStyle(color: Colors.white,
                            fontSize: 22, fontWeight: FontWeight.bold))),
                  ),
              ]),
            ),
          ),
        );
      },
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ── Fullscreen Gallery (dark is fine for fullscreen image viewer) ──────────────
class _FullscreenGallery extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;
  const _FullscreenGallery({required this.urls, required this.initialIndex});

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late final PageController _pageCtrl;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() { _pageCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragEnd: (d) {
          if ((d.primaryVelocity ?? 0).abs() > 300) Navigator.pop(context);
        },
        child: Stack(children: [
          PageView.builder(
            controller: _pageCtrl,
            itemCount: widget.urls.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (_, i) => InteractiveViewer(
              minScale: 0.85, maxScale: 4.0,
              child: Center(
                child: i == widget.initialIndex
                    ? Hero(tag: 'portfolio_${widget.urls[i]}',
                        child: _GalleryImage(url: widget.urls[i]))
                    : _GalleryImage(url: widget.urls[i]),
              ),
            ),
          ),
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black54, shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24)),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24)),
                    child: Text('${_currentIndex + 1} / ${widget.urls.length}',
                        style: const TextStyle(color: Colors.white,
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
            ),
          ),
          if (widget.urls.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.urls.length.clamp(0, 10), (i) =>
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentIndex == i ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentIndex == i
                          ? Colors.white : Colors.white38,
                      borderRadius: BorderRadius.circular(3)),
                  )),
              ),
            ),
        ]),
      ),
    );
  }
}

class _GalleryImage extends StatelessWidget {
  final String url;
  const _GalleryImage({required this.url});
  @override
  Widget build(BuildContext context) => Image.network(
    url, fit: BoxFit.contain,
    loadingBuilder: (_, child, progress) {
      if (progress == null) return child;
      return SizedBox.expand(child: Center(
        child: CircularProgressIndicator(
          value: progress.expectedTotalBytes != null
              ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
              : null,
          color: Colors.white54, strokeWidth: 2)));
    },
    errorBuilder: (_, __, ___) => const Center(
      child: Icon(Icons.broken_image_rounded,
          color: Colors.white38, size: 48)),
  );
}

// ── Bottom Chat + Book Bar ─────────────────────────────────────────────────────
class _ChatBookingBar extends StatelessWidget {
  final RichVendorProfile vendor;
  const _ChatBookingBar({required this.vendor});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 14, 20,
              MediaQuery.of(context).padding.bottom + 14),
          decoration: BoxDecoration(
            color: AppColors.background.withOpacity(0.88),
            border: Border(
              top: BorderSide(
                color: AppColors.charcoal.withOpacity(0.08)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 20, offset: const Offset(0, -4)),
            ],
          ),
          child: Row(children: [
            // Chat button
            Expanded(
              child: GestureDetector(
                onTap: () => _openChat(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.charcoal.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.charcoal.withOpacity(0.14)),
                  ),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    Icon(Icons.chat_bubble_outline_rounded,
                        size: 16, color: AppColors.charcoal),
                    const SizedBox(width: 7),
                    Text('Chat', style: AppTextStyles.headingSmall.copyWith(
                        fontSize: 14)),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Book Now button
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () => _openBooking(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.crimson, Color(0xFF950025)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(
                        color: AppColors.crimson.withOpacity(0.35),
                        blurRadius: 18, offset: const Offset(0, 5))],
                  ),
                  child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    Icon(Icons.calendar_month_rounded,
                        size: 16, color: Colors.white),
                    SizedBox(width: 7),
                    Text('Book Now', style: TextStyle(color: Colors.white,
                        fontSize: 14, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _openChat(BuildContext context) async {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) return;
    try {
      final convo = await ChatService.getOrCreateConversation(
        hostId: currentUser.id, vendorId: vendor.userId);
      if (context.mounted) {
        Navigator.push(context, PageRouteBuilder(
          pageBuilder: (_, __, ___) => ChatScreen(
            conversationId: convo.id,
            otherUserName: vendor.businessName),
          transitionsBuilder: (_, a, __, c) =>
              FadeTransition(opacity: a, child: c),
        ));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppStrings.errorOccurred),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  void _openBooking(BuildContext context) {
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (_, __, ___) => _CreateBookingSheet(vendor: vendor),
      transitionsBuilder: (_, a, __, c) => SlideTransition(
        position: Tween<Offset>(
            begin: const Offset(0, 1), end: Offset.zero)
            .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
        child: c),
    ));
  }
}

// ── Create Booking Sheet ───────────────────────────────────────────────────────
class _CreateBookingSheet extends StatefulWidget {
  final RichVendorProfile vendor;
  const _CreateBookingSheet({required this.vendor});

  @override
  State<_CreateBookingSheet> createState() => _CreateBookingSheetState();
}

class _CreateBookingSheetState extends State<_CreateBookingSheet> {
  DateTime? _eventDate;
  VendorPackage? _selectedPackage;
  final _amountCtrl = TextEditingController();
  final _notesCtrl  = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.vendor.packages.isNotEmpty) {
      _selectedPackage = widget.vendor.packages.first;
      _amountCtrl.text = '${_selectedPackage!.price}';
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = AuthService.currentUser;
    if (user == null || _eventDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please select an event date.'),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating));
      return;
    }
    final amount = int.tryParse(_amountCtrl.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please enter a valid amount.'),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating));
      return;
    }

    setState(() => _saving = true);
    final booking = await BookingService.createBooking(
      hostId: user.id,
      vendorId: widget.vendor.userId,
      packageId: _selectedPackage?.id,
      eventDate: _eventDate!,
      serviceCategory: widget.vendor.category,
      agreedAmount: amount,
      notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (booking != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppStrings.bookingConfirmed),
        backgroundColor: AppColors.freshTalent,
        behavior: SnackBarBehavior.floating));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppStrings.errorOccurred),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _HeroHeader.catAccent(widget.vendor.category);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(AppStrings.confirmBooking,
            style: AppTextStyles.headingMedium),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded,
              color: AppColors.charcoalLight),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vendor summary card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.charcoal.withOpacity(0.07)),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12, offset: const Offset(0, 3))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(widget.vendor.businessName,
                    style: AppTextStyles.headingMedium),
                const SizedBox(height: 4),
                Text(widget.vendor.category,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.charcoalLight)),
              ]),
            ),
            const SizedBox(height: 22),
            Text(AppStrings.eventDate,
                style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.charcoalMid)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 7)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now()
                      .add(const Duration(days: 365 * 2)),
                  builder: (ctx, child) => Theme(
                    data: ThemeData.light().copyWith(
                      colorScheme: ColorScheme.light(primary: accent)),
                    child: child!),
                );
                if (picked != null) setState(() => _eventDate = picked);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _eventDate != null
                        ? accent.withOpacity(0.5)
                        : AppColors.charcoal.withOpacity(0.10)),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(children: [
                  Icon(Icons.calendar_month_rounded,
                      color: _eventDate != null
                          ? accent : AppColors.charcoalLight,
                      size: 20),
                  const SizedBox(width: 10),
                  Text(
                    _eventDate == null
                        ? 'Select event date'
                        : '${_eventDate!.day}/${_eventDate!.month}/${_eventDate!.year}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: _eventDate == null
                          ? AppColors.charcoalLight : AppColors.charcoal)),
                ]),
              ),
            ),
            if (widget.vendor.packages.isNotEmpty) ...[
              const SizedBox(height: 22),
              Text(AppStrings.selectPackage,
                  style: AppTextStyles.headingSmall.copyWith(
                      color: AppColors.charcoalMid)),
              const SizedBox(height: 8),
              ...widget.vendor.packages.map((p) => GestureDetector(
                onTap: () => setState(() {
                  _selectedPackage = p;
                  _amountCtrl.text = '${p.price}';
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _selectedPackage?.id == p.id
                        ? accent.withOpacity(0.07) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedPackage?.id == p.id
                          ? accent.withOpacity(0.45)
                          : AppColors.charcoal.withOpacity(0.08))),
                  child: Row(children: [
                    Icon(
                      _selectedPackage?.id == p.id
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: _selectedPackage?.id == p.id
                          ? accent : AppColors.charcoalLight,
                      size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(p.name,
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.charcoal))),
                    Text(p.priceLabel,
                        style: AppTextStyles.headingSmall.copyWith(
                            color: accent)),
                  ]),
                ),
              )),
            ],
            const SizedBox(height: 22),
            Text(AppStrings.agreedAmount,
                style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.charcoalMid)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.charcoal),
              decoration: InputDecoration(
                prefixText: '৳ ',
                prefixStyle: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.charcoalMid),
                hintText: '0',
                hintStyle: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.charcoalLight),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: AppColors.charcoal.withOpacity(0.10))),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: AppColors.charcoal.withOpacity(0.10))),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: accent, width: 1.5)),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.charcoal),
              decoration: InputDecoration(
                hintText: 'Additional notes (optional)',
                hintStyle: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.charcoalLight),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: AppColors.charcoal.withOpacity(0.10))),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: AppColors.charcoal.withOpacity(0.10))),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: accent, width: 1.5)),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: _saving ? null : _submit,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.crimson, Color(0xFF950025)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(
                        color: AppColors.crimson.withOpacity(0.35),
                        blurRadius: 16, offset: const Offset(0, 5))],
                  ),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    if (_saving)
                      const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                    else
                      const Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                        _saving
                            ? AppStrings.loading
                            : AppStrings.confirmBooking,
                        style: const TextStyle(color: Colors.white,
                            fontSize: 15, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

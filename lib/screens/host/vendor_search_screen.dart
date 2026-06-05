import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/app_strings.dart';
import '../../models/vendor_package_model.dart';
import '../../services/booking_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/mesh_background.dart';
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
    'All', 'venue', 'catering', 'photography', 'decor', 'makeup', 'attire', 'logistics',
  ];

  static const _categoryEmojis = {
    'All': '🔍',
    'venue': '🏛️',
    'catering': '🍽️',
    'photography': '📸',
    'decor': '🌸',
    'makeup': '💄',
    'attire': '💍',
    'logistics': '🚐',
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
    final results = await VendorPackageService.searchVendors(
      category: _selectedCategory == 'All' ? null : _selectedCategory,
      maxBudget: _maxBudget,
      sortBy: _sortBy,
    );
    if (mounted) setState(() { _vendors = results; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StaticMeshBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            _buildAppBar(),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _BudgetFilterBar(
                    initialBudget: _maxBudget,
                    onBudgetChanged: (b) {
                      setState(() => _maxBudget = b);
                      _search();
                    },
                  ),
                  const SizedBox(height: 16),
                  _CategoryRow(
                    categories: _categories,
                    emojis: _categoryEmojis,
                    selected: _selectedCategory,
                    onSelect: (c) {
                      setState(() => _selectedCategory = c);
                      _search();
                    },
                  ),
                  const SizedBox(height: 16),
                  _SortBar(
                    selected: _sortBy,
                    onSelect: (s) {
                      setState(() => _sortBy = s);
                      _search();
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(color: AppColors.crimson),
                      ),
                    )
                  else if (_vendors.isEmpty)
                    _EmptyState(category: _selectedCategory)
                  else ...[
                    Text(
                      '${_vendors.length} vendor${_vendors.length == 1 ? '' : 's'} found',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.charcoalLight),
                    ),
                    const SizedBox(height: 12),
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
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.charcoal, size: 20),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppStrings.findVendors, style: AppTextStyles.headingMedium),
          if (_maxBudget != null)
            Text(
              'Budget: ৳${_maxBudget! ~/ 1000}k',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.crimson),
            ),
        ],
      ),
    );
  }
}

// ── Budget Filter ──────────────────────────────────────────────────────────────

class _BudgetFilterBar extends StatefulWidget {
  final int? initialBudget;
  final ValueChanged<int?> onBudgetChanged;
  const _BudgetFilterBar({this.initialBudget, required this.onBudgetChanged});

  @override
  State<_BudgetFilterBar> createState() => _BudgetFilterBarState();
}

class _BudgetFilterBarState extends State<_BudgetFilterBar> {
  late double _value;
  static const _min = 10000.0;
  static const _max = 1000000.0;

  @override
  void initState() {
    super.initState();
    _value = (widget.initialBudget ?? 200000).clamp(_min, _max).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppStrings.filterByBudget, style: AppTextStyles.headingSmall),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.crimson.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '৳${(_value ~/ 1000)}k',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.crimson, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.crimson,
              inactiveTrackColor: AppColors.crimson.withOpacity(0.15),
              thumbColor: AppColors.crimson,
              overlayColor: AppColors.crimson.withOpacity(0.12),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: _value,
              min: _min,
              max: _max,
              divisions: 99,
              onChanged: (v) => setState(() => _value = v),
              onChangeEnd: (v) => widget.onBudgetChanged(v.toInt()),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('৳10k', style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
              Text('৳10 lakh', style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

// ── Category Row ───────────────────────────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  final List<String> categories;
  final Map<String, String> emojis;
  final String selected;
  final ValueChanged<String> onSelect;
  const _CategoryRow({
    required this.categories,
    required this.emojis,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
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
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? AppColors.charcoal : Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: sel ? AppColors.charcoal : AppColors.charcoal.withOpacity(0.12)),
                boxShadow: sel ? [
                  BoxShadow(
                    color: AppColors.charcoal.withOpacity(0.18),
                    blurRadius: 10, offset: const Offset(0, 4)),
                ] : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 5),
                  Text(
                    cat == 'All' ? AppStrings.all : cat,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: sel ? Colors.white : AppColors.charcoalMid,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Sort Bar ───────────────────────────────────────────────────────────────────

class _SortBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const _SortBar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final options = [
      ('rating', '⭐ Rating'),
      ('price_asc', '৳ Low–High'),
      ('price_desc', '৳ High–Low'),
      ('experience', '🏅 Experience'),
    ];
    return Row(
      children: [
        Text('Sort: ', style: AppTextStyles.bodySmall.copyWith(color: AppColors.charcoalLight)),
        ...options.map((opt) {
          final sel = opt.$1 == selected;
          return GestureDetector(
            onTap: () => onSelect(opt.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: sel ? AppColors.gold.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: sel ? AppColors.gold : AppColors.charcoal.withOpacity(0.12)),
              ),
              child: Text(
                opt.$2,
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 11,
                  color: sel ? AppColors.gold : AppColors.charcoalMid,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ── Vendor Card ────────────────────────────────────────────────────────────────

class _VendorCard extends StatelessWidget {
  final RichVendorProfile vendor;
  final int index;
  final VoidCallback onTap;
  const _VendorCard({required this.vendor, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasDiscount = vendor.discounts.any((d) => d.isActive && !d.isExpired);

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 14),
        padding: EdgeInsets.zero,
        borderRadius: 20,
        boxShadow: [
          BoxShadow(
            color: AppColors.crimson.withOpacity(0.06),
            blurRadius: 18, offset: const Offset(0, 6)),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2)),
        ],
        child: Column(
          children: [
            // Cover photo strip
            Container(
              height: vendor.coverPhotoUrl != null ? 120 : 6,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                gradient: vendor.coverPhotoUrl == null
                    ? LinearGradient(colors: [
                        AppColors.crimson.withOpacity(0.6),
                        AppColors.gold.withOpacity(0.4),
                      ])
                    : null,
                image: vendor.coverPhotoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(vendor.coverPhotoUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(vendor.businessName,
                                style: AppTextStyles.headingSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 3),
                            Row(children: [
                              _CategoryBadge(vendor.category),
                              if (vendor.isVerified) ...[
                                const SizedBox(width: 6),
                                _VerifiedBadge(),
                              ],
                              if (hasDiscount) ...[
                                const SizedBox(width: 6),
                                _DiscountBadge(vendor.discounts.first.displayValue),
                              ],
                            ]),
                          ],
                        ),
                      ),
                      _RatingBadge(vendor.rating, vendor.totalReviews),
                    ],
                  ),
                  if (vendor.bio != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      vendor.bio!,
                      style: AppTextStyles.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Info pills row
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (vendor.location != null)
                        _InfoPill(Icons.location_on_rounded, vendor.location!),
                      if (vendor.capacity != null)
                        _InfoPill(Icons.people_rounded, '${vendor.capacity} guests'),
                      if (vendor.yearsExperience > 0)
                        _InfoPill(Icons.star_rounded, '${vendor.yearsExperience}y exp.'),
                      _InfoPill(Icons.shopping_bag_rounded,
                          '${vendor.totalBookings} bookings'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Price + CTA
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppStrings.priceRange,
                                style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
                            Text(vendor.priceRangeDisplay,
                                style: AppTextStyles.currencyMedium.copyWith(
                                    fontSize: 15, color: AppColors.crimson)),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.visibility_rounded, size: 15),
                        label: Text(AppStrings.viewProfile,
                            style: const TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 70))
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
  }
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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.gold.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.star_rounded, size: 13, color: AppColors.gold),
          const SizedBox(width: 3),
          Text(rating.toStringAsFixed(1),
              style: AppTextStyles.headingSmall.copyWith(
                  fontSize: 13, color: AppColors.gold)),
        ]),
      ),
      const SizedBox(height: 2),
      Text('$reviews reviews',
          style: AppTextStyles.bodySmall.copyWith(fontSize: 9)),
    ],
  );
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
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.all(30),
    child: Column(children: [
      const Text('🔍', style: TextStyle(fontSize: 44)),
      const SizedBox(height: 14),
      Text(AppStrings.noVendorsFound, style: AppTextStyles.headingMedium,
          textAlign: TextAlign.center),
      const SizedBox(height: 6),
      Text(
        'Try increasing your budget or selecting a different category.',
        style: AppTextStyles.bodySmall,
        textAlign: TextAlign.center,
      ),
    ]),
  ).animate(delay: 200.ms).fadeIn(duration: 400.ms);
}

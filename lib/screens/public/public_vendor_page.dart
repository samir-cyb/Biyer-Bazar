import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../models/vendor_package_model.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';
import '../../services/budget_service.dart';
import '../../widgets/auth_guard.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/mesh_background.dart';
import '../host/vendor_detail_screen.dart';

// Category filter data
const _filterCats = [
  ('All', '🔍'),
  ('Photography', '📸'),
  ('Catering', '🍽️'),
  ('Venue', '🏛️'),
  ('Decor', '✨'),
  ('Makeup', '💄'),
  ('Attire', '💍'),
  ('Music', '🎵'),
  ('Logistics', '🚐'),
];

const _categoryDbPatterns = <String, String>{
  'Photography': '%Photo%',
  'Catering':    '%Catering%',
  'Venue':       '%Venue%',
  'Decor':       '%Decor%',
  'Makeup':      '%Makeup%',
  'Attire':      '%Attire%',
  'Music':       '%Music%',
  'Logistics':   '%Logistics%',
};

// ─────────────────────────────────────────────────────────────────────────────
class PublicVendorPage extends StatefulWidget {
  final String? initialCategory;
  const PublicVendorPage({super.key, this.initialCategory});
  @override
  State<PublicVendorPage> createState() => _PublicVendorPageState();
}

class _PublicVendorPageState extends State<PublicVendorPage> {
  final _searchCtrl = TextEditingController();
  late String _selectedCat;
  String _sortBy = 'rating';
  bool _loading = false;
  List<RichVendorProfile> _vendors = [];
  List<RichVendorProfile> _featured = [];

  // ── Budget filter state ──────────────────────────────────────────────────
  bool _budgetFilterOn = false;
  double _budgetMin = 0;
  double _budgetMax = 500000;
  List<SavedBudgetPlan> _budgetPlans = [];
  SavedBudgetPlan? _activePlan;
  bool _loadingBudgetPlans = false;

  @override
  void initState() {
    super.initState();
    // Apply category from landing page tap, fall back to 'All'
    _selectedCat = widget.initialCategory ?? 'All';
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Toggles the budget filter. On first activation, loads saved budget plans
  /// and shows a picker if the user has multiple. Sets _budgetMin/_budgetMax
  /// from the chosen plan's total budget.
  Future<void> _toggleBudgetFilter() async {
    if (_budgetFilterOn) {
      // Turn off
      setState(() => _budgetFilterOn = false);
      _load();
      return;
    }

    // Turn on — need a budget range
    final user = AuthService.currentUser;
    if (user == null) {
      AuthGuard.check(
        context,
        message: 'Sign in to use budget filtering.',
        onAuthenticated: () => _toggleBudgetFilter(),
      );
      return;
    }

    if (_budgetPlans.isEmpty) {
      setState(() => _loadingBudgetPlans = true);
      _budgetPlans = await BudgetService.getAllPlans(user.id);
      setState(() => _loadingBudgetPlans = false);
    }

    if (!mounted) return;

    if (_budgetPlans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No saved budget plans found. Create one in Budget Planner.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    if (_budgetPlans.length == 1) {
      _applyBudgetPlan(_budgetPlans.first);
    } else {
      // Show selector sheet
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _BudgetPlanPickerSheet(
          plans: _budgetPlans,
          selected: _activePlan,
          onSelect: (plan) {
            Navigator.pop(context);
            _applyBudgetPlan(plan);
          },
        ),
      );
    }
  }

  void _applyBudgetPlan(SavedBudgetPlan plan) {
    final total = plan.totalBudget;
    setState(() {
      _activePlan = plan;
      _budgetMin = 0;
      _budgetMax = total;
      _budgetFilterOn = true;
    });
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    // Load featured (top-rated, no budget filter for featured)
    final all = await VendorPackageService.searchVendors(
      category: null,
      maxBudget: null,
      sortBy: 'rating',
    );

    // Apply category + budget filter for the main list
    var filtered = _selectedCat == 'All'
        ? List<RichVendorProfile>.from(all)
        : all.where((v) {
            final pattern =
                (_categoryDbPatterns[_selectedCat] ?? '%')
                    .replaceAll('%', '')
                    .toLowerCase();
            return v.category.toLowerCase().contains(pattern);
          }).toList();

    // Apply budget range filter when active
    if (_budgetFilterOn) {
      filtered = filtered.where((v) {
        final min = v.priceRangeMin ?? 0;
        final max = v.priceRangeMax ?? min;
        // Include vendor if their price range overlaps with the selected budget range
        return min <= _budgetMax && (max == 0 || max >= _budgetMin);
      }).toList();

      // Sort budget-filtered results: best fit (price range closest to budget max) first
      filtered.sort((a, b) {
        final aDiff = (_budgetMax - (a.priceRangeMin ?? 0)).abs();
        final bDiff = (_budgetMax - (b.priceRangeMin ?? 0)).abs();
        return aDiff.compareTo(bDiff);
      });
    } else {
      if (_sortBy == 'price_asc') {
        filtered.sort((a, b) => (a.priceRangeMin ?? 0).compareTo(b.priceRangeMin ?? 0));
      } else if (_sortBy == 'price_desc') {
        filtered.sort((a, b) => (b.priceRangeMin ?? 0).compareTo(a.priceRangeMin ?? 0));
      } else if (_sortBy == 'experience') {
        filtered.sort((a, b) => b.yearsExperience.compareTo(a.yearsExperience));
      }
    }

    final query = _searchCtrl.text.trim().toLowerCase();
    final searched = query.isEmpty
        ? filtered
        : filtered
            .where((v) =>
                v.businessName.toLowerCase().contains(query) ||
                v.category.toLowerCase().contains(query))
            .toList();

    if (mounted) {
      setState(() {
        _vendors = searched;
        _featured = all
            .where((v) => v.rating >= 4.0 && v.totalReviews >= 2)
            .take(6)
            .toList();
        _loading = false;
      });
    }
  }

  void _onVendorTap(RichVendorProfile vendor) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => VendorDetailScreen(vendor: vendor),
        transitionsBuilder: (_, a, __, c) =>
            FadeTransition(opacity: a, child: c),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StaticMeshBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // ── Sticky header ────────────────────────────────────────────
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyHeader(
                selectedCat: _selectedCat,
                onCatSelected: (c) {
                  setState(() => _selectedCat = c);
                  _load();
                },
                searchCtrl: _searchCtrl,
                onSearch: _load,
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 8),

                  // ── Sort bar + budget toggle ───────────────────────────
                  Row(
                    children: [
                      Flexible(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: _LightSortBar(
                            selected: _budgetFilterOn ? 'budget' : _sortBy,
                            onSelect: (s) { setState(() => _sortBy = s); _load(); },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _BudgetTogglePill(
                        active: _budgetFilterOn,
                        loading: _loadingBudgetPlans,
                        onTap: _toggleBudgetFilter,
                      ),
                    ],
                  ),

                  // ── Budget filter bar (shown when filter is ON) ────────
                  if (_budgetFilterOn && _activePlan != null) ...[
                    const SizedBox(height: 10),
                    _BudgetFilterBar(
                      plan: _activePlan!,
                      min: _budgetMin,
                      max: _budgetMax,
                      hardMax: _activePlan!.totalBudget,
                      onRangeChanged: (min, max) {
                        setState(() { _budgetMin = min; _budgetMax = max; });
                        _load();
                      },
                      onChangePlan: _budgetPlans.length > 1
                          ? () async {
                              await showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => _BudgetPlanPickerSheet(
                                  plans: _budgetPlans,
                                  selected: _activePlan,
                                  onSelect: (plan) {
                                    Navigator.pop(context);
                                    _applyBudgetPlan(plan);
                                  },
                                ),
                              );
                            }
                          : null,
                    ),
                  ],

                  // ── Featured section ──────────────────────────────────
                  if (_featured.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    _SectionHeader(
                      title: 'Featured Vendors',
                      subtitle: 'বেছে নেওয়া সেরা ভেন্ডর',
                      badge: '⭐ Top Rated',
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _featured.length,
                        itemBuilder: (_, i) =>
                            _FeaturedCard(vendor: _featured[i], onTap: () => _onVendorTap(_featured[i])),
                      ),
                    ),
                  ],

                  // ── All vendors ───────────────────────────────────────
                  const SizedBox(height: 32),
                  _SectionHeader(
                    title: 'All Vendors',
                    subtitle: _budgetFilterOn ? '💰 Budget Filtered' : 'সকল ভেন্ডর',
                    badge: _loading
                        ? '...'
                        : '${_vendors.length} found',
                  ),
                  const SizedBox(height: 16),

                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(48),
                        child: CircularProgressIndicator(
                            color: AppColors.crimson, strokeWidth: 2),
                      ),
                    )
                  else if (_vendors.isEmpty)
                    _EmptyVendors(onReset: () {
                      setState(() {
                        _selectedCat = 'All';
                        _searchCtrl.clear();
                      });
                      _load();
                    })
                  else
                    ..._vendors.asMap().entries.map((e) =>
                      _LightVendorCard(
                        vendor: e.value,
                        index: e.key,
                        onTap: () => _onVendorTap(e.value),
                        onContact: () => AuthGuard.check(
                          context,
                          message: 'Sign in to chat with this vendor.',
                          onAuthenticated: () => _onVendorTap(e.value),
                        ),
                      )),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STICKY HEADER — search + filters
// ─────────────────────────────────────────────────────────────────────────────
class _StickyHeader extends SliverPersistentHeaderDelegate {
  final String selectedCat;
  final ValueChanged<String> onCatSelected;
  final TextEditingController searchCtrl;
  final VoidCallback onSearch;
  const _StickyHeader({
    required this.selectedCat, required this.onCatSelected,
    required this.searchCtrl, required this.onSearch,
  });

  @override
  double get minExtent => 140;
  @override
  double get maxExtent => 140;

  @override
  bool shouldRebuild(_StickyHeader old) =>
      old.selectedCat != selectedCat;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          color: AppColors.background.withOpacity(0.92),
          padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                        color: AppColors.charcoal.withOpacity(0.08)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12, offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      const Icon(Icons.search_rounded,
                          color: AppColors.charcoalLight, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: searchCtrl,
                          onChanged: (_) => onSearch(),
                          decoration: InputDecoration(
                            hintText: 'Search vendors, categories...',
                            hintStyle: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.charcoalLight),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Category chips
              SizedBox(
                height: 36,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filterCats.length,
                  itemBuilder: (_, i) {
                    final (cat, emoji) = _filterCats[i];
                    final sel = cat == selectedCat;
                    return GestureDetector(
                      onTap: () => onCatSelected(cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          gradient: sel
                              ? const LinearGradient(
                                  colors: [AppColors.crimson, Color(0xFF950025)])
                              : null,
                          color: sel ? null : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: sel
                                ? Colors.transparent
                                : AppColors.charcoal.withOpacity(0.10),
                          ),
                          boxShadow: sel
                              ? [BoxShadow(
                                  color: AppColors.crimson.withOpacity(0.30),
                                  blurRadius: 10, offset: const Offset(0, 3))]
                              : [BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 6, offset: const Offset(0, 2))],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(emoji,
                                style: const TextStyle(fontSize: 13)),
                            const SizedBox(width: 5),
                            Text(cat,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: sel
                                      ? Colors.white
                                      : AppColors.charcoalMid,
                                  fontWeight: sel
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 12,
                                )),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SORT BAR
// ─────────────────────────────────────────────────────────────────────────────
class _LightSortBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const _LightSortBar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final opts = [
      ('rating', '⭐', 'Rating'),
      ('price_asc', '↑৳', 'Low–High'),
      ('price_desc', '↓৳', 'High–Low'),
      ('experience', '🏅', 'Experience'),
    ];
    return Row(
      children: [
        Text('Sort by  ',
            style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.charcoalLight, fontWeight: FontWeight.w500)),
        ...opts.map((o) {
          final sel = o.$1 == selected;
          return GestureDetector(
            onTap: () => onSelect(o.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: sel
                    ? AppColors.gold.withOpacity(0.12)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: sel
                        ? AppColors.gold.withOpacity(0.45)
                        : AppColors.charcoal.withOpacity(0.08)),
                boxShadow: sel
                    ? [BoxShadow(
                        color: AppColors.gold.withOpacity(0.18),
                        blurRadius: 8, offset: const Offset(0, 2))]
                    : [BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(o.$2, style: const TextStyle(fontSize: 11)),
                const SizedBox(width: 4),
                Text(o.$3,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 11,
                      color: sel ? AppColors.gold : AppColors.charcoalMid,
                      fontWeight:
                          sel ? FontWeight.w700 : FontWeight.w500,
                    )),
              ]),
            ),
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BUDGET TOGGLE PILL
// ─────────────────────────────────────────────────────────────────────────────
class _BudgetTogglePill extends StatelessWidget {
  final bool active;
  final bool loading;
  final VoidCallback onTap;
  const _BudgetTogglePill({required this.active, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.crimson : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? AppColors.crimson : AppColors.charcoal.withOpacity(0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: active
                  ? AppColors.crimson.withOpacity(0.30)
                  : Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: loading
            ? const SizedBox(
                width: 14, height: 14,
                child: CircularProgressIndicator(
                  color: AppColors.crimson, strokeWidth: 2))
            : Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.account_balance_wallet_rounded,
                    size: 14, color: active ? Colors.white : AppColors.charcoalMid),
                const SizedBox(width: 5),
                Text('Budget',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 11,
                      color: active ? Colors.white : AppColors.charcoalMid,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(width: 4),
                Icon(
                  active ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
                  size: 18,
                  color: active ? Colors.white.withOpacity(0.85) : AppColors.charcoalLight,
                ),
              ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BUDGET FILTER BAR (shown when filter is ON)
// ─────────────────────────────────────────────────────────────────────────────
class _BudgetFilterBar extends StatefulWidget {
  final SavedBudgetPlan plan;
  final double min, max, hardMax;
  final void Function(double min, double max) onRangeChanged;
  final VoidCallback? onChangePlan;
  const _BudgetFilterBar({
    required this.plan, required this.min, required this.max,
    required this.hardMax, required this.onRangeChanged, this.onChangePlan,
  });

  @override
  State<_BudgetFilterBar> createState() => _BudgetFilterBarState();
}

class _BudgetFilterBarState extends State<_BudgetFilterBar> {
  late double _localMin;
  late double _localMax;

  @override
  void initState() {
    super.initState();
    _localMin = widget.min;
    _localMax = widget.max;
  }

  @override
  void didUpdateWidget(_BudgetFilterBar old) {
    super.didUpdateWidget(old);
    // Sync local state when parent resets the range (e.g. plan changed)
    if (old.min != widget.min || old.max != widget.max) {
      _localMin = widget.min;
      _localMax = widget.max;
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeMax = widget.hardMax <= 0 ? 1000000.0 : widget.hardMax;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.crimson.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.crimson.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.filter_alt_rounded, size: 15, color: AppColors.crimson),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Budget: ৳${(_localMin / 1000).toStringAsFixed(0)}k – ৳${(_localMax / 1000).toStringAsFixed(0)}k',
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.crimson, fontSize: 12),
              ),
            ),
            if (widget.onChangePlan != null)
              GestureDetector(
                onTap: widget.onChangePlan,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.crimson.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('Change Plan',
                      style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 10, color: AppColors.crimson, fontWeight: FontWeight.w700)),
                ),
              ),
          ]),
          Text(
            'Plan: "${widget.plan.planName}" · Total ৳${widget.plan.totalBudget.toInt()}',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.charcoalLight, fontSize: 10),
          ),
          const SizedBox(height: 6),
          RangeSlider(
            min: 0,
            max: safeMax,
            divisions: 20,
            values: RangeValues(
              _localMin.clamp(0, safeMax),
              _localMax.clamp(0, safeMax),
            ),
            activeColor: AppColors.crimson,
            inactiveColor: AppColors.crimson.withOpacity(0.15),
            labels: RangeLabels(
              '৳${(_localMin / 1000).toStringAsFixed(0)}k',
              '৳${(_localMax / 1000).toStringAsFixed(0)}k',
            ),
            // Local setState gives instant visual feedback while dragging
            onChanged: (v) => setState(() { _localMin = v.start; _localMax = v.end; }),
            // Only trigger the heavy _load() call when the user lifts their finger
            onChangeEnd: (v) => widget.onRangeChanged(v.start, v.end),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BUDGET PLAN PICKER SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _BudgetPlanPickerSheet extends StatelessWidget {
  final List<SavedBudgetPlan> plans;
  final SavedBudgetPlan? selected;
  final ValueChanged<SavedBudgetPlan> onSelect;
  const _BudgetPlanPickerSheet({
    required this.plans, required this.selected, required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.charcoalLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Choose Budget Plan', style: AppTextStyles.headingLarge),
          const SizedBox(height: 6),
          Text('Vendors will be filtered to fit within this plan',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.charcoalLight)),
          const SizedBox(height: 16),
          ...plans.map((plan) {
            final isSel = plan.id == selected?.id;
            return GestureDetector(
              onTap: () => onSelect(plan),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSel ? AppColors.crimson.withOpacity(0.06) : AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSel ? AppColors.crimson : AppColors.divider,
                    width: isSel ? 1.5 : 1,
                  ),
                ),
                child: Row(children: [
                  const Text('💰', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan.planName, style: AppTextStyles.headingSmall.copyWith(
                          color: isSel ? AppColors.crimson : AppColors.charcoal)),
                      Text('৳ ${plan.totalBudget.toInt()} total · ${plan.categories.length} categories',
                          style: AppTextStyles.bodySmall),
                    ],
                  )),
                  if (isSel)
                    const Icon(Icons.check_circle_rounded, color: AppColors.crimson, size: 22),
                ]),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title, subtitle, badge;
  const _SectionHeader({
    required this.title, required this.subtitle, required this.badge});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.gold, fontWeight: FontWeight.w600,
                      fontSize: 11, letterSpacing: 0.3)),
              const SizedBox(height: 2),
              Text(title,
                  style: AppTextStyles.headingLarge.copyWith(fontSize: 20)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.crimson.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.crimson.withOpacity(0.20)),
          ),
          child: Text(badge,
              style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.crimson, fontWeight: FontWeight.w700,
                  fontSize: 11)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FEATURED CARD — horizontal scroll
// ─────────────────────────────────────────────────────────────────────────────
class _FeaturedCard extends StatefulWidget {
  final RichVendorProfile vendor;
  final VoidCallback onTap;
  const _FeaturedCard({required this.vendor, required this.onTap});
  @override
  State<_FeaturedCard> createState() => _FeaturedCardState();
}

class _FeaturedCardState extends State<_FeaturedCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final v = widget.vendor;
    final imgUrl = v.coverPhotoUrl ??
        (v.portfolioUrls.isNotEmpty ? v.portfolioUrls.first : null);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.03 : 1.0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: Container(
            width: 160,
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16, offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo
                  SizedBox(
                    height: 110,
                    child: imgUrl != null
                        ? CachedNetworkImage(
                            imageUrl: imgUrl,
                            fit: BoxFit.cover, width: double.infinity,
                            placeholder: (_, __) => Container(
                                color: AppColors.crimson.withOpacity(0.08)),
                            errorWidget: (_, __, ___) => _AvatarPlaceholder(
                                name: v.businessName,
                                color: AppColors.crimson),
                          )
                        : _AvatarPlaceholder(
                            name: v.businessName, color: AppColors.crimson),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v.businessName,
                            style: AppTextStyles.headingSmall
                                .copyWith(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 3),
                        Text(v.category,
                            style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 10,
                                color: AppColors.charcoalLight),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        Row(children: [
                          const Icon(Icons.star_rounded,
                              size: 12, color: AppColors.gold),
                          const SizedBox(width: 3),
                          Text(
                            v.totalReviews > 0
                                ? v.rating.toStringAsFixed(1)
                                : 'New',
                            style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 11,
                                color: AppColors.gold,
                                fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          if (v.isVerified)
                            const Icon(Icons.verified_rounded,
                                size: 13,
                                color: AppColors.freshTalent),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms)
        .slideX(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  final String name;
  final Color color;
  const _AvatarPlaceholder({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(RegExp(r'\s+')).take(2)
            .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
    return Container(
      width: double.infinity, height: double.infinity,
      color: color.withOpacity(0.10),
      child: Center(child: Text(initials,
          style: TextStyle(
              color: color, fontSize: 28, fontWeight: FontWeight.w700))),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LIGHT VENDOR CARD — full list
// ─────────────────────────────────────────────────────────────────────────────
class _LightVendorCard extends StatefulWidget {
  final RichVendorProfile vendor;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onContact;
  const _LightVendorCard({
    required this.vendor, required this.index,
    required this.onTap, required this.onContact,
  });
  @override
  State<_LightVendorCard> createState() => _LightVendorCardState();
}

class _LightVendorCardState extends State<_LightVendorCard> {
  bool _pressed = false;

  // Category → light gradient
  static List<Color> _gradientFor(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('photo') || c.contains('video') || c.contains('drone'))
      return [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)];
    if (c.contains('cater') || c.contains('food') || c.contains('cake'))
      return [const Color(0xFFFFF3E0), const Color(0xFFFFE0B2)];
    if (c.contains('venue') || c.contains('hall') || c.contains('stage'))
      return [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)];
    if (c.contains('decor') || c.contains('light') || c.contains('flower'))
      return [const Color(0xFFF3E5F5), const Color(0xFFE1BEE7)];
    if (c.contains('makeup') || c.contains('mehendi'))
      return [const Color(0xFFFCE4EC), const Color(0xFFF8BBD0)];
    if (c.contains('attire') || c.contains('jewel') || c.contains('bridal'))
      return [const Color(0xFFFFF8E1), const Color(0xFFFFECB3)];
    return [const Color(0xFFEDE7F6), const Color(0xFFD1C4E9)];
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vendor;
    final imgUrl = v.coverPhotoUrl ??
        (v.portfolioUrls.isNotEmpty ? v.portfolioUrls.first : null);
    final colors = _gradientFor(v.category);
    final hasDiscount = v.discounts.any((d) => d.isActive && !d.isExpired);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: AppColors.charcoal.withOpacity(0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 20, offset: const Offset(0, 6), spreadRadius: -2,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.8),
                blurRadius: 0, spreadRadius: 1, offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Color accent strip ──────────────────────────────────────
              Container(
                height: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Container(
                      width: 68, height: 68,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(colors: colors),
                        boxShadow: [
                          BoxShadow(
                            color: colors.last.withOpacity(0.45),
                            blurRadius: 14, offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: imgUrl != null
                            ? CachedNetworkImage(
                                imageUrl: imgUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) =>
                                    _AvatarPlaceholder(
                                        name: v.businessName,
                                        color: colors.last),
                                errorWidget: (_, __, ___) =>
                                    _AvatarPlaceholder(
                                        name: v.businessName,
                                        color: colors.last),
                              )
                            : _AvatarPlaceholder(
                                name: v.businessName, color: colors.last),
                      ),
                    ),

                    const SizedBox(width: 14),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(v.businessName,
                                    style: AppTextStyles.headingMedium
                                        .copyWith(fontSize: 16),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                              if (v.isVerified)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.freshTalent.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified_rounded,
                                          size: 11,
                                          color: AppColors.freshTalent),
                                      const SizedBox(width: 3),
                                      Text('Verified',
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                                  fontSize: 10,
                                                  color: AppColors.freshTalent,
                                                  fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Category + Location
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: colors.first,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(v.category,
                                  style: AppTextStyles.bodySmall.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.charcoalMid),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            if (v.location != null) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.location_on_rounded,
                                  size: 11,
                                  color: AppColors.charcoalLight),
                              const SizedBox(width: 2),
                              Text(v.location!,
                                  style: AppTextStyles.bodySmall.copyWith(
                                      fontSize: 11)),
                            ],
                          ]),
                          const SizedBox(height: 8),

                          // Rating + bookings
                          Row(children: [
                            const Icon(Icons.star_rounded,
                                size: 14, color: AppColors.gold),
                            const SizedBox(width: 3),
                            Text(
                              v.totalReviews > 0
                                  ? '${v.rating.toStringAsFixed(1)}  (${v.totalReviews})'
                                  : 'No reviews yet',
                              style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: v.totalReviews > 0
                                      ? AppColors.charcoalMid
                                      : AppColors.charcoalLight),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.shopping_bag_rounded,
                                size: 13, color: AppColors.charcoalLight),
                            const SizedBox(width: 3),
                            Text('${v.totalBookings} bookings',
                                style: AppTextStyles.bodySmall),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Divider ───────────────────────────────────────────────────
              Divider(
                  height: 1, indent: 16, endIndent: 16,
                  color: AppColors.charcoal.withOpacity(0.06)),

              // ── Price + CTA ───────────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Price Range',
                            style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 10,
                                color: AppColors.charcoalLight)),
                        const SizedBox(height: 2),
                        Text(v.priceRangeDisplay,
                            style: AppTextStyles.headingMedium.copyWith(
                                color: AppColors.charcoal, fontSize: 15)),
                        if (hasDiscount)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              v.discounts.first.displayValue,
                              style: AppTextStyles.bodySmall.copyWith(
                                  fontSize: 10,
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),

                    // Contact button (auth-gated)
                    GestureDetector(
                      onTap: widget.onContact,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.charcoal.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.charcoal.withOpacity(0.10)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.chat_bubble_outline_rounded,
                                size: 14, color: AppColors.charcoalMid),
                            const SizedBox(width: 6),
                            Text('Contact',
                                style: AppTextStyles.headingSmall.copyWith(
                                    fontSize: 12,
                                    color: AppColors.charcoalMid)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // View profile button
                    GestureDetector(
                      onTap: widget.onTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.crimson, Color(0xFF950025)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.crimson.withOpacity(0.30),
                              blurRadius: 12, offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text('View',
                            style: AppTextStyles.headingSmall.copyWith(
                                fontSize: 12, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: widget.index * 70))
        .fadeIn(duration: 450.ms)
        .slideY(begin: 0.10, end: 0, curve: Curves.easeOutCubic);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _EmptyVendors extends StatelessWidget {
  final VoidCallback onReset;
  const _EmptyVendors({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Text('🔍', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 14),
          Text('No Vendors Found',
              style: AppTextStyles.headingLarge),
          const SizedBox(height: 8),
          Text(
            'Try a different category or clear your search filter.',
            style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.charcoalLight),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          ElevatedButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Reset Filters'),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.crimson,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14))),
          ),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn(duration: 400.ms);
  }
}

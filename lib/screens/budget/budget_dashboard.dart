import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../models/budget_model.dart';
import '../../logic/budget_logic.dart';
import '../../services/auth_service.dart';
import '../../services/budget_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/animated_progress_bar.dart';
import '../../widgets/mesh_background.dart';

class BudgetDashboard extends StatefulWidget {
  const BudgetDashboard({super.key});
  @override
  State<BudgetDashboard> createState() => _BudgetDashboardState();
}

class _BudgetDashboardState extends State<BudgetDashboard>
    with SingleTickerProviderStateMixin {
  final _budgetCtrl  = TextEditingController();
  final _guestCtrl   = TextEditingController();
  final _planNameCtrl = TextEditingController(text: 'My Budget');
  final _notesCtrl   = TextEditingController();
  final _formKey     = GlobalKey<FormState>();
  late TabController _tabCtrl;

  BudgetPlan? _plan;
  bool _showBreakdown = false;
  bool _saving = false;
  String _eventType = 'Wedding';
  List<SavedBudgetPlan> _savedPlans = [];
  bool _loadingHistory = false;

  final _fmt = NumberFormat('#,##,###', 'en_IN');

  static const _eventTypes = [
    'Wedding', 'Holud', 'Walima', 'Engagement',
    'Birthday', 'Corporate', 'Aqiqah', 'Anniversary',
  ];

  static const _eventPresets = {
    'Wedding':     600000.0,
    'Holud':       150000.0,
    'Walima':      200000.0,
    'Engagement':  100000.0,
    'Birthday':    50000.0,
    'Corporate':   300000.0,
    'Aqiqah':      80000.0,
    'Anniversary': 120000.0,
  };

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadHistory();
  }

  @override
  void dispose() {
    _budgetCtrl.dispose();
    _guestCtrl.dispose();
    _planNameCtrl.dispose();
    _notesCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final user = AuthService.currentUser;
    if (user == null) return;
    setState(() => _loadingHistory = true);
    final plans = await BudgetService.getAllPlans(user.id);
    setState(() { _savedPlans = plans; _loadingHistory = false; });
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final budget = double.tryParse(_budgetCtrl.text.replaceAll(',', '')) ?? 0;
    final guests = int.tryParse(_guestCtrl.text) ?? 0;
    setState(() {
      _plan = BudgetLogic.createPlan(totalBudget: budget, guestCount: guests);
      _showBreakdown = true;
    });
  }

  void _applyPreset(String type) {
    final preset = _eventPresets[type];
    if (preset != null) _budgetCtrl.text = preset.toInt().toString();
    setState(() {
      _eventType = type;
      _planNameCtrl.text = '$type Budget';
    });
  }

  void _adjustCategory(String id, double newPercent) {
    if (_plan == null) return;
    setState(() {
      final updated = BudgetLogic.adjustCategory(
          categories: _plan!.categories, categoryId: id, newPercent: newPercent);
      _plan = BudgetPlan(
          totalBudget: _plan!.totalBudget,
          guestCount: _plan!.guestCount,
          categories: updated,
          notes: _plan!.notes);
    });
  }

  void _toggleLock(String id) {
    if (_plan == null) return;
    setState(() {
      final updated = BudgetLogic.toggleLock(
          categories: _plan!.categories, categoryId: id);
      _plan = BudgetPlan(
          totalBudget: _plan!.totalBudget,
          guestCount: _plan!.guestCount,
          categories: updated,
          notes: _plan!.notes);
    });
  }

  Future<void> _savePlan() async {
    final user = AuthService.currentUser;
    if (user == null || _plan == null) return;
    setState(() => _saving = true);
    final saved = await BudgetService.savePlan(
      userId: user.id,
      totalBudget: _plan!.totalBudget,
      guestCount: _plan!.guestCount,
      eventType: _eventType,
      categories: _plan!.categories,
      planName: _planNameCtrl.text.trim().isEmpty ? '$_eventType Budget' : _planNameCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    setState(() => _saving = false);
    if (saved != null) {
      await _loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('✅ Budget saved! It will auto-suggest when you post an event.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  void _loadSavedPlan(SavedBudgetPlan plan) {
    setState(() {
      _budgetCtrl.text = plan.totalBudget.toInt().toString();
      _guestCtrl.text  = plan.guestCount.toString();
      _planNameCtrl.text = plan.planName;
      _notesCtrl.text  = plan.notes ?? '';
      _eventType = plan.eventType;
      _plan = BudgetPlan(
        totalBudget: plan.totalBudget,
        guestCount: plan.guestCount,
        categories: plan.categories,
        notes: plan.notes,
      );
      _showBreakdown = true;
    });
    _tabCtrl.animateTo(0);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('📂 Loaded "${plan.planName}"'),
      backgroundColor: AppColors.charcoal,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StaticMeshBackground(child: NestedScrollView(
        headerSliverBuilder: (_, __) => [_buildAppBar()],
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [_buildCalculatorTab(), _buildHistoryTab()],
              ),
            ),
          ],
        ),
      )),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.charcoal, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text('Budget Planner', style: AppTextStyles.headingLarge),
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: AppColors.background.withOpacity(0.85)),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          color: AppColors.background.withOpacity(0.9),
          child: TabBar(
            controller: _tabCtrl,
            labelColor: AppColors.crimson,
            unselectedLabelColor: AppColors.charcoalLight,
            indicatorColor: AppColors.crimson,
            labelStyle: AppTextStyles.labelLarge.copyWith(fontSize: 12),
            tabs: [
              const Tab(text: '🧮  CALCULATE'),
              Tab(text: '📂  SAVED (${_savedPlans.length})'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalculatorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EventTypeSelector(types: _eventTypes, selected: _eventType, onSelect: _applyPreset),
          const SizedBox(height: 16),

          // Plan Name & Notes
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Plan Details', style: AppTextStyles.headingSmall),
              const SizedBox(height: 12),
              TextFormField(
                controller: _planNameCtrl,
                textCapitalization: TextCapitalization.words,
                style: AppTextStyles.bodyLarge,
                decoration: const InputDecoration(
                  labelText: 'Plan Name',
                  prefixIcon: Icon(Icons.label_rounded, color: AppColors.charcoalLight, size: 20),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                style: AppTextStyles.bodyMedium,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'e.g. Focus on photography and venue',
                  prefixIcon: Icon(Icons.notes_rounded, color: AppColors.charcoalLight, size: 20),
                  alignLabelWithHint: true,
                ),
              ),
            ]),
          ),
          const SizedBox(height: 14),

          // Budget Input
          _InputCard(
            formKey: _formKey,
            budgetCtrl: _budgetCtrl,
            guestCtrl: _guestCtrl,
            eventType: _eventType,
            onCalculate: _calculate,
          ),

          if (_showBreakdown && _plan != null) ...[
            const SizedBox(height: 20),
            _SummaryBanner(plan: _plan!, fmt: _fmt, eventType: _eventType),
            const SizedBox(height: 10),
            // Allocation health bar
            _AllocationHealthBar(plan: _plan!),
            const SizedBox(height: 14),
            _TipCard(plan: _plan!),
            const SizedBox(height: 16),
            ..._plan!.categories.asMap().entries.map((e) => _CategoryCard(
              category: e.value,
              amount: _plan!.amountFor(e.value),
              fmt: _fmt,
              onSliderChange: (v) => _adjustCategory(e.value.id, v),
              onLockToggle: () => _toggleLock(e.value.id),
              index: e.key,
            )),
            const SizedBox(height: 16),
            _PerHeadCard(plan: _plan!, fmt: _fmt),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _savePlan,
                icon: _saving
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(_saving ? 'Saving...' : 'Save This Plan'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_loadingHistory) {
      return const Center(child: CircularProgressIndicator(color: AppColors.crimson));
    }
    if (_savedPlans.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('📊', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 14),
          Text('No saved plans yet', style: AppTextStyles.headingMedium),
          const SizedBox(height: 6),
          Text('Calculate a budget and save it to see it here.',
              style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: AppColors.crimson,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _savedPlans.length,
        itemBuilder: (_, i) => _SavedPlanCard(
          plan: _savedPlans[i],
          fmt: _fmt,
          onLoad: () => _loadSavedPlan(_savedPlans[i]),
          index: i,
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _AllocationHealthBar extends StatelessWidget {
  final BudgetPlan plan;
  const _AllocationHealthBar({required this.plan});

  @override
  Widget build(BuildContext context) {
    final total = plan.totalAllocated;
    final isOver = total > 100;
    final color = isOver ? AppColors.error : total > 98 ? AppColors.success : AppColors.warning;
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Budget Allocation', style: AppTextStyles.bodySmall),
          Text(
            isOver ? '⚠️ Over by ${(total - 100).toStringAsFixed(1)}%'
                   : '${total.toStringAsFixed(1)}% allocated',
            style: AppTextStyles.bodySmall.copyWith(
              color: color, fontWeight: FontWeight.w700,
            ),
          ),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (total / 100).clamp(0.0, 1.0),
            backgroundColor: AppColors.charcoal.withOpacity(0.08),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ]),
    );
  }
}

class _SavedPlanCard extends StatelessWidget {
  final SavedBudgetPlan plan;
  final NumberFormat fmt;
  final VoidCallback onLoad;
  final int index;
  const _SavedPlanCard({required this.plan, required this.fmt, required this.onLoad, required this.index});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(plan.planName, style: AppTextStyles.headingMedium),
            Text('${plan.eventType}  ·  ${plan.createdAt.day}/${plan.createdAt.month}/${plan.createdAt.year}',
                style: AppTextStyles.bodySmall),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('৳ ${fmt.format(plan.totalBudget.toInt())}',
                style: AppTextStyles.currencyMedium.copyWith(fontSize: 16, color: AppColors.crimson)),
            Text('${fmt.format(plan.guestCount)} guests', style: AppTextStyles.bodySmall),
          ]),
        ]),
        if (plan.notes != null && plan.notes!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              const Icon(Icons.notes_rounded, size: 13, color: AppColors.charcoalLight),
              const SizedBox(width: 6),
              Expanded(child: Text(plan.notes!, style: AppTextStyles.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis)),
            ]),
          ),
        ],
        const SizedBox(height: 10),
        // Category mini-bars
        ...plan.categories.take(4).map((cat) {
          final amount = plan.totalBudget * cat.allocatedPercent / 100;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              SizedBox(width: 120, child: Text(cat.name, style: AppTextStyles.bodySmall, overflow: TextOverflow.ellipsis)),
              Expanded(child: AnimatedProgressBar(value: cat.allocatedPercent / 100, color: cat.color, height: 4)),
              const SizedBox(width: 8),
              Text('৳${fmt.format(amount.round())}', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
            ]),
          );
        }),
        if (plan.categories.length > 4)
          Text('+${plan.categories.length - 4} more categories', style: AppTextStyles.bodySmall.copyWith(color: AppColors.charcoalLight)),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onLoad,
            icon: const Icon(Icons.edit_rounded, size: 16),
            label: const Text('Load & Edit This Plan'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.crimson,
              side: BorderSide(color: AppColors.crimson.withOpacity(0.4)),
              padding: const EdgeInsets.symmetric(vertical: 11),
            ),
          ),
        ),
      ]),
    ).animate(delay: Duration(milliseconds: index * 60)).fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }
}

class _EventTypeSelector extends StatelessWidget {
  final List<String> types;
  final String selected;
  final ValueChanged<String> onSelect;
  const _EventTypeSelector({required this.types, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Event Type', style: AppTextStyles.labelLarge),
      const SizedBox(height: 8),
      SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: types.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final sel = types[i] == selected;
            return GestureDetector(
              onTap: () => onSelect(types[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: sel ? AppColors.crimson : Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sel ? AppColors.crimson : AppColors.charcoal.withOpacity(0.15)),
                ),
                child: Text(types[i], style: AppTextStyles.bodySmall.copyWith(
                    color: sel ? Colors.white : AppColors.charcoalMid,
                    fontWeight: FontWeight.w600)),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

class _InputCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController budgetCtrl;
  final TextEditingController guestCtrl;
  final String eventType;
  final VoidCallback onCalculate;
  const _InputCard({required this.formKey, required this.budgetCtrl,
      required this.guestCtrl, required this.eventType, required this.onCalculate});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Form(
        key: formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('🧮', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Bangla Budget Calculator', style: AppTextStyles.headingMedium),
              Text('বাজেট হিসাব করুন', style: AppTextStyles.bangla.copyWith(fontSize: 11)),
            ])),
          ]),
          const SizedBox(height: 18),
          TextFormField(
            controller: budgetCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTextStyles.headingMedium,
            decoration: const InputDecoration(
              labelText: 'Total Budget (BDT)',
              hintText: 'e.g. 600000',
              prefixText: '৳  ',
              prefixStyle: TextStyle(fontWeight: FontWeight.bold),
              suffixIcon: Icon(Icons.calculate_rounded, color: AppColors.charcoalLight),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter your total budget';
              final val = double.tryParse(v);
              if (val == null || val < 10000) return 'Minimum budget is ৳10,000';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: guestCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTextStyles.headingMedium,
            decoration: const InputDecoration(
              labelText: 'Expected Guest Count',
              hintText: 'e.g. 300',
              prefixIcon: Icon(Icons.people_rounded, color: AppColors.charcoalLight),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter guest count';
              final val = int.tryParse(v);
              if (val == null || val < 1) return 'Invalid guest count';
              return null;
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onCalculate,
              icon: const Icon(Icons.auto_awesome_rounded, size: 17),
              label: const Text('Calculate My Budget'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
            ),
          ),
        ]),
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0);
  }
}

class _SummaryBanner extends StatelessWidget {
  final BudgetPlan plan;
  final NumberFormat fmt;
  final String eventType;
  const _SummaryBanner({required this.plan, required this.fmt, required this.eventType});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      backgroundColor: AppColors.crimson.withOpacity(0.06),
      borderColor: AppColors.crimson.withOpacity(0.18),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$eventType Budget', style: AppTextStyles.bodyMedium),
          Text('৳ ${fmt.format(plan.totalBudget.toInt())}', style: AppTextStyles.currencyHero),
          const SizedBox(height: 4),
          Text('${fmt.format(plan.guestCount)} guests  ·  ৳${fmt.format(plan.perHeadCost.round())} per head',
              style: AppTextStyles.bodySmall),
        ])),
        const Text('💰', style: TextStyle(fontSize: 36)),
      ]),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0);
  }
}

class _TipCard extends StatelessWidget {
  final BudgetPlan plan;
  const _TipCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final perHead = plan.perHeadCost.round();
    final tip = perHead > 3000
        ? '💎 Premium budget — you can attract high-end vendors for all categories.'
        : perHead > 1500
            ? '✅ Mid-range budget — good balance. Focus spending on venue, photography & attire.'
            : '💡 Tight budget — lock Photography & Catering first, then find fresh talent for the rest.';
    return GlassCard(
      backgroundColor: AppColors.gold.withOpacity(0.06),
      borderColor: AppColors.gold.withOpacity(0.18),
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        const Text('💡', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(child: Text(tip, style: AppTextStyles.bodySmall)),
      ]),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final BudgetCategory category;
  final double amount;
  final NumberFormat fmt;
  final ValueChanged<double> onSliderChange;
  final VoidCallback onLockToggle;
  final int index;
  const _CategoryCard({required this.category, required this.amount, required this.fmt,
      required this.onSliderChange, required this.onLockToggle, required this.index});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(children: [
        Row(children: [
          Container(width: 40, height: 40,
            decoration: BoxDecoration(color: category.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(category.icon, color: category.color, size: 19)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(category.name, style: AppTextStyles.headingSmall),
            Text(category.banglaName, style: AppTextStyles.bangla.copyWith(fontSize: 10)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('৳ ${fmt.format(amount.round())}',
                style: AppTextStyles.currencyMedium.copyWith(color: category.color, fontSize: 14)),
            Text('${category.allocatedPercent.toStringAsFixed(1)}%',
                style: AppTextStyles.bodySmall),
          ]),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onLockToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: category.isLocked ? AppColors.crimson.withOpacity(0.1) : AppColors.charcoal.withOpacity(0.05),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(category.isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                  size: 15,
                  color: category.isLocked ? AppColors.crimson : AppColors.charcoalLight),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        AnimatedProgressBar(value: category.allocatedPercent / 100, color: category.color),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: category.color,
            thumbColor: category.color,
            inactiveTrackColor: category.color.withOpacity(0.12),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: category.allocatedPercent.clamp(1.0, 90.0),
            min: 1, max: 90,
            onChanged: category.isLocked ? null : onSliderChange,
          ),
        ),
      ]),
    ).animate(delay: Duration(milliseconds: 80 + index * 50)).fadeIn(duration: 300.ms).slideX(begin: 0.04, end: 0);
  }
}

class _PerHeadCard extends StatelessWidget {
  final BudgetPlan plan;
  final NumberFormat fmt;
  const _PerHeadCard({required this.plan, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final perHead = plan.perHeadCost.round();
    final quality = perHead > 3000
        ? ('Premium', AppColors.gold, '⭐')
        : perHead > 1500
            ? ('Mid-Range', AppColors.freshTalent, '✅')
            : ('Budget', AppColors.charcoalLight, '💡');
    return GlassCard(
      backgroundColor: AppColors.gold.withOpacity(0.06),
      borderColor: AppColors.gold.withOpacity(0.18),
      child: Row(children: [
        Text(quality.$3, style: const TextStyle(fontSize: 30)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Per-Head Cost', style: AppTextStyles.bodyMedium),
          Text('৳ ${fmt.format(perHead)}',
              style: AppTextStyles.currencyMedium.copyWith(fontSize: 20)),
          const SizedBox(height: 4),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: quality.$2.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(quality.$1, style: AppTextStyles.labelMedium.copyWith(color: quality.$2, fontSize: 10))),
        ])),
      ]),
    ).animate(delay: 400.ms).fadeIn(duration: 350.ms);
  }
}

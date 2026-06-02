import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../models/budget_model.dart';
import '../../logic/budget_logic.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/animated_progress_bar.dart';

class BudgetDashboard extends StatefulWidget {
  const BudgetDashboard({super.key});

  @override
  State<BudgetDashboard> createState() => _BudgetDashboardState();
}

class _BudgetDashboardState extends State<BudgetDashboard> {
  final _budgetController = TextEditingController();
  final _guestController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  BudgetPlan? _plan;
  bool _showBreakdown = false;

  final _formatter = NumberFormat('#,##,###', 'en_IN');

  @override
  void dispose() {
    _budgetController.dispose();
    _guestController.dispose();
    super.dispose();
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final raw = _budgetController.text.replaceAll(',', '').trim();
    final budget = double.tryParse(raw) ?? 0;
    final guests = int.tryParse(_guestController.text.trim()) ?? 0;
    setState(() {
      _plan = BudgetLogic.createPlan(totalBudget: budget, guestCount: guests);
      _showBreakdown = true;
    });
  }

  void _adjustCategory(String id, double newPercent) {
    if (_plan == null) return;
    setState(() {
      final updated = BudgetLogic.adjustCategory(
        categories: _plan!.categories,
        categoryId: id,
        newPercent: newPercent,
      );
      _plan = BudgetPlan(
        totalBudget: _plan!.totalBudget,
        guestCount: _plan!.guestCount,
        categories: updated,
      );
    });
  }

  void _toggleLock(String id) {
    if (_plan == null) return;
    setState(() {
      final updated = BudgetLogic.toggleLock(
        categories: _plan!.categories,
        categoryId: id,
      );
      _plan = BudgetPlan(
        totalBudget: _plan!.totalBudget,
        guestCount: _plan!.guestCount,
        categories: updated,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded,
                  color: AppColors.charcoal, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('Budget Calculator', style: AppTextStyles.headingLarge),
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child:
                    Container(color: AppColors.background.withOpacity(0.85)),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _InputCard(
                  formKey: _formKey,
                  budgetController: _budgetController,
                  guestController: _guestController,
                  onCalculate: _calculate,
                ),
                if (_showBreakdown && _plan != null) ...[
                  const SizedBox(height: 24),
                  _SummaryHeader(plan: _plan!, formatter: _formatter),
                  const SizedBox(height: 20),
                  ..._plan!.categories.asMap().entries.map(
                        (e) => _CategoryCard(
                          category: e.value,
                          amount: _plan!.amountFor(e.value),
                          formatter: _formatter,
                          onSliderChange: (v) =>
                              _adjustCategory(e.value.id, v),
                          onLockToggle: () => _toggleLock(e.value.id),
                          index: e.key,
                        ),
                      ),
                  const SizedBox(height: 20),
                  _PerHeadCard(plan: _plan!, formatter: _formatter),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController budgetController;
  final TextEditingController guestController;
  final VoidCallback onCalculate;

  const _InputCard({
    required this.formKey,
    required this.budgetController,
    required this.guestController,
    required this.onCalculate,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🧮', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bangla Budget Planner',
                          style: AppTextStyles.headingLarge),
                      Text('বাজেট পরিকল্পনাকারী',
                          style: AppTextStyles.bangla.copyWith(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            TextFormField(
              controller: budgetController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppTextStyles.headingMedium,
              decoration: InputDecoration(
                labelText: 'Total Budget (BDT)',
                hintText: 'e.g. 600000',
                prefixText: '৳  ',
                prefixStyle: AppTextStyles.currencyMedium,
                suffixIcon: const Icon(Icons.calculate_rounded,
                    color: AppColors.charcoalLight),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter your total budget';
                final val = double.tryParse(v.replaceAll(',', ''));
                if (val == null || val < 10000) {
                  return 'Minimum budget is ৳10,000';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: guestController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppTextStyles.headingMedium,
              decoration: const InputDecoration(
                labelText: 'Expected Guest Count',
                hintText: 'e.g. 300',
                prefixIcon:
                    Icon(Icons.people_rounded, color: AppColors.charcoalLight),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter guest count';
                final val = int.tryParse(v);
                if (val == null || val < 1) return 'Invalid guest count';
                return null;
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onCalculate,
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: const Text('Calculate My Budget'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.crimson,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
  }
}

class _SummaryHeader extends StatelessWidget {
  final BudgetPlan plan;
  final NumberFormat formatter;
  const _SummaryHeader({required this.plan, required this.formatter});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      backgroundColor: AppColors.crimson.withOpacity(0.06),
      borderColor: AppColors.crimson.withOpacity(0.18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Budget', style: AppTextStyles.bodyMedium),
                Text(
                  '৳ ${formatter.format(plan.totalBudget)}',
                  style: AppTextStyles.currencyHero,
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatter.format(plan.guestCount)} guests  •  ৳${formatter.format(plan.perHeadCost.round())} per head',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.crimson.withOpacity(0.1),
            ),
            child: const Text('💰', style: TextStyle(fontSize: 28)),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}

class _CategoryCard extends StatelessWidget {
  final BudgetCategory category;
  final double amount;
  final NumberFormat formatter;
  final ValueChanged<double> onSliderChange;
  final VoidCallback onLockToggle;
  final int index;

  const _CategoryCard({
    required this.category,
    required this.amount,
    required this.formatter,
    required this.onSliderChange,
    required this.onLockToggle,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(category.icon, color: category.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.name,
                        style: AppTextStyles.headingSmall),
                    Text(category.banglaName,
                        style: AppTextStyles.bangla.copyWith(fontSize: 11)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '৳ ${formatter.format(amount.round())}',
                    style: AppTextStyles.currencyMedium.copyWith(
                      color: category.color,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    '${category.allocatedPercent.toStringAsFixed(1)}%',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onLockToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: category.isLocked
                        ? AppColors.crimson.withOpacity(0.1)
                        : AppColors.charcoal.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    category.isLocked
                        ? Icons.lock_rounded
                        : Icons.lock_open_rounded,
                    size: 16,
                    color: category.isLocked
                        ? AppColors.crimson
                        : AppColors.charcoalLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedProgressBar(
            value: category.allocatedPercent / 100,
            color: category.color,
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: category.color,
              thumbColor: category.color,
              inactiveTrackColor: category.color.withOpacity(0.15),
              overlayColor: category.color.withOpacity(0.1),
              trackHeight: 3,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: category.allocatedPercent.clamp(1.0, 90.0),
              min: 1,
              max: 90,
              onChanged: category.isLocked ? null : onSliderChange,
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 100 + index * 80))
        .fadeIn(duration: 350.ms)
        .slideX(begin: 0.05, end: 0);
  }
}

class _PerHeadCard extends StatelessWidget {
  final BudgetPlan plan;
  final NumberFormat formatter;
  const _PerHeadCard({required this.plan, required this.formatter});

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
      borderColor: AppColors.gold.withOpacity(0.2),
      child: Row(
        children: [
          Text(quality.$3, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Per-Head Cost', style: AppTextStyles.bodyMedium),
                Text(
                  '৳ ${formatter.format(perHead)}',
                  style: AppTextStyles.currencyMedium.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: quality.$2.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    quality.$1,
                    style: AppTextStyles.labelMedium
                        .copyWith(color: quality.$2, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: 500.ms).fadeIn(duration: 400.ms);
  }
}

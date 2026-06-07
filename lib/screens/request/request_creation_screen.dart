import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/service_categories.dart';
import '../../services/budget_service.dart';
import '../../services/auth_service.dart';
import '../../services/post_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/mesh_background.dart';

class RequestCreationScreen extends StatefulWidget {
  const RequestCreationScreen({super.key});

  @override
  State<RequestCreationScreen> createState() =>
      _RequestCreationScreenState();
}

class _RequestCreationScreenState extends State<RequestCreationScreen> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  String _location = 'Dhaka';
  DateTime? _eventDate;
  final _guestController = TextEditingController();
  final _budgetController = TextEditingController();
  String _selectedCategory = ServiceCategories.all.first;
  final _descController = TextEditingController();
  List<SavedBudgetPlan> _allBudgets = [];
  SavedBudgetPlan? _suggestedBudget;
  bool _loadingSuggestedBudget = false;

  final List<String> _locations = [
    'Dhaka', 'Chittagong', 'Sylhet', 'Rajshahi', 'Khulna',
    'Barishal', 'Cumilla', 'Mymensingh', 'Rangpur', 'Narayanganj',
  ];

  final List<String> _categories = ServiceCategories.all;

  @override
  void initState() {
    super.initState();
    _loadSuggestedBudget();
  }

  Future<void> _loadSuggestedBudget() async {
    final user = AuthService.currentUser;
    if (user == null) return;
    setState(() => _loadingSuggestedBudget = true);
    final plans = await BudgetService.getAllPlans(user.id);
    setState(() {
      _allBudgets = plans;
      _suggestedBudget = plans.isNotEmpty ? plans.first : null;
      _loadingSuggestedBudget = false;
    });
  }

  /// Shows a bottom sheet for the user to pick which saved budget to use.
  void _showBudgetSelector() {
    if (_allBudgets.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BudgetSelectorSheet(
        plans: _allBudgets,
        selected: _suggestedBudget,
        onSelect: (plan) {
          setState(() => _suggestedBudget = plan);
          Navigator.pop(context);
        },
      ),
    );
  }

  /// Applies the budget slice that matches the currently selected service.
  void _applySuggestedBudget() {
    if (_suggestedBudget == null) return;

    // Auto-fill guest count if empty
    if (_guestController.text.isEmpty) {
      _guestController.text = _suggestedBudget!.guestCount.toString();
    }

    // Find matching budget category for the selected service
    final budgetCatId = ServiceCategories.budgetCategoryFor(_selectedCategory);

    if (budgetCatId != null) {
      // Check if this category exists in the saved plan
      final amount = BudgetService.getCategoryAmount(_suggestedBudget!, budgetCatId);
      if (amount != null && amount > 0) {
        setState(() {
          _budgetController.text = amount.toInt().toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            '✅ Applied ৳${amount.toInt()} — your $_selectedCategory budget from "${_suggestedBudget!.planName}"',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        return;
      }
    }

    // This service has no matching budget category — show helpful popup
    _showNotInBudgetDialog();
  }

  /// Shown when the selected service is not in the saved budget plan.
  void _showNotInBudgetDialog() {
    final plan = _suggestedBudget!;
    final suggested = BudgetService.suggestAmountForNewService(plan);
    final unallocated = BudgetService.unallocatedPercent(plan);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Text('⚠️', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(child: Text('Not in your budget', style: AppTextStyles.headingLarge)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"$_selectedCategory" has no allocation in your "${plan.planName}" plan.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gold.withOpacity(0.3)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('💡 Suggested amount', style: AppTextStyles.headingSmall),
                const SizedBox(height: 6),
                Text(
                  '৳ ${suggested.toInt()}',
                  style: AppTextStyles.currencyMedium.copyWith(color: AppColors.gold),
                ),
                const SizedBox(height: 4),
                Text(
                  unallocated > 2
                      ? 'Based on ${unallocated.toStringAsFixed(1)}% unallocated in your plan'
                      : 'Based on 5% of your total budget (plan is nearly full)',
                  style: AppTextStyles.bodySmall,
                ),
              ]),
            ),
            const SizedBox(height: 12),
            Text(
              'If you confirm, this will be added to your saved plan and filled in the budget field.',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
              // Just fill the suggested amount, don't add to plan
              setState(() => _budgetController.text = suggested.toInt().toString());
            },
            child: const Text('Use suggestion only'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _budgetController.text = suggested.toInt().toString());
              // Add to saved plan
              final pct = suggested / plan.totalBudget * 100;
              final added = await BudgetService.addCategoryToPlan(
                plan: plan,
                categoryId: _selectedCategory.toLowerCase().replaceAll(' ', '_').replaceAll('&', 'and'),
                categoryName: _selectedCategory,
                allocatedPercent: pct,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(added
                      ? '✅ "$_selectedCategory" added to your budget plan!'
                      : '⚠️ Amount applied. Could not update saved plan.'),
                  backgroundColor: added ? AppColors.success : AppColors.warning,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ));
                // Reload the plan so next time shows the new category
                await _loadSuggestedBudget();
              }
            },
            child: const Text('Confirm & Add to Plan'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _guestController.dispose();
    _budgetController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _submit();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _submit() async {
    final user = AuthService.currentUser;
    if (user == null) return;

    // Show loading on the button
    setState(() => _currentStep = _currentStep); // trigger rebuild for loading

    final post = await PostService.createPost(
      host: user,
      location: _location,
      eventDate: _eventDate ?? DateTime.now().add(const Duration(days: 30)),
      guestCapacity: int.tryParse(_guestController.text) ?? 100,
      serviceCategory: _selectedCategory,
      budgetCeiling: int.tryParse(_budgetController.text) ?? 0,
      description: _descController.text.trim(),
      budgetPlanId: _suggestedBudget?.id,
    );

    if (!mounted) return;

    if (post == null) {
      // Creation failed — stay on screen, show error
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('❌ Failed to publish post. Please try again.'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return; // DON'T pop — let the host try again
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('🎉 Post published! Vendors will start bidding soon.'),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final steps = ['Event Info', 'Service Needs', 'Review & Post'];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StaticMeshBackground(child: Column(
        children: [
          _buildHeader(steps),
          _StepIndicator(currentStep: _currentStep, steps: steps),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _Step1EventInfo(
                  location: _location,
                  locations: _locations,
                  eventDate: _eventDate,
                  guestController: _guestController,
                  onLocationChanged: (v) =>
                      setState(() => _location = v ?? _location),
                  onDatePicked: (d) => setState(() => _eventDate = d),
                ),
                _Step2ServiceNeeds(
                  selectedCategory: _selectedCategory,
                  categories: _categories,
                  budgetController: _budgetController,
                  descController: _descController,
                  onCategoryChanged: (c) =>
                      setState(() => _selectedCategory = c),
                  suggestedBudget: _suggestedBudget,
                  allBudgets: _allBudgets,
                  loadingSuggestedBudget: _loadingSuggestedBudget,
                  onApplySuggestedBudget: _applySuggestedBudget,
                  onSelectBudget: _allBudgets.length > 1 ? _showBudgetSelector : null,
                ),
                _Step3Review(
                  location: _location,
                  eventDate: _eventDate,
                  guests: _guestController.text,
                  category: _selectedCategory,
                  budget: _budgetController.text,
                  description: _descController.text,
                ),
              ],
            ),
          ),
          _buildNavButtons(),
        ],
      )),
    );
  }

  Widget _buildHeader(List<String> steps) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: AppColors.background.withOpacity(0.85),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            right: 20,
            bottom: 12,
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded,
                    color: AppColors.charcoal, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Post an Event',
                        style: AppTextStyles.headingLarge),
                    Text(
                        'Step ${_currentStep + 1} of 3 — ${steps[_currentStep]}',
                        style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButtons() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.95),
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.charcoal,
                  side: BorderSide(
                      color: AppColors.charcoal.withOpacity(0.25)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _nextStep,
              child: Text(
                  _currentStep < 2 ? 'Continue' : '🚀  Publish Post'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> steps;
  const _StepIndicator({required this.currentStep, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: List.generate(
          steps.length,
          (i) => Expanded(
            child: Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= currentStep
                          ? AppColors.crimson
                          : AppColors.charcoal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                if (i < steps.length - 1) const SizedBox(width: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Step1EventInfo extends StatelessWidget {
  final String location;
  final List<String> locations;
  final DateTime? eventDate;
  final TextEditingController guestController;
  final ValueChanged<String?> onLocationChanged;
  final ValueChanged<DateTime> onDatePicked;

  const _Step1EventInfo({
    required this.location,
    required this.locations,
    required this.eventDate,
    required this.guestController,
    required this.onLocationChanged,
    required this.onDatePicked,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header('📍', 'Event Details', 'When and where is your wedding?'),
          const SizedBox(height: 24),
          GlassCard(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: location,
                  decoration: const InputDecoration(
                    labelText: 'City / Location',
                    prefixIcon: Icon(Icons.location_on_rounded,
                        color: AppColors.charcoalLight),
                  ),
                  items: locations
                      .map((l) =>
                          DropdownMenuItem(value: l, child: Text(l)))
                      .toList(),
                  onChanged: onLocationChanged,
                  style: AppTextStyles.bodyLarge,
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate:
                          DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now()
                          .add(const Duration(days: 730)),
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: const ColorScheme.light(
                              primary: AppColors.crimson),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) onDatePicked(picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.charcoal.withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded,
                            color: AppColors.charcoalLight, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            eventDate != null
                                ? '${eventDate!.day}/${eventDate!.month}/${eventDate!.year}'
                                : 'Select Event Date',
                            style: eventDate != null
                                ? AppTextStyles.bodyLarge
                                : AppTextStyles.bodyLarge.copyWith(
                                    color: AppColors.charcoalLight),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down_rounded,
                            color: AppColors.charcoalLight),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: guestController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  style: AppTextStyles.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: 'Expected Guests',
                    hintText: 'e.g. 300',
                    prefixIcon: Icon(Icons.people_rounded,
                        color: AppColors.charcoalLight),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _Step2ServiceNeeds extends StatelessWidget {
  final String selectedCategory;
  final List<String> categories;
  final TextEditingController budgetController;
  final TextEditingController descController;
  final ValueChanged<String> onCategoryChanged;
  final SavedBudgetPlan? suggestedBudget;
  final List<SavedBudgetPlan> allBudgets;
  final bool loadingSuggestedBudget;
  final VoidCallback onApplySuggestedBudget;
  final VoidCallback? onSelectBudget;

  const _Step2ServiceNeeds({
    required this.selectedCategory,
    required this.categories,
    required this.budgetController,
    required this.descController,
    required this.onCategoryChanged,
    this.suggestedBudget,
    this.allBudgets = const [],
    this.loadingSuggestedBudget = false,
    required this.onApplySuggestedBudget,
    this.onSelectBudget,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header('🎯', 'Service Needed', 'What do you need vendors for?'),
          const SizedBox(height: 24),
          Text('Service Category', style: AppTextStyles.labelLarge),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((cat) {
              final sel = cat == selectedCategory;
              return GestureDetector(
                onTap: () => onCategoryChanged(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel
                        ? AppColors.crimson
                        : Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: sel
                          ? AppColors.crimson
                          : AppColors.charcoal.withOpacity(0.15),
                    ),
                    boxShadow: sel
                        ? [
                            BoxShadow(
                              color: AppColors.crimson.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : null,
                  ),
                  child: Text(
                    cat,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: sel
                          ? Colors.white
                          : AppColors.charcoalMid,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          // ── Budget Suggestion Banner ──────────────────────────────────────
          if (loadingSuggestedBudget)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(color: AppColors.crimson, backgroundColor: Colors.transparent),
            )
          else if (suggestedBudget != null)
            Builder(builder: (context) {
              // Find the specific allocation for the currently selected service
              final budgetCatId = ServiceCategories.budgetCategoryFor(selectedCategory);
              double? catAmount;
              if (budgetCatId != null) {
                final match = suggestedBudget!.categories
                    .where((c) => c.id == budgetCatId)
                    .toList();
                if (match.isNotEmpty && match.first.allocatedPercent > 0) {
                  catAmount = suggestedBudget!.totalBudget * match.first.allocatedPercent / 100;
                }
              }
              return GestureDetector(
                onTap: onSelectBudget,
                child: GlassCard(
                  backgroundColor: AppColors.gold.withOpacity(0.07),
                  borderColor: AppColors.gold.withOpacity(0.25),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Text('💰', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Text('Saved budget available!', style: AppTextStyles.headingSmall),
                            if (onSelectBudget != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('${allBudgets.length} plans · tap to change',
                                    style: AppTextStyles.bodySmall.copyWith(
                                        fontSize: 9, color: AppColors.gold, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ]),
                          const SizedBox(height: 2),
                          if (catAmount != null)
                            Text(
                              '৳ ${catAmount.toInt()} for $selectedCategory',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.gold,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          else
                            Text(
                              'No allocation found for $selectedCategory',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.charcoalLight),
                            ),
                          Text(
                            'Plan: "${suggestedBudget!.planName}" · ৳ ${suggestedBudget!.totalBudget.toInt()} total',
                            style: AppTextStyles.bodySmall,
                          ),
                        ])),
                        ElevatedButton(
                          onPressed: onApplySuggestedBudget,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            textStyle: AppTextStyles.labelMedium.copyWith(fontSize: 11),
                          ),
                          child: const Text('Apply'),
                        ),
                      ]),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              children: [
                TextFormField(
                  controller: budgetController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  style: AppTextStyles.headingMedium,
                  decoration: InputDecoration(
                    labelText: 'Budget Ceiling (BDT)',
                    hintText: 'Maximum you will pay',
                    prefixText: '৳  ',
                    prefixStyle: AppTextStyles.currencyMedium
                        .copyWith(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: descController,
                  maxLines: 4,
                  style: AppTextStyles.bodyLarge,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Describe your requirements',
                    hintText:
                        'e.g. Holud photography, cinematic style, 6 hrs coverage...',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _Step3Review extends StatelessWidget {
  final String location;
  final DateTime? eventDate;
  final String guests;
  final String category;
  final String budget;
  final String description;
  const _Step3Review({
    required this.location,
    required this.eventDate,
    required this.guests,
    required this.category,
    required this.budget,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header('✅', 'Review & Post',
              'Confirm your event details before going live'),
          const SizedBox(height: 24),
          GlassCard(
            backgroundColor: AppColors.crimson.withOpacity(0.04),
            borderColor: AppColors.crimson.withOpacity(0.15),
            child: Column(
              children: [
                _Row('Location', location),
                _Row(
                    'Event Date',
                    eventDate != null
                        ? '${eventDate!.day}/${eventDate!.month}/${eventDate!.year}'
                        : 'Not set'),
                _Row('Guests',
                    guests.isEmpty ? '—' : '$guests guests'),
                _Row('Service', category),
                _Row('Budget Cap',
                    budget.isEmpty ? '—' : '৳ $budget'),
                _Row('Description',
                    description.isEmpty ? '—' : description,
                    isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            backgroundColor: AppColors.gold.withOpacity(0.07),
            borderColor: AppColors.gold.withOpacity(0.2),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Text('🎯', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Once published, vendors will submit blind bids within 24–48 hours. You\'ll receive up to 7 curated proposals.',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _Header extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  const _Header(this.emoji, this.title, this.subtitle);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.displaySmall),
              Text(subtitle, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Budget Selector Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _BudgetSelectorSheet extends StatelessWidget {
  final List<SavedBudgetPlan> plans;
  final SavedBudgetPlan? selected;
  final ValueChanged<SavedBudgetPlan> onSelect;
  const _BudgetSelectorSheet({
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
          Text('Select a Budget Plan', style: AppTextStyles.headingLarge),
          const SizedBox(height: 6),
          Text('Choose which saved budget to apply to this event',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.charcoalLight)),
          const SizedBox(height: 20),
          ...plans.map((plan) {
            final isSelected = plan.id == selected?.id;
            return GestureDetector(
              onTap: () => onSelect(plan),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.gold.withOpacity(0.08)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.gold : AppColors.divider,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.gold.withOpacity(0.15)
                          : AppColors.charcoal.withOpacity(0.07),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('💰', style: TextStyle(fontSize: isSelected ? 20 : 18)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan.planName, style: AppTextStyles.headingSmall.copyWith(
                          color: isSelected ? AppColors.gold : AppColors.charcoal)),
                      const SizedBox(height: 2),
                      Text('৳ ${plan.totalBudget.toInt()} · ${plan.categories.length} categories',
                          style: AppTextStyles.bodySmall),
                    ],
                  )),
                  if (isSelected)
                    const Icon(Icons.check_circle_rounded, color: AppColors.gold, size: 22),
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

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;
  const _Row(this.label, this.value, {this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 110,
                child: Text(label,
                    style: AppTextStyles.bodySmall
                        .copyWith(fontWeight: FontWeight.w600)),
              ),
              Expanded(
                  child: Text(value, style: AppTextStyles.bodyMedium)),
            ],
          ),
        ),
        if (!isLast)
          Divider(height: 1, color: AppColors.divider),
      ],
    );
  }
}

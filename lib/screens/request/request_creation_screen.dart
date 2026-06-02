import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../services/auth_service.dart';
import '../../services/post_service.dart';
import '../../widgets/glass_card.dart';

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
  String _selectedCategory = 'Photography & Video';
  final _descController = TextEditingController();

  final List<String> _locations = [
    'Dhaka', 'Chittagong', 'Sylhet', 'Rajshahi', 'Khulna'
  ];

  final List<String> _categories = [
    'Photography & Video', 'Catering', 'Decor & Lighting',
    'Makeup Artist', 'Venue', 'Attire & Jewelry', 'Logistics',
  ];

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

  void _submit() {
    final user = AuthService.currentUser;
    if (user == null) return;

    PostService.createPost(
      host: user,
      location: _location,
      eventDate:
          _eventDate ?? DateTime.now().add(const Duration(days: 30)),
      guestCapacity: int.tryParse(_guestController.text) ?? 100,
      serviceCategory: _selectedCategory,
      budgetCeiling: int.tryParse(_budgetController.text) ?? 0,
      description: _descController.text.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('🎉 Post published! Vendors will start bidding soon.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    Navigator.pop(context); // return to host home / my posts
  }

  @override
  Widget build(BuildContext context) {
    final steps = ['Event Info', 'Service Needs', 'Review & Post'];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
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
      ),
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

  const _Step2ServiceNeeds({
    required this.selectedCategory,
    required this.categories,
    required this.budgetController,
    required this.descController,
    required this.onCategoryChanged,
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

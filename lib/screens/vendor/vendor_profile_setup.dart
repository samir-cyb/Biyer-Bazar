import 'dart:developer' as dev;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/app_strings.dart';
import '../../core/service_categories.dart';
import '../../core/vendor_category_config.dart';
import '../../models/vendor_package_model.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';
import '../../services/profile_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/mesh_background.dart';

class VendorProfileSetupScreen extends StatefulWidget {
  const VendorProfileSetupScreen({super.key});

  @override
  State<VendorProfileSetupScreen> createState() =>
      _VendorProfileSetupScreenState();
}

class _VendorProfileSetupScreenState extends State<VendorProfileSetupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // Profile fields
  final _bizCtrl    = TextEditingController();
  final _bioCtrl    = TextEditingController();
  final _addrCtrl   = TextEditingController();
  final _minCtrl    = TextEditingController();
  final _maxCtrl    = TextEditingController();
  final _capCtrl    = TextEditingController();
  final _expCtrl    = TextEditingController();
  String _category  = ServiceCategories.all.first;
  String _city      = 'Dhaka';
  String _avail     = 'available';
  List<String> _tags = [];
  final _tagCtrl    = TextEditingController();
  String? _coverPhotoUrl;
  bool _savingProfile = false;

  static const _cities = [
    'Dhaka', 'Chittagong', 'Sylhet', 'Rajshahi',
    'Khulna', 'Barishal', 'Cumilla', 'Mymensingh', 'Rangpur', 'Narayanganj',
  ];

  // Category-specific details
  Map<String, dynamic> _categoryDetails = {};

  // Packages
  List<VendorPackage> _packages = [];
  bool _loadingPkgs = true;

  // Discounts
  List<VendorDiscount> _discounts = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _prefillFromCurrentUser();
    _loadPackages();
    _loadCategoryDetails();
  }

  void _prefillFromCurrentUser() {
    final u = AuthService.currentUser;
    if (u == null) return;
    _bizCtrl.text  = u.businessName ?? '';
    _bioCtrl.text  = u.bio ?? '';
    _minCtrl.text  = u.priceRangeMin?.toString() ?? '';
    _maxCtrl.text  = u.priceRangeMax?.toString() ?? '';
    _expCtrl.text  = u.yearsExperience.toString();
    _addrCtrl.text = u.address ?? '';
    _capCtrl.text  = u.capacity?.toString() ?? '';
    if (u.vendorCategory != null) _category = u.vendorCategory!;
    if (u.location != null && _cities.contains(u.location)) _city = u.location!;
    if (u.specialtyTags.isNotEmpty) _tags = List<String>.from(u.specialtyTags);
    _avail = u.availabilityStatus;
    _coverPhotoUrl = u.coverPhotoUrl;
  }

  Future<void> _loadPackages() async {
    final u = AuthService.currentUser;
    if (u == null) return;
    final pkgs  = await VendorPackageService.getPackages(u.id);
    final discs = await VendorPackageService.getDiscounts(u.id);
    if (mounted) setState(() {
      _packages  = pkgs;
      _discounts = discs;
      _loadingPkgs = false;
    });
  }

  Future<void> _loadCategoryDetails() async {
    final u = AuthService.currentUser;
    if (u == null) return;
    try {
      final row = await SupabaseService.vendorProfiles
          .select('category_details')
          .eq('user_id', u.id)
          .maybeSingle();
      if (row != null && row['category_details'] != null && mounted) {
        final raw = row['category_details'];
        setState(() {
          _categoryDetails = raw is Map
              ? Map<String, dynamic>.from(raw)
              : {};
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _bizCtrl.dispose(); _bioCtrl.dispose(); _addrCtrl.dispose();
    _minCtrl.dispose(); _maxCtrl.dispose(); _capCtrl.dispose();
    _expCtrl.dispose(); _tagCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final u = AuthService.currentUser;
    if (u == null) return;
    setState(() => _savingProfile = true);

    final payload = {
      'business_name':       _bizCtrl.text.trim(),
      'bio':                 _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
      'category':            _category,
      'location':            _city,
      'address':             _addrCtrl.text.trim().isEmpty ? null : _addrCtrl.text.trim(),
      'price_range_min':     int.tryParse(_minCtrl.text),
      'price_range_max':     int.tryParse(_maxCtrl.text),
      'capacity':            int.tryParse(_capCtrl.text),
      'years_experience':    int.tryParse(_expCtrl.text) ?? 0,
      'specialty_tags':      _tags,
      'availability_status': _avail,
      'category_details':    _categoryDetails,
      if (_coverPhotoUrl != null) 'cover_photo_url': _coverPhotoUrl,
      // Only reset to pending if not already approved — don't penalise minor edits
      'approval_status': u.approvalStatus == 'approved' ? 'approved' : 'pending',
    }..removeWhere((_, v) => v == null); // strip null values to avoid type errors

    dev.log('[ProfileSetup] Saving payload: $payload', name: 'BiyerBajar');

    try {
      // Check if a vendor_profiles row already exists for this user
      final existing = await SupabaseService.vendorProfiles
          .select('user_id')
          .eq('user_id', u.id)
          .maybeSingle();

      dev.log('[ProfileSetup] Existing row: $existing', name: 'BiyerBajar');

      if (existing != null) {
        // Row exists — use UPDATE
        await SupabaseService.vendorProfiles
            .update(payload)
            .eq('user_id', u.id);
      } else {
        // No row yet — INSERT
        await SupabaseService.vendorProfiles
            .insert({...payload, 'user_id': u.id});
      }

      dev.log('[ProfileSetup] Save successful', name: 'BiyerBajar');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Profile saved! Awaiting admin approval.'),
          backgroundColor: AppColors.freshTalent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      dev.log('[ProfileSetup] Save FAILED: $e', name: 'BiyerBajar', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Save failed: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
        ));
      }
    }

    if (mounted) setState(() => _savingProfile = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StaticMeshBackground(
        child: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.background,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded,
                    color: AppColors.charcoal, size: 20),
                onPressed: () => Navigator.maybePop(context),
              ),
              title: Text(AppStrings.editProfile, style: AppTextStyles.headingMedium),
              bottom: TabBar(
                controller: _tabCtrl,
                labelColor: AppColors.crimson,
                unselectedLabelColor: AppColors.charcoalLight,
                indicatorColor: AppColors.crimson,
                indicatorWeight: 2.5,
                labelStyle: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700),
                unselectedLabelStyle: AppTextStyles.bodySmall,
                tabs: const [
                  Tab(text: 'Profile'),
                  Tab(text: 'Packages'),
                  Tab(text: 'Discounts'),
                ],
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabCtrl,
            children: [
              _ProfileTab(
                bizCtrl: _bizCtrl,    bioCtrl: _bioCtrl,
                addrCtrl: _addrCtrl,  minCtrl: _minCtrl,
                maxCtrl: _maxCtrl,    capCtrl: _capCtrl,
                expCtrl: _expCtrl,    tagCtrl: _tagCtrl,
                category: _category,  city: _city,
                avail: _avail,        tags: _tags,
                cities: _cities,
                onCategoryChanged: (v) => setState(() => _category = v),
                onCityChanged:     (v) => setState(() => _city = v),
                onAvailChanged:    (v) => setState(() => _avail = v),
                onAddTag:          (t) => setState(() { if (t.isNotEmpty) _tags.add(t); }),
                onRemoveTag:       (t) => setState(() => _tags.remove(t)),
                onSave: _saveProfile,
                saving: _savingProfile,
                vendorId: AuthService.currentUser?.id ?? '',
                portfolioUrls: AuthService.currentUser?.portfolioUrls ?? [],
                coverPhotoUrl: _coverPhotoUrl,
                onCoverPhotoChanged: (url) => setState(() => _coverPhotoUrl = url),
                categoryDetails: _categoryDetails,
                onCategoryDetailsChanged: (m) => setState(() => _categoryDetails = m),
              ),
              _PackagesTab(
                packages: _packages,
                loading: _loadingPkgs,
                vendorId: AuthService.currentUser?.id ?? '',
                onRefresh: _loadPackages,
                category: _category,
              ),
              _DiscountsTab(
                discounts: _discounts,
                vendorId: AuthService.currentUser?.id ?? '',
                onRefresh: _loadPackages,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Profile Tab ────────────────────────────────────────────────────────────────

class _ProfileTab extends StatelessWidget {
  final TextEditingController bizCtrl, bioCtrl, addrCtrl,
      minCtrl, maxCtrl, capCtrl, expCtrl, tagCtrl;
  final String category, city, avail;
  final List<String> tags, cities;
  final ValueChanged<String> onCategoryChanged, onCityChanged, onAvailChanged;
  final ValueChanged<String> onAddTag;
  final ValueChanged<String> onRemoveTag;
  final VoidCallback onSave;
  final bool saving;
  final String vendorId;
  final List<String> portfolioUrls;
  final String? coverPhotoUrl;
  final ValueChanged<String?> onCoverPhotoChanged;
  final Map<String, dynamic> categoryDetails;
  final ValueChanged<Map<String, dynamic>> onCategoryDetailsChanged;

  const _ProfileTab({
    required this.bizCtrl,    required this.bioCtrl,
    required this.addrCtrl,   required this.minCtrl,
    required this.maxCtrl,    required this.capCtrl,
    required this.expCtrl,    required this.tagCtrl,
    required this.category,   required this.city,
    required this.avail,      required this.tags,
    required this.cities,
    required this.onCategoryChanged, required this.onCityChanged,
    required this.onAvailChanged,    required this.onAddTag,
    required this.onRemoveTag,       required this.onSave,
    required this.saving,
    required this.vendorId,
    required this.portfolioUrls,
    required this.coverPhotoUrl,
    required this.onCoverPhotoChanged,
    required this.categoryDetails,
    required this.onCategoryDetailsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status note
          GlassCard(
            backgroundColor: AppColors.gold.withOpacity(0.06),
            borderColor: AppColors.gold.withOpacity(0.3),
            child: Row(children: [
              const Text('⏳', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(child: Text(
                'Your profile will go live after admin approval. Fill in all details carefully.',
                style: AppTextStyles.bodySmall,
              )),
            ]),
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 20),
          _FieldSection(
            title: AppStrings.businessName,
            child: _TextField(ctrl: bizCtrl, hint: 'e.g. Royal Moments Photography'),
          ),
          _FieldSection(
            title: AppStrings.bio,
            child: _TextField(ctrl: bioCtrl, hint: 'Tell hosts about your services...', maxLines: 4),
          ),
          _FieldSection(
            title: 'Category',
            child: DropdownButtonFormField<String>(
              value: category,
              items: ServiceCategories.all.map((c) =>
                  DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) { if (v != null) onCategoryChanged(v); },
              decoration: _dropdownDecor(),
            ),
          ),
          // ── Category-specific tag checkboxes ───────────────────────
          _CategorySpecificSection(
            category: category,
            selectedTags: tags,
            onAddTag: onAddTag,
            onRemoveTag: onRemoveTag,
          ),
          // ── Category-specific structured fields ─────────────────────
          _CategoryDetailsSection(
            category: category,
            initialDetails: categoryDetails,
            onChanged: onCategoryDetailsChanged,
          ),
          _FieldSection(
            title: 'City',
            child: DropdownButtonFormField<String>(
              value: city,
              items: cities.map((c) =>
                  DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) { if (v != null) onCityChanged(v); },
              decoration: _dropdownDecor(),
            ),
          ),
          _FieldSection(
            title: 'Full Address (optional)',
            child: _TextField(ctrl: addrCtrl, hint: 'Road, area, district'),
          ),
          _FieldSection(
            title: AppStrings.priceRange,
            child: Row(children: [
              Expanded(child: _TextField(ctrl: minCtrl, hint: 'Min ৳', isNum: true)),
              const SizedBox(width: 12),
              Expanded(child: _TextField(ctrl: maxCtrl, hint: 'Max ৳', isNum: true)),
            ]),
          ),
          _FieldSection(
            title: _capacityLabel(category),
            child: _TextField(ctrl: capCtrl,
                hint: category == 'catering' ? 'e.g. 100 guests min'
                    : category == 'venue'    ? 'e.g. 500 guests max'
                    : 'Optional',
                isNum: true),
          ),
          _FieldSection(
            title: 'Years of Experience',
            child: _TextField(ctrl: expCtrl, hint: 'e.g. 5', isNum: true),
          ),
          _FieldSection(
            title: AppStrings.availability,
            child: DropdownButtonFormField<String>(
              value: avail,
              items: const [
                DropdownMenuItem(value: 'available', child: Text('✅ Available')),
                DropdownMenuItem(value: 'busy',      child: Text('🟡 Busy')),
                DropdownMenuItem(value: 'unavailable', child: Text('🔴 Unavailable')),
              ],
              onChanged: (v) { if (v != null) onAvailChanged(v); },
              decoration: _dropdownDecor(),
            ),
          ),
          // Specialty tags
          _FieldSection(
            title: AppStrings.specialties,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: _TextField(ctrl: tagCtrl, hint: 'e.g. Outdoor wedding')),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      onAddTag(tagCtrl.text.trim());
                      tagCtrl.clear();
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
                    child: const Text('Add'),
                  ),
                ]),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 6,
                    children: tags.map((t) => Chip(
                      label: Text(t, style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
                      backgroundColor: AppColors.gold.withOpacity(0.10),
                      side: BorderSide(color: AppColors.gold.withOpacity(0.2)),
                      deleteIcon: const Icon(Icons.close_rounded, size: 14),
                      onDeleted: () => onRemoveTag(t),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
          // ── Portfolio photos ──────────────────────────────────────────
          _FieldSection(
            title: '${AppStrings.portfolio} (max 10 — tap ⭐ to set as cover)',
            child: _PortfolioUploadSection(
              vendorId: vendorId,
              initialUrls: portfolioUrls,
              initialCoverUrl: coverPhotoUrl,
              onCoverChanged: onCoverPhotoChanged,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: saving ? null : onSave,
              icon: saving
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded),
              label: Text(saving ? AppStrings.loading : AppStrings.save),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ),
        ],
      ),
    );
  }

  static String _capacityLabel(String cat) {
    switch (cat.toLowerCase()) {
      case 'venue':    return 'Venue Capacity (max guests)';
      case 'catering': return 'Minimum Guests Required';
      case 'logistics': return 'Number of Vehicles';
      default:         return '${AppStrings.capacity} (optional)';
    }
  }

  InputDecoration _dropdownDecor() => InputDecoration(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppColors.charcoal.withOpacity(0.15))),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppColors.charcoal.withOpacity(0.15))),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.crimson)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}

// ── Category-Specific Tag Section ─────────────────────────────────────────────

class _CategoryMeta {
  final String label;
  final List<String> options;
  const _CategoryMeta({required this.label, required this.options});
}

class _CategorySpecificSection extends StatelessWidget {
  final String category;
  final List<String> selectedTags;
  final ValueChanged<String> onAddTag;
  final ValueChanged<String> onRemoveTag;

  static const _meta = <String, _CategoryMeta>{
    'venue': _CategoryMeta(
      label: '🏛 Venue Features',
      options: ['Indoor Hall', 'Outdoor Garden', 'Rooftop Space', 'Poolside',
        'AC Facility', 'Generator Backup', 'Parking', 'Stage Setup',
        'Bridal Room', 'Min 100 Guests', 'Min 200 Guests', 'Min 500 Guests'],
    ),
    'catering': _CategoryMeta(
      label: '🍽 Catering Specialties',
      options: ['Bangladeshi Cuisine', 'Chinese', 'Continental', 'BBQ Live',
        'Buffet Style', 'Halal Certified', 'Dessert Counter',
        'Mocktails Bar', 'Custom Menu', 'Home Delivery'],
    ),
    'photography': _CategoryMeta(
      label: '📷 Photography Style',
      options: ['DSLR Photography', 'Drone Shots', '4K Video', 'Cinematic Edit',
        'Same Day Highlights', 'Candid Photography', 'Traditional Poses',
        'Pre-Wedding Shoot', 'RAW Files', 'International Delivery'],
    ),
    'decor': _CategoryMeta(
      label: '✨ Decor Style',
      options: ['Floral Decor', 'LED Setup', 'Traditional Bengali', 'Modern Minimalist',
        'Bollywood Theme', 'Mandap Setup', 'Stage Backdrop',
        'Table Setting', 'Entrance Arch', 'Car Decoration'],
    ),
    'makeup': _CategoryMeta(
      label: '💄 Makeup & Styling',
      options: ['Bridal Makeup', 'Airbrush Makeup', 'HD Foundation', 'Natural Look',
        'Party Makeup', 'Trial Session', 'Hair Styling', 'Saree Draping',
        'Nail Art', 'Home Service'],
    ),
    'attire': _CategoryMeta(
      label: '💍 Attire & Jewelry',
      options: ['Gold Jewelry', 'Diamond Jewelry', 'Silver Jewelry', 'Bridal Set',
        'Custom Orders', 'Rental Available', 'Lehenga', 'Saree',
        'Sherewani', 'Indo-Western'],
    ),
    'logistics': _CategoryMeta(
      label: '🚗 Vehicle & Logistics',
      options: ['AC Vehicles', 'Flower Decorated Car', 'Bus/Microbus', 'Bride Car',
        'Guest Pickup', 'Airport Transfer', 'Outstation Service',
        'Driver Included', 'Fuel Included', 'Night Service'],
    ),
  };

  const _CategorySpecificSection({
    required this.category,
    required this.selectedTags,
    required this.onAddTag,
    required this.onRemoveTag,
  });

  /// Maps full ServiceCategories names → short key used in _meta.
  /// e.g. 'Photography & Video' → 'photography'
  static String? _shortKey(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('venue') || c.contains('hall')) return 'venue';
    if (c.contains('cater') || c.contains('food') || c.contains('cake')) return 'catering';
    if (c.contains('photo') || c.contains('video') || c.contains('cine') || c.contains('drone')) return 'photography';
    if (c.contains('decor') || c.contains('light') || c.contains('flower') ||
        c.contains('garland') || c.contains('stage') || c.contains('mandap')) return 'decor';
    if (c.contains('makeup') || c.contains('mehendi') || c.contains('henna') ||
        c.contains('beauty') || c.contains('salon')) return 'makeup';
    if (c.contains('attire') || c.contains('jewel') || c.contains('bridal') ||
        c.contains('groom') || c.contains('wear')) return 'attire';
    if (c.contains('logistic') || c.contains('transport') || c.contains('car') ||
        c.contains('dj') || c.contains('sound') || c.contains('band') ||
        c.contains('music') || c.contains('mc') || c.contains('security')) return 'logistics';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final m = _meta[_shortKey(category)];
    if (m == null) return const SizedBox.shrink();

    return _FieldSection(
      title: m.label,
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: m.options.map((opt) {
          final selected = selectedTags.contains(opt);
          return GestureDetector(
            onTap: () => selected ? onRemoveTag(opt) : onAddTag(opt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.crimson.withOpacity(0.10)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? AppColors.crimson
                      : AppColors.charcoal.withOpacity(0.15),
                  width: selected ? 1.5 : 1.0,
                ),
                boxShadow: selected ? [
                  BoxShadow(
                    color: AppColors.crimson.withOpacity(0.12),
                    blurRadius: 6, offset: const Offset(0, 2)),
                ] : null,
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (selected) ...[
                  const Icon(Icons.check_circle_rounded,
                      size: 13, color: AppColors.crimson),
                  const SizedBox(width: 4),
                ],
                Text(opt,
                    style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 12,
                        color: selected ? AppColors.crimson : AppColors.charcoal,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
              ]),
            ),
          );
        }).toList(),
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.05, end: 0);
  }
}

// ── Portfolio Upload Section ───────────────────────────────────────────────────

class _PortfolioUploadSection extends StatefulWidget {
  final String vendorId;
  final List<String> initialUrls;
  final String? initialCoverUrl;
  final ValueChanged<String?> onCoverChanged;
  const _PortfolioUploadSection({
    required this.vendorId,
    required this.initialUrls,
    required this.initialCoverUrl,
    required this.onCoverChanged,
  });

  @override
  State<_PortfolioUploadSection> createState() =>
      _PortfolioUploadSectionState();
}

class _PortfolioUploadSectionState extends State<_PortfolioUploadSection> {
  static const int _maxPhotos = 10;
  final _picker = ImagePicker();
  late List<String> _urls;
  String? _coverUrl;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _urls = List<String>.from(widget.initialUrls);
    _coverUrl = widget.initialCoverUrl;
  }

  Future<void> _setCover(String url) async {
    // Immediately save cover_photo_url to DB
    try {
      await SupabaseService.vendorProfiles
          .update({'cover_photo_url': url})
          .eq('user_id', widget.vendorId);
      setState(() => _coverUrl = url);
      widget.onCoverChanged(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('⭐ Cover photo set!'),
          backgroundColor: AppColors.freshTalent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      dev.log('[Portfolio] setCover error: $e', name: 'Utsob');
    }
  }

  Future<void> _addPhoto() async {
    if (_urls.length >= _maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Maximum $_maxPhotos photos allowed.'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      // ── Compression: resize to 1080px and apply 75% JPEG quality ──
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 75,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploading = true);

    final url = await ProfileService.uploadPortfolioImage(
      picked,
      widget.vendorId,
    );

    if (url != null) {
      final updated = [..._urls, url];
      final saved = await ProfileService.savePortfolioUrls(widget.vendorId, updated);
      if (saved && mounted) {
        setState(() => _urls = updated);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('✅ Photo uploaded!'),
          backgroundColor: AppColors.freshTalent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('❌ Upload failed. Try again.'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }

    if (mounted) setState(() => _uploading = false);
  }

  Future<void> _removePhoto(String url) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Remove photo?', style: AppTextStyles.headingLarge),
        content: Text('This will permanently delete the photo.', style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _uploading = true);
    await ProfileService.deletePortfolioImage(widget.vendorId, url, _urls);
    if (mounted) {
      setState(() {
        _urls.remove(url);
        _uploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _maxPhotos - _urls.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Count chip
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _urls.length >= _maxPhotos
                  ? AppColors.error.withOpacity(0.10)
                  : AppColors.freshTalent.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _urls.length >= _maxPhotos
                    ? AppColors.error.withOpacity(0.3)
                    : AppColors.freshTalent.withOpacity(0.3),
              ),
            ),
            child: Text(
              '${_urls.length}/$_maxPhotos  •  $remaining slot${remaining == 1 ? '' : 's'} left',
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 11,
                color: _urls.length >= _maxPhotos
                    ? AppColors.error
                    : AppColors.freshTalent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        // Photo grid
        if (_urls.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _urls.length,
            itemBuilder: (_, i) {
              final url = _urls[i];
              final isCover = url == _coverUrl;
              return Stack(
                children: [
                  // Photo
                  GestureDetector(
                    onLongPress: () => _setCover(url),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: url,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: AppColors.charcoal.withOpacity(0.08),
                              child: const Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.charcoalLight)),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.charcoal.withOpacity(0.08),
                              child: const Icon(Icons.broken_image_rounded,
                                  color: AppColors.charcoalLight),
                            ),
                          ),
                          // Cover overlay
                          if (isCover)
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppColors.gold, width: 2.5),
                                gradient: LinearGradient(
                                  begin: Alignment.bottomLeft,
                                  colors: [
                                    Colors.black.withOpacity(0.4),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Cover badge (bottom-left)
                  if (isCover)
                    Positioned(
                      bottom: 5, left: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.star_rounded, size: 10, color: Colors.white),
                          SizedBox(width: 2),
                          Text('Cover', style: TextStyle(
                              fontSize: 8, color: Colors.white, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                  // Set-as-cover hint (bottom-right, only if not cover)
                  if (!isCover)
                    Positioned(
                      bottom: 4, right: 4,
                      child: GestureDetector(
                        onTap: () => _setCover(url),
                        child: Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.star_outline_rounded,
                              size: 14, color: Colors.white70),
                        ),
                      ),
                    ),
                  // Delete button (top-right)
                  Positioned(
                    top: 4, right: 4,
                    child: GestureDetector(
                      onTap: () => _removePhoto(url),
                      child: Container(
                        width: 24, height: 24,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        const SizedBox(height: 12),
        // Add photo button
        if (_urls.length < _maxPhotos)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _uploading ? null : _addPhoto,
              icon: _uploading
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.gold))
                  : const Icon(Icons.add_photo_alternate_rounded,
                      color: AppColors.gold),
              label: Text(
                _uploading ? 'Uploading…' : 'Add Photo',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gold),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: AppColors.gold.withOpacity(0.5)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        if (_urls.length >= _maxPhotos)
          Text(
            'Maximum 10 photos reached. Delete one to add another.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.charcoalLight),
          ),
        const SizedBox(height: 4),
        Text(
          '📦 Images are auto-compressed to ~150–300 KB before upload.',
          style: AppTextStyles.bodySmall.copyWith(
              fontSize: 10, color: AppColors.charcoalLight),
        ),
      ],
    );
  }
}

// ── Packages Tab ───────────────────────────────────────────────────────────────

class _PackagesTab extends StatelessWidget {
  final List<VendorPackage> packages;
  final bool loading;
  final String vendorId;
  final VoidCallback onRefresh;
  final String category;
  const _PackagesTab({
    required this.packages, required this.loading,
    required this.vendorId, required this.onRefresh,
    required this.category});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(AppStrings.myPackages, style: AppTextStyles.headingMedium),
            Row(children: [
              // Template suggestion button
              if (VendorCategoryConfig.forCategory(category)?.packageTemplates.isNotEmpty == true)
                TextButton.icon(
                  onPressed: () => _showTemplatesSheet(context),
                  icon: const Icon(Icons.auto_fix_high_rounded, size: 15, color: AppColors.gold),
                  label: Text('Templates',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.gold, fontWeight: FontWeight.w700)),
                ),
              ElevatedButton.icon(
                onPressed: () => _showAddPackageSheet(context),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(AppStrings.addPackage),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.crimson))
              : packages.isEmpty
                  ? Center(child: GlassCard(
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(24),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Text('📦', style: TextStyle(fontSize: 36)),
                        const SizedBox(height: 10),
                        Text('No packages yet', style: AppTextStyles.headingSmall),
                        const SizedBox(height: 6),
                        Text('Add service packages with pricing so hosts can book you.',
                            style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
                      ]),
                    ))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      physics: const BouncingScrollPhysics(),
                      itemCount: packages.length,
                      itemBuilder: (_, i) => _EditablePackageCard(
                        package: packages[i],
                        onDeleted: () async {
                          await VendorPackageService.deletePackage(packages[i].id);
                          onRefresh();
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  void _showAddPackageSheet(BuildContext context, {PackageTemplate? template}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PackageFormSheet(
          vendorId: vendorId, onSaved: onRefresh, initialTemplate: template),
    );
  }

  void _showTemplatesSheet(BuildContext context) {
    final config = VendorCategoryConfig.forCategory(category);
    if (config == null || config.packageTemplates.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.charcoal.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Row(children: [
                const Text('✨', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text('Package Templates', style: AppTextStyles.headingMedium),
              ]),
              const SizedBox(height: 6),
              Text('Tap a template to pre-fill the package form.',
                  style: AppTextStyles.bodySmall),
              const SizedBox(height: 16),
              ...config.packageTemplates.map((t) => GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _showAddPackageSheet(context, template: t);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.gold.withOpacity(0.25)),
                    boxShadow: [BoxShadow(
                        color: AppColors.gold.withOpacity(0.06),
                        blurRadius: 12, offset: const Offset(0, 3))],
                  ),
                  child: Row(children: [
                    Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(t.name, style: AppTextStyles.headingSmall),
                      const SizedBox(height: 4),
                      Text(t.description,
                          style: AppTextStyles.bodySmall, maxLines: 2),
                      const SizedBox(height: 6),
                      Text(
                        t.priceType == 'per_head'
                            ? '৳${t.price} / person'
                            : t.priceType == 'per_day'
                                ? '৳${t.price} / day'
                                : '৳${t.price}',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.crimson, fontWeight: FontWeight.w700)),
                    ])),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10)),
                      child: Text('Use',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.gold, fontWeight: FontWeight.w700)),
                    ),
                  ]),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditablePackageCard extends StatelessWidget {
  final VendorPackage package;
  final VoidCallback onDeleted;
  const _EditablePackageCard({required this.package, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(package.name, style: AppTextStyles.headingSmall),
            if (package.description != null)
              Text(package.description!, style: AppTextStyles.bodySmall, maxLines: 2),
            const SizedBox(height: 4),
            Text(package.priceLabel,
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.crimson, fontWeight: FontWeight.w700)),
          ],
        )),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded,
              color: AppColors.error, size: 20),
          onPressed: onDeleted,
        ),
      ]),
    ).animate().fadeIn(duration: 280.ms);
  }
}

// ── Package Form Sheet ─────────────────────────────────────────────────────────

class _PackageFormSheet extends StatefulWidget {
  final String vendorId;
  final VoidCallback onSaved;
  final PackageTemplate? initialTemplate;
  const _PackageFormSheet({
    required this.vendorId, required this.onSaved, this.initialTemplate});

  @override
  State<_PackageFormSheet> createState() => _PackageFormSheetState();
}

class _PackageFormSheetState extends State<_PackageFormSheet> {
  final _nameCtrl  = TextEditingController();
  final _descCtrl  = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _inclCtrl  = TextEditingController();
  String _priceType = 'fixed';
  bool _isPopular  = false;
  bool _saving     = false;
  List<String> _includes = [];

  @override
  void initState() {
    super.initState();
    final t = widget.initialTemplate;
    if (t != null) {
      _nameCtrl.text  = t.name;
      _descCtrl.text  = t.description;
      _priceCtrl.text = '${t.price}';
      _priceType      = t.priceType;
      _includes       = List<String>.from(t.includes);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _descCtrl.dispose();
    _priceCtrl.dispose(); _inclCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty || _priceCtrl.text.isEmpty) return;
    setState(() => _saving = true);
    final pkg = VendorPackage(
      id: '', vendorId: widget.vendorId,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      price: int.tryParse(_priceCtrl.text) ?? 0,
      priceType: _priceType,
      includes: _includes,
      isPopular: _isPopular,
    );
    await VendorPackageService.upsertPackage(pkg);
    setState(() => _saving = false);
    widget.onSaved();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.charcoal.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Text(AppStrings.addPackage, style: AppTextStyles.headingMedium),
              const SizedBox(height: 16),
              _TextField(ctrl: _nameCtrl, hint: 'Package name', label: 'Name'),
              const SizedBox(height: 12),
              _TextField(ctrl: _descCtrl, hint: 'What does this include?',
                  label: 'Description', maxLines: 2),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _TextField(ctrl: _priceCtrl, hint: '0', label: 'Price ৳', isNum: true)),
                const SizedBox(width: 12),
                Expanded(child: DropdownButtonFormField<String>(
                  value: _priceType,
                  items: const [
                    DropdownMenuItem(value: 'fixed',     child: Text('Fixed')),
                    DropdownMenuItem(value: 'per_head',  child: Text('Per head')),
                    DropdownMenuItem(value: 'per_day',   child: Text('Per day')),
                    DropdownMenuItem(value: 'negotiable',child: Text('Negotiate')),
                  ],
                  onChanged: (v) { if (v != null) setState(() => _priceType = v); },
                  decoration: InputDecoration(
                    labelText: 'Type', filled: true, fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.charcoal.withOpacity(0.15))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.charcoal.withOpacity(0.15))),
                  ),
                )),
              ]),
              const SizedBox(height: 12),
              // Includes
              Row(children: [
                Expanded(child: _TextField(ctrl: _inclCtrl, hint: 'e.g. 500 edited photos')),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_inclCtrl.text.trim().isNotEmpty) {
                      setState(() { _includes.add(_inclCtrl.text.trim()); _inclCtrl.clear(); });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15)),
                  child: const Text('Add'),
                ),
              ]),
              if (_includes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6, runSpacing: 4,
                  children: _includes.map((it) => Chip(
                    label: Text(it, style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
                    backgroundColor: AppColors.freshTalent.withOpacity(0.10),
                    deleteIcon: const Icon(Icons.close_rounded, size: 13),
                    onDeleted: () => setState(() => _includes.remove(it)),
                  )).toList(),
                ),
              ],
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _isPopular,
                onChanged: (v) => setState(() => _isPopular = v ?? false),
                title: Text('Mark as Popular', style: AppTextStyles.bodyMedium),
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.gold,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: Text(_saving ? AppStrings.loading : AppStrings.save),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Discounts Tab ──────────────────────────────────────────────────────────────

class _DiscountsTab extends StatelessWidget {
  final List<VendorDiscount> discounts;
  final String vendorId;
  final VoidCallback onRefresh;
  const _DiscountsTab({required this.discounts, required this.vendorId, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(AppStrings.discountsOffers, style: AppTextStyles.headingMedium),
            ElevatedButton.icon(
              onPressed: () => _showAddDiscountSheet(context),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Offer'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: discounts.isEmpty
              ? Center(child: GlassCard(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('🏷️', style: TextStyle(fontSize: 36)),
                    const SizedBox(height: 10),
                    Text('No discounts yet', style: AppTextStyles.headingSmall),
                    const SizedBox(height: 6),
                    Text('Offer seasonal discounts or early-bird deals to attract more hosts.',
                        style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
                  ]),
                ))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  physics: const BouncingScrollPhysics(),
                  itemCount: discounts.length,
                  itemBuilder: (_, i) {
                    final d = discounts[i];
                    return GlassCard(
                      margin: const EdgeInsets.only(bottom: 10),
                      backgroundColor: AppColors.error.withOpacity(0.04),
                      borderColor: AppColors.error.withOpacity(0.2),
                      child: Row(children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(12)),
                          child: Center(child: Text(d.displayValue,
                              style: AppTextStyles.headingSmall.copyWith(
                                  color: AppColors.error, fontSize: 11),
                              textAlign: TextAlign.center)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d.title, style: AppTextStyles.headingSmall),
                            if (d.description != null)
                              Text(d.description!, style: AppTextStyles.bodySmall, maxLines: 1),
                          ],
                        )),
                      ]),
                    ).animate(delay: Duration(milliseconds: i * 50)).fadeIn(duration: 280.ms);
                  },
                ),
        ),
      ],
    );
  }

  void _showAddDiscountSheet(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl  = TextEditingController();
    final valCtrl   = TextEditingController();
    String dtype = 'percentage';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: StatefulBuilder(builder: (ctx, set) => Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Center(child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColors.charcoal.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('Add Discount / Offer', style: AppTextStyles.headingMedium),
            const SizedBox(height: 16),
            _TextField(ctrl: titleCtrl, label: 'Title', hint: 'e.g. Early Bird Discount'),
            const SizedBox(height: 12),
            _TextField(ctrl: descCtrl, label: 'Description (optional)', hint: 'Details...', maxLines: 2),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _TextField(ctrl: valCtrl, label: 'Value', hint: '10', isNum: true)),
              const SizedBox(width: 12),
              Expanded(child: DropdownButtonFormField<String>(
                value: dtype,
                items: const [
                  DropdownMenuItem(value: 'percentage', child: Text('Percentage %')),
                  DropdownMenuItem(value: 'flat',       child: Text('Flat ৳')),
                ],
                onChanged: (v) { if (v != null) set(() => dtype = v); },
                decoration: InputDecoration(
                  labelText: 'Type', filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.charcoal.withOpacity(0.15))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.charcoal.withOpacity(0.15))),
                ),
              )),
            ]),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (titleCtrl.text.isEmpty || valCtrl.text.isEmpty) return;
                  await SupabaseService.client.from('vendor_discounts').insert({
                    'vendor_id':     vendorId,
                    'title':         titleCtrl.text.trim(),
                    'description':   descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                    'discount_type': dtype,
                    'discount_value': int.tryParse(valCtrl.text) ?? 0,
                  });
                  onRefresh();
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: Text(AppStrings.save),
              ),
            ),
          ]),
        )),
      ),
    );
  }
}

// ── Category-Specific Structured Details Section ──────────────────────────────

class _CategoryDetailsSection extends StatefulWidget {
  final String category;
  final Map<String, dynamic> initialDetails;
  final ValueChanged<Map<String, dynamic>> onChanged;

  const _CategoryDetailsSection({
    required this.category,
    required this.initialDetails,
    required this.onChanged,
  });

  @override
  State<_CategoryDetailsSection> createState() =>
      _CategoryDetailsSectionState();
}

class _CategoryDetailsSectionState extends State<_CategoryDetailsSection> {
  final Map<String, TextEditingController> _textCtrls = {};
  final Map<String, bool> _boolVals = {};
  final Map<String, String?> _dropdownVals = {};
  final Map<String, List<String>> _multiselectVals = {};

  @override
  void initState() {
    super.initState();
    _build(widget.category, widget.initialDetails);
  }

  @override
  void didUpdateWidget(_CategoryDetailsSection old) {
    super.didUpdateWidget(old);
    if (old.category != widget.category) {
      _disposeAll();
      _build(widget.category, {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onChanged(_assembleMap());
      });
    }
  }

  void _build(String category, Map<String, dynamic> init) {
    final config = VendorCategoryConfig.forCategory(category);
    if (config == null) return;
    for (final f in config.fields) {
      switch (f.type) {
        case CatFieldType.text:
        case CatFieldType.number:
          final ctrl = TextEditingController(
              text: (init[f.key] ?? '').toString().replaceAll('null', ''));
          ctrl.addListener(_notify);
          _textCtrls[f.key] = ctrl;
          break;
        case CatFieldType.bool_:
          _boolVals[f.key] = (init[f.key] as bool?) ?? false;
          break;
        case CatFieldType.dropdown:
          _dropdownVals[f.key] = init[f.key] as String?;
          break;
        case CatFieldType.multiselect:
          final raw = init[f.key];
          List<String> sel = [];
          if (raw is List) sel = raw.cast<String>();
          _multiselectVals[f.key] = List<String>.from(sel);
          break;
      }
    }
  }

  void _disposeAll() {
    for (final c in _textCtrls.values) {
      c.removeListener(_notify);
      c.dispose();
    }
    _textCtrls.clear();
    _boolVals.clear();
    _dropdownVals.clear();
    _multiselectVals.clear();
  }

  @override
  void dispose() {
    _disposeAll();
    super.dispose();
  }

  void _notify() => widget.onChanged(_assembleMap());

  Map<String, dynamic> _assembleMap() {
    final m = <String, dynamic>{};
    _textCtrls.forEach((k, c) {
      if (c.text.trim().isNotEmpty) {
        final n = int.tryParse(c.text.trim());
        m[k] = n ?? c.text.trim();
      }
    });
    _boolVals.forEach((k, v) => m[k] = v);
    _dropdownVals.forEach((k, v) { if (v != null) m[k] = v; });
    _multiselectVals.forEach((k, v) { if (v.isNotEmpty) m[k] = v; });
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final config = VendorCategoryConfig.forCategory(widget.category);
    if (config == null) return const SizedBox.shrink();

    return _FieldSection(
      title: config.sectionTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: config.fields.map(_buildField).toList(),
      ),
    ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildField(CategoryField field) {
    switch (field.type) {
      case CatFieldType.text:
      case CatFieldType.number:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _TextField(
            ctrl: _textCtrls[field.key]!,
            hint: field.hint ?? '',
            label: field.label,
            isNum: field.type == CatFieldType.number,
          ),
        );

      case CatFieldType.bool_:
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.charcoal.withOpacity(0.12)),
          ),
          child: SwitchListTile(
            value: _boolVals[field.key] ?? false,
            activeColor: AppColors.crimson,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            title: Text(field.label, style: AppTextStyles.bodyMedium),
            onChanged: (v) {
              setState(() => _boolVals[field.key] = v);
              _notify();
            },
          ),
        );

      case CatFieldType.dropdown:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField<String>(
            value: _dropdownVals[field.key],
            items: field.options!
                .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                .toList(),
            onChanged: (v) {
              setState(() => _dropdownVals[field.key] = v);
              _notify();
            },
            decoration: InputDecoration(
              labelText: field.label,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    BorderSide(color: AppColors.charcoal.withOpacity(0.15))),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    BorderSide(color: AppColors.charcoal.withOpacity(0.15))),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.crimson)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        );

      case CatFieldType.multiselect:
        final selected = _multiselectVals[field.key] ?? [];
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(field.label, style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.charcoalLight, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: field.options!.map((opt) {
                  final isSel = selected.contains(opt);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSel) selected.remove(opt);
                        else selected.add(opt);
                      });
                      _notify();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSel
                            ? AppColors.crimson.withOpacity(0.09)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSel
                              ? AppColors.crimson
                              : AppColors.charcoal.withOpacity(0.15),
                          width: isSel ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (isSel) ...[
                          const Icon(Icons.check_circle_rounded,
                              size: 12, color: AppColors.crimson),
                          const SizedBox(width: 4),
                        ],
                        Text(opt,
                            style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 12,
                                color: isSel
                                    ? AppColors.crimson
                                    : AppColors.charcoal,
                                fontWeight: isSel
                                    ? FontWeight.w700
                                    : FontWeight.w400)),
                      ]),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
    }
  }
}

// ── Shared Widgets ─────────────────────────────────────────────────────────────

class _FieldSection extends StatelessWidget {
  final String title;
  final Widget child;
  const _FieldSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: AppTextStyles.headingSmall),
      const SizedBox(height: 8),
      child,
      const SizedBox(height: 16),
    ],
  );
}

class _TextField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final String? label;
  final int maxLines;
  final bool isNum;
  const _TextField({
    required this.ctrl, required this.hint,
    this.label, this.maxLines = 1, this.isNum = false});

  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    maxLines: maxLines,
    keyboardType: isNum ? TextInputType.number : TextInputType.multiline,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.charcoal.withOpacity(0.15))),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.charcoal.withOpacity(0.15))),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.crimson)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
  );
}

import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/app_strings.dart';
import '../../core/service_categories.dart';
import '../../models/vendor_package_model.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';
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
  bool _savingProfile = false;

  static const _cities = [
    'Dhaka', 'Chittagong', 'Sylhet', 'Rajshahi',
    'Khulna', 'Barishal', 'Cumilla', 'Mymensingh', 'Rangpur', 'Narayanganj',
  ];

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

    setState(() => _savingProfile = false);
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
              ),
              _PackagesTab(
                packages: _packages,
                loading: _loadingPkgs,
                vendorId: AuthService.currentUser?.id ?? '',
                onRefresh: _loadPackages,
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
            title: '${AppStrings.capacity} (venues only)',
            child: _TextField(ctrl: capCtrl, hint: 'e.g. 500 guests', isNum: true),
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

// ── Packages Tab ───────────────────────────────────────────────────────────────

class _PackagesTab extends StatelessWidget {
  final List<VendorPackage> packages;
  final bool loading;
  final String vendorId;
  final VoidCallback onRefresh;
  const _PackagesTab({
    required this.packages, required this.loading,
    required this.vendorId, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(AppStrings.myPackages, style: AppTextStyles.headingMedium),
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

  void _showAddPackageSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PackageFormSheet(vendorId: vendorId, onSaved: onRefresh),
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
  const _PackageFormSheet({required this.vendorId, required this.onSaved});

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

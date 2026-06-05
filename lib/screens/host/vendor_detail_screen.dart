import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/app_strings.dart';
import '../../models/vendor_package_model.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/booking_service.dart';
import '../../widgets/glass_card.dart';
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
                _BusinessInfoCard(vendor: vendor),
                const SizedBox(height: 16),
                if (vendor.packages.isNotEmpty) ...[
                  Text(AppStrings.myPackages, style: AppTextStyles.headingMedium),
                  const SizedBox(height: 10),
                  ...vendor.packages.asMap().entries.map((e) =>
                      _PackageCard(package: e.value, index: e.key)),
                  const SizedBox(height: 16),
                ],
                if (vendor.discounts.any((d) => d.isActive && !d.isExpired)) ...[
                  Text(AppStrings.discountsOffers, style: AppTextStyles.headingMedium),
                  const SizedBox(height: 10),
                  ...vendor.discounts
                      .where((d) => d.isActive && !d.isExpired)
                      .map((d) => _DiscountCard(discount: d)),
                  const SizedBox(height: 16),
                ],
                if (vendor.portfolioUrls.isNotEmpty) ...[
                  Text(AppStrings.portfolio, style: AppTextStyles.headingMedium),
                  const SizedBox(height: 10),
                  _PortfolioGrid(urls: vendor.portfolioUrls),
                  const SizedBox(height: 16),
                ],
                if (vendor.specialtyTags.isNotEmpty) ...[
                  Text(AppStrings.specialties, style: AppTextStyles.headingMedium),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 6,
                    children: vendor.specialtyTags.map((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.gold.withOpacity(0.25)),
                      ),
                      child: Text(t, style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
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
      expandedHeight: vendor.coverPhotoUrl != null ? 220 : 100,
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85), shape: BoxShape.circle),
          child: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.charcoal, size: 16),
        ),
        onPressed: () => Navigator.maybePop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: vendor.coverPhotoUrl != null
            ? Stack(fit: StackFit.expand, children: [
                Image.network(vendor.coverPhotoUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.crimson, Color(0xFF4A0018)])),
                    )),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xCC000000)])),
                ),
              ])
            : Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.crimson, Color(0xFF4A0018)]))),
        title: Text(vendor.businessName,
            style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
        titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
      ),
    );
  }
}

// ── Business Info Card ─────────────────────────────────────────────────────────

class _BusinessInfoCard extends StatelessWidget {
  final RichVendorProfile vendor;
  const _BusinessInfoCard({required this.vendor});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
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
                    Text(vendor.businessName, style: AppTextStyles.headingLarge),
                    const SizedBox(height: 4),
                    Wrap(spacing: 6, children: [
                      _Chip(vendor.category, AppColors.gold),
                      if (vendor.isVerified) _Chip('✓ Verified', AppColors.freshTalent),
                    ]),
                  ],
                ),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Row(children: [
                  const Icon(Icons.star_rounded, size: 15, color: AppColors.gold),
                  const SizedBox(width: 3),
                  Text(vendor.rating.toStringAsFixed(1),
                      style: AppTextStyles.headingSmall.copyWith(color: AppColors.gold)),
                ]),
                Text('${vendor.totalReviews} ${AppStrings.reviews}',
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
              ]),
            ],
          ),
          const SizedBox(height: 14),
          Row(children: [
            _Stat('${vendor.totalBookings}', AppStrings.bookingsCount, AppColors.crimson),
            const SizedBox(width: 20),
            _Stat('${vendor.yearsExperience}y', AppStrings.experience, AppColors.gold),
            if (vendor.capacity != null) ...[
              const SizedBox(width: 20),
              _Stat('${vendor.capacity}', AppStrings.capacity, AppColors.charcoalMid),
            ],
          ]),
          if (vendor.bio != null) ...[
            const Divider(height: 24),
            Text(vendor.bio!, style: AppTextStyles.bodyMedium.copyWith(height: 1.55)),
          ],
          if (vendor.location != null) ...[
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.location_on_rounded, size: 13, color: AppColors.charcoalLight),
              const SizedBox(width: 4),
              Text(vendor.location!,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.charcoalLight)),
            ]),
          ],
          const Divider(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(AppStrings.priceRange, style: AppTextStyles.bodySmall),
            Text(vendor.priceRangeDisplay,
                style: AppTextStyles.currencyMedium.copyWith(
                    fontSize: 16, color: AppColors.crimson)),
          ]),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06, end: 0);
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: AppTextStyles.bodySmall.copyWith(
        fontSize: 10, color: color, fontWeight: FontWeight.w600)),
  );
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _Stat(this.value, this.label, this.color);
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: AppTextStyles.headingMedium.copyWith(color: color, fontSize: 18)),
      Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
    ],
  );
}

// ── Package Card ───────────────────────────────────────────────────────────────

class _PackageCard extends StatelessWidget {
  final VendorPackage package;
  final int index;
  const _PackageCard({required this.package, required this.index});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      backgroundColor: package.isPopular ? AppColors.gold.withOpacity(0.06) : null,
      borderColor: package.isPopular ? AppColors.gold.withOpacity(0.3) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(package.name, style: AppTextStyles.headingSmall),
                  if (package.isPopular) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.gold, borderRadius: BorderRadius.circular(4)),
                      child: Text('Popular',
                          style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ]),
                if (package.description != null)
                  Text(package.description!,
                      style: AppTextStyles.bodySmall, maxLines: 2,
                      overflow: TextOverflow.ellipsis),
              ],
            )),
            Text(package.priceLabel,
                style: AppTextStyles.currencyMedium.copyWith(
                    fontSize: 15, color: AppColors.crimson)),
          ]),
          if (package.includes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 4,
              children: package.includes.map((item) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded, size: 12,
                      color: AppColors.freshTalent),
                  const SizedBox(width: 3),
                  Text(item, style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
                ],
              )).toList(),
            ),
          ],
        ],
      ),
    ).animate(delay: Duration(milliseconds: index * 60)).fadeIn(duration: 300.ms);
  }
}

// ── Discount Card ──────────────────────────────────────────────────────────────

class _DiscountCard extends StatelessWidget {
  final VendorDiscount discount;
  const _DiscountCard({required this.discount});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      backgroundColor: AppColors.error.withOpacity(0.04),
      borderColor: AppColors.error.withOpacity(0.2),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12)),
          child: Center(
            child: Text(discount.displayValue,
                style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.error, fontSize: 12),
                textAlign: TextAlign.center),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(discount.title, style: AppTextStyles.headingSmall),
            if (discount.description != null)
              Text(discount.description!,
                  style: AppTextStyles.bodySmall, maxLines: 2),
            if (discount.validUntil != null)
              Text(
                'Valid till ${discount.validUntil!.day}/${discount.validUntil!.month}/${discount.validUntil!.year}',
                style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 10, color: AppColors.charcoalLight)),
          ],
        )),
      ]),
    );
  }
}

// ── Portfolio Grid ─────────────────────────────────────────────────────────────

class _PortfolioGrid extends StatelessWidget {
  final List<String> urls;
  const _PortfolioGrid({required this.urls});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 6, mainAxisSpacing: 6),
      itemCount: urls.length.clamp(0, 9),
      itemBuilder: (_, i) => ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(urls[i], fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.overlayDark,
              child: const Icon(Icons.image_rounded, color: AppColors.charcoalLight))),
      ),
    );
  }
}

// ── Bottom Chat + Book Bar ─────────────────────────────────────────────────────

class _ChatBookingBar extends StatelessWidget {
  final RichVendorProfile vendor;
  const _ChatBookingBar({required this.vendor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20,
          MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        border: Border(top: BorderSide(color: AppColors.divider)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06),
              blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      child: Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _openChat(context),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
            label: Text(AppStrings.chat),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
              side: const BorderSide(color: AppColors.crimson),
              foregroundColor: AppColors.crimson,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _openBooking(context),
            icon: const Icon(Icons.calendar_month_rounded, size: 16),
            label: Text(AppStrings.bookNow),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ]),
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
            conversationId: convo.id, otherUserName: vendor.businessName),
          transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
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
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
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
        backgroundColor: AppColors.warning, behavior: SnackBarBehavior.floating));
      return;
    }
    final amount = int.tryParse(_amountCtrl.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please enter a valid amount.'),
        backgroundColor: AppColors.warning, behavior: SnackBarBehavior.floating));
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

    setState(() => _saving = false);
    if (!mounted) return;

    if (booking != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppStrings.bookingConfirmed),
        backgroundColor: AppColors.freshTalent, behavior: SnackBarBehavior.floating));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppStrings.errorOccurred),
        backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(AppStrings.confirmBooking, style: AppTextStyles.headingMedium),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.charcoal),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassCard(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.vendor.businessName, style: AppTextStyles.headingMedium),
                const SizedBox(height: 4),
                Text(widget.vendor.category, style: AppTextStyles.bodySmall),
              ],
            )),
            const SizedBox(height: 20),
            Text(AppStrings.eventDate, style: AppTextStyles.headingSmall),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 7)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                );
                if (picked != null) setState(() => _eventDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.crimson.withOpacity(0.3))),
                child: Row(children: [
                  const Icon(Icons.calendar_month_rounded, color: AppColors.crimson, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    _eventDate == null
                        ? 'Select event date'
                        : '${_eventDate!.day}/${_eventDate!.month}/${_eventDate!.year}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: _eventDate == null ? AppColors.charcoalLight : AppColors.charcoal)),
                ]),
              ),
            ),
            if (widget.vendor.packages.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(AppStrings.selectPackage, style: AppTextStyles.headingSmall),
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
                        ? AppColors.crimson.withOpacity(0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedPackage?.id == p.id
                          ? AppColors.crimson : AppColors.charcoal.withOpacity(0.12))),
                  child: Row(children: [
                    Icon(
                      _selectedPackage?.id == p.id
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: _selectedPackage?.id == p.id
                          ? AppColors.crimson : AppColors.charcoalLight,
                      size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(p.name, style: AppTextStyles.bodyMedium)),
                    Text(p.priceLabel,
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.crimson, fontWeight: FontWeight.w700)),
                  ]),
                ),
              )),
            ],
            const SizedBox(height: 20),
            Text(AppStrings.agreedAmount, style: AppTextStyles.headingSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: '৳ ',
                hintText: '0',
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
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Additional notes (optional)',
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
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_rounded),
                label: Text(_saving ? AppStrings.loading : AppStrings.confirmBooking),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

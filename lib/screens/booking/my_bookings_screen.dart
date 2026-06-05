import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/app_strings.dart';
import '../../models/booking_model.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/mesh_background.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<Booking> _bookings = [];
  bool _loading = true;
  String? _userId;
  bool _isVendor = false;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    final user = AuthService.currentUser;
    _userId  = user?.id;
    _isVendor = user?.role.name == 'vendor';
    _load();
    // Auto-reload every 30 seconds for hosts so they see vendor confirmations promptly
    if (!_isVendor) {
      _autoRefreshTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _load(),
      );
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (_userId == null) return;
    final bookings = _isVendor
        ? await BookingService.getVendorBookings(_userId!)
        : await BookingService.getHostBookings(_userId!);
    if (mounted) setState(() { _bookings = bookings; _loading = false; });
  }

  List<Booking> _filtered(List<BookingStatus> statuses) =>
      _bookings.where((b) => statuses.contains(b.status)).toList();

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
              title: Text(AppStrings.bookings, style: AppTextStyles.headingLarge),
              bottom: TabBar(
                controller: _tabCtrl,
                labelStyle: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700),
                unselectedLabelStyle: AppTextStyles.bodySmall,
                labelColor: AppColors.crimson,
                unselectedLabelColor: AppColors.charcoalLight,
                indicatorColor: AppColors.crimson,
                indicatorWeight: 2.5,
                tabs: const [
                  Tab(text: 'Active'),
                  Tab(text: 'Completed'),
                  Tab(text: 'Cancelled'),
                ],
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabCtrl,
            children: [
              _BookingList(
                bookings: _filtered([BookingStatus.pending, BookingStatus.confirmed]),
                loading: _loading,
                isVendor: _isVendor,
                onRefresh: _load,
              ),
              _BookingList(
                bookings: _filtered([BookingStatus.completed]),
                loading: _loading,
                isVendor: _isVendor,
                onRefresh: _load,
              ),
              _BookingList(
                bookings: _filtered([BookingStatus.cancelled]),
                loading: _loading,
                isVendor: _isVendor,
                onRefresh: _load,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final List<Booking> bookings;
  final bool loading;
  final bool isVendor;
  final Future<void> Function() onRefresh;
  const _BookingList({
    required this.bookings,
    required this.loading,
    required this.isVendor,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.crimson));
    }
    if (bookings.isEmpty) {
      return Center(
        child: GlassCard(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('📅', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text('No bookings here', style: AppTextStyles.headingMedium),
            const SizedBox(height: 6),
            Text('Your bookings will appear here.',
                style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
          ]),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.crimson,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        itemCount: bookings.length,
        itemBuilder: (_, i) => _BookingCard(
          booking: bookings[i],
          isVendor: isVendor,
          index: i,
          onAction: onRefresh,
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final bool isVendor;
  final int index;
  final Future<void> Function() onAction;
  const _BookingCard({
    required this.booking,
    required this.isVendor,
    required this.index,
    required this.onAction,
  });

  Color get _statusColor {
    switch (booking.status) {
      case BookingStatus.pending:   return AppColors.warning;
      case BookingStatus.confirmed: return AppColors.freshTalent;
      case BookingStatus.completed: return AppColors.charcoalMid;
      case BookingStatus.cancelled: return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.zero,
      borderRadius: 20,
      child: Column(
        children: [
          // Status strip
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_statusColor, _statusColor.withOpacity(0.4)]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12)),
                    child: Center(
                      child: Text(booking.status.emoji,
                          style: const TextStyle(fontSize: 22))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isVendor
                            ? booking.hostName ?? 'Host'
                            : booking.vendorBusinessName ?? booking.vendorName ?? 'Vendor',
                        style: AppTextStyles.headingSmall,
                      ),
                      Text(booking.serviceCategory,
                          style: AppTextStyles.bodySmall),
                    ],
                  )),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      '${booking.status.emoji} ${booking.status.label}',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: _statusColor, fontWeight: FontWeight.w700,
                          fontSize: 10)),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  _InfoItem(Icons.calendar_month_rounded,
                      '${booking.eventDate.day}/${booking.eventDate.month}/${booking.eventDate.year}'),
                  const SizedBox(width: 14),
                  _InfoItem(Icons.payments_rounded,
                      '৳${booking.agreedAmount}'),
                ]),
                if (booking.notes != null) ...[
                  const SizedBox(height: 8),
                  Text(booking.notes!,
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.charcoalLight),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                // Vendor actions on pending bookings
                if (isVendor && booking.status == BookingStatus.pending &&
                    !booking.vendorConfirmed) ...[
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _respond(context, false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.error),
                          foregroundColor: AppColors.error,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10)),
                        child: Text(AppStrings.reject,
                            style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _respond(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.freshTalent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10)),
                        child: Text(AppStrings.approve,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.white)),
                      ),
                    ),
                  ]),
                ],
                // Payment recording button for confirmed bookings
                if (!isVendor && booking.status == BookingStatus.confirmed) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showPaymentDialog(context),
                      icon: const Icon(Icons.payments_rounded, size: 16),
                      label: Text(AppStrings.recordPayment),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.gold),
                        foregroundColor: AppColors.gold,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: index * 60))
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.06, end: 0);
  }

  Future<void> _respond(BuildContext context, bool accept) async {
    final ok = await BookingService.vendorRespond(
        bookingId: booking.id, accept: accept);
    if (ok) onAction();
  }

  Future<void> _showPaymentDialog(BuildContext context) async {
    final methods = ['cash', 'bkash', 'nagad', 'rocket', 'bank', 'other'];
    String? method = 'cash';
    final ctrl = TextEditingController(text: '${booking.agreedAmount}');
    final refCtrl = TextEditingController();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppStrings.recordPayment),
        content: StatefulBuilder(builder: (ctx, set) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: ctrl, keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Amount paid (৳)', prefixText: '৳ ')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: method,
              items: methods.map((m) =>
                  DropdownMenuItem(value: m, child: Text(m.toUpperCase()))).toList(),
              onChanged: (v) => set(() => method = v),
              decoration: const InputDecoration(labelText: 'Payment method'),
            ),
            const SizedBox(height: 12),
            TextField(controller: refCtrl,
                decoration: const InputDecoration(
                    labelText: 'Transaction ref (optional)')),
          ],
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppStrings.cancel)),
          ElevatedButton(
            onPressed: () async {
              final amt = int.tryParse(ctrl.text.replaceAll(',', '')) ?? 0;
              await BookingService.recordPayment(
                bookingId: booking.id,
                paidAmount: amt,
                totalAmount: booking.agreedAmount,
                paymentMethod: method ?? 'cash',
                transactionRef: refCtrl.text.isEmpty ? null : refCtrl.text,
              );
              Navigator.pop(context, true);
            },
            child: Text(AppStrings.save),
          ),
        ],
      ),
    );
    if (submitted == true) onAction();
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoItem(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 13, color: AppColors.charcoalLight),
    const SizedBox(width: 4),
    Text(text, style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
  ]);
}

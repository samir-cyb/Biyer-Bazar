import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../services/admin_service.dart';
import '../../widgets/glass_card.dart';

class AdminTransactions extends StatefulWidget {
  const AdminTransactions({super.key});
  @override
  State<AdminTransactions> createState() => _AdminTransactionsState();
}

class _AdminTransactionsState extends State<AdminTransactions>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _fmt = NumberFormat('#,##,###', 'en_IN');
  Map<String, List<Map<String, dynamic>>> _byStatus = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    dev.log('[AdminTx] Loading transactions', name: 'BiyerBajar');
    setState(() => _loading = true);
    final all = await AdminService.getAllTransactions();
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final tx in all) {
      final s = tx['status'] as String? ?? 'pending';
      grouped.putIfAbsent(s, () => []).add(tx);
    }
    setState(() { _byStatus = grouped; _loading = false; });
    dev.log('[AdminTx] Loaded ${all.length} transactions', name: 'BiyerBajar');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.charcoal,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Transactions & Escrow', style: AppTextStyles.headingLarge.copyWith(color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white), onPressed: _load),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppColors.gold,
          isScrollable: true,
          tabs: const [
            Tab(text: '⏳ Pending'),
            Tab(text: '💳 Deposit Paid'),
            Tab(text: '✅ Completed'),
            Tab(text: '↩️ Refunded'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.crimson))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _TxList(txns: _byStatus['pending'] ?? [], fmt: _fmt, onRefresh: _load),
                _TxList(txns: _byStatus['deposit_paid'] ?? [], fmt: _fmt, onRefresh: _load),
                _TxList(txns: _byStatus['completed'] ?? [], fmt: _fmt, onRefresh: _load),
                _TxList(txns: _byStatus['refunded'] ?? [], fmt: _fmt, onRefresh: _load),
              ],
            ),
    );
  }
}

class _TxList extends StatelessWidget {
  final List<Map<String, dynamic>> txns;
  final NumberFormat fmt;
  final VoidCallback onRefresh;
  const _TxList({required this.txns, required this.fmt, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (txns.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('💳', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 12),
        Text('No transactions here', style: AppTextStyles.bodyMedium),
      ]));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: txns.length,
      itemBuilder: (_, i) => _TxCard(tx: txns[i], fmt: fmt, index: i, onRefresh: onRefresh),
    );
  }
}

class _TxCard extends StatelessWidget {
  final Map<String, dynamic> tx;
  final NumberFormat fmt;
  final int index;
  final VoidCallback onRefresh;
  const _TxCard({required this.tx, required this.fmt, required this.index, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final status  = tx['status'] as String? ?? 'pending';
    final amount  = tx['amount'] as int? ?? 0;
    final deposit = tx['deposit_amount'] as int? ?? 0;
    final commission = tx['commission_amt'] as int? ?? 0;
    final method  = tx['payment_method'] as String? ?? 'bkash';
    final ref     = tx['payment_ref'] as String? ?? '—';
    final txId    = tx['id'] as String;

    final statusColor = status == 'completed' ? AppColors.success
        : status == 'deposit_paid' ? AppColors.freshTalent
        : status == 'refunded' ? AppColors.error
        : AppColors.warning;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Booking #${txId.substring(0, 8).toUpperCase()}',
                style: AppTextStyles.headingSmall),
            Text('৳ ${fmt.format(amount)} total  ·  Deposit: ৳ ${fmt.format(deposit)}',
                style: AppTextStyles.bodySmall),
            Text('Method: ${method.toUpperCase()}  ·  Ref: $ref',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.charcoalLight)),
            if (commission > 0)
              Text('Commission: ৳ ${fmt.format(commission)} (${tx['commission_rate']}%)',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.gold)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: statusColor.withOpacity(0.3))),
            child: Text(status.replaceAll('_', ' ').toUpperCase(),
                style: AppTextStyles.bodySmall.copyWith(color: statusColor,
                    fontWeight: FontWeight.w700, fontSize: 9)),
          ),
        ]),
        if (status == 'pending' || status == 'deposit_paid') ...[
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: [
            if (status == 'pending')
              _ActionBtn('Mark Deposit Paid 💳', AppColors.freshTalent, () => _markPaid(context, txId)),
            if (status == 'deposit_paid')
              _ActionBtn('Complete & Pay Vendor ✅', AppColors.success, () => _complete(context, txId)),
            _ActionBtn('Refund ↩️', AppColors.error, () => _refund(context, txId)),
          ]),
        ],
      ]),
    ).animate(delay: Duration(milliseconds: index * 30)).fadeIn(duration: 220.ms);
  }

  void _markPaid(BuildContext context, String txId) async {
    final refCtrl = TextEditingController();
    final ref = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Enter Payment Reference'),
        content: TextField(
          controller: refCtrl,
          decoration: const InputDecoration(
            labelText: 'bKash/Nagad Transaction ID',
            hintText: 'e.g. 8N7A2B3C4D',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, refCtrl.text.trim()),
              child: const Text('Confirm')),
        ],
      ),
    );
    if (ref != null && ref.isNotEmpty) {
      await AdminService.updateTransactionStatus(txId, 'deposit_paid', paymentRef: ref);
      onRefresh();
    }
  }

  void _complete(BuildContext context, String txId) async {
    await AdminService.updateTransactionStatus(txId, 'completed');
    onRefresh();
  }

  void _refund(BuildContext context, String txId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Issue Refund?'),
        content: const Text('This will mark the transaction as refunded.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Refund'),
          ),
        ],
      ),
    ) ?? false;
    if (confirm) {
      await AdminService.updateTransactionStatus(txId, 'refunded');
      onRefresh();
    }
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(this.label, this.color, this.onTap);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3))),
        child: Text(label, style: AppTextStyles.bodySmall.copyWith(color: color, fontWeight: FontWeight.w600, fontSize: 11)),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_colors.dart';
import '../core/app_text_styles.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

/// Drop-in bell icon with live unread badge.
/// Add to any AppBar actions:
///   actions: [const NotificationBell(), ...]
class NotificationBell extends StatefulWidget {
  final Color iconColor;
  const NotificationBell({super.key, this.iconColor = Colors.white});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell>
    with SingleTickerProviderStateMixin {
  int _unread = 0;
  List<AppNotification> _notifications = [];
  RealtimeChannel? _channel;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = Tween(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));
    _load();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final u = AuthService.currentUser;
    if (u == null) return;
    final notifs = await NotificationService.getMyNotifications(u.id);
    final unread = notifs.where((n) => !n.isRead).length;
    if (mounted) setState(() { _notifications = notifs; _unread = unread; });
  }

  void _subscribeRealtime() {
    final u = AuthService.currentUser;
    if (u == null) return;
    _channel = NotificationService.subscribeToMyNotifications(u.id, (n) {
      if (!mounted) return;
      setState(() {
        _notifications.insert(0, n);
        _unread++;
      });
      // Shake the bell
      _shakeCtrl.forward(from: 0).then((_) => _shakeCtrl.reverse());
      // Show popup toast
      NotificationToast.show(context, n);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openSheet(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedBuilder(
              animation: _shakeAnim,
              builder: (_, child) => Transform.rotate(
                angle: _shakeAnim.value,
                child: child,
              ),
              child: Icon(
                _unread > 0
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_outlined,
                color: widget.iconColor,
                size: 24,
              ),
            ),
            if (_unread > 0)
              Positioned(
                right: -4, top: -2,
                child: Container(
                  width: 18, height: 18,
                  decoration: const BoxDecoration(
                    color: AppColors.gold, shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      _unread > 9 ? '9+' : '$_unread',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 9,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openSheet(BuildContext context) async {
    final u = AuthService.currentUser;
    if (u != null) {
      await NotificationService.markAllRead(u.id);
      if (mounted) setState(() => _unread = 0);
    }
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotificationSheet(notifications: _notifications),
    );
  }
}

// ── Notification Bottom Sheet ──────────────────────────────────────────────────

class _NotificationSheet extends StatelessWidget {
  final List<AppNotification> notifications;
  const _NotificationSheet({required this.notifications});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFAFAED),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                const Text('🔔', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text('Notifications', style: AppTextStyles.headingMedium),
                const Spacer(),
                Text('${notifications.length} total',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.charcoalLight)),
              ]),
            ),
            const SizedBox(height: 8),
            const Divider(),
            Expanded(
              child: notifications.isEmpty
                  ? Center(child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔕', style: TextStyle(fontSize: 44)),
                        const SizedBox(height: 12),
                        Text('No notifications yet',
                            style: AppTextStyles.headingSmall),
                        const SizedBox(height: 6),
                        Text('You\'ll be notified about bookings, approvals, and more.',
                            style: AppTextStyles.bodySmall,
                            textAlign: TextAlign.center),
                      ],
                    ))
                  : ListView.separated(
                      controller: ctrl,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) =>
                          _NotificationTile(notification: notifications[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  const _NotificationTile({required this.notification});

  Color get _color {
    switch (notification.type) {
      case 'approval': return AppColors.freshTalent;
      case 'rejection': return AppColors.error;
      case 'booking': return AppColors.gold;
      case 'chat': return AppColors.crimson;
      default: return AppColors.charcoalMid;
    }
  }

  String get _emoji {
    switch (notification.type) {
      case 'approval': return '✅';
      case 'rejection': return '❌';
      case 'booking': return '📅';
      case 'chat': return '💬';
      default: return '🔔';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: notification.isRead
            ? Colors.white
            : _color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: notification.isRead
              ? Colors.black.withOpacity(0.06)
              : _color.withOpacity(0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: _color.withOpacity(0.12), shape: BoxShape.circle),
            child: Center(
              child: Text(_emoji, style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(notification.title,
                      style: AppTextStyles.headingSmall.copyWith(fontSize: 13))),
                  if (!notification.isRead)
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                          color: _color, shape: BoxShape.circle)),
                ]),
                const SizedBox(height: 4),
                Text(notification.body,
                    style: AppTextStyles.bodySmall.copyWith(height: 1.4)),
                const SizedBox(height: 6),
                Text(
                  _formatTime(notification.createdAt),
                  style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 10, color: AppColors.charcoalLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ── Popup Toast ────────────────────────────────────────────────────────────────

class NotificationToast {
  static OverlayEntry? _current;

  static void show(BuildContext context, AppNotification n) {
    _current?.remove();
    _current = null;

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _ToastWidget(
        notification: n,
        onDismiss: () {
          entry.remove();
          if (_current == entry) _current = null;
        },
      ),
    );

    _current = entry;
    overlay.insert(entry);

    // Auto-dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (entry.mounted) {
        entry.remove();
        if (_current == entry) _current = null;
      }
    });
  }
}

class _ToastWidget extends StatefulWidget {
  final AppNotification notification;
  final VoidCallback onDismiss;
  const _ToastWidget({required this.notification, required this.onDismiss});

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _slide = Tween<Offset>(
        begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _color {
    switch (widget.notification.type) {
      case 'approval': return AppColors.freshTalent;
      case 'rejection': return AppColors.error;
      case 'booking': return AppColors.gold;
      case 'chat': return AppColors.crimson;
      default: return AppColors.charcoalMid;
    }
  }

  String get _emoji {
    switch (widget.notification.type) {
      case 'approval': return '✅';
      case 'rejection': return '❌';
      case 'booking': return '📅';
      case 'chat': return '💬';
      default: return '🔔';
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Positioned(
      top: topPad + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: GestureDetector(
            onTap: widget.onDismiss,
            onVerticalDragUpdate: (d) {
              if (d.primaryDelta != null && d.primaryDelta! < -5) {
                widget.onDismiss();
              }
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _color.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: _color.withOpacity(0.20),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                      spreadRadius: -4,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: _color.withOpacity(0.12),
                        shape: BoxShape.circle),
                      child: Center(
                        child: Text(_emoji,
                            style: const TextStyle(fontSize: 20))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(widget.notification.title,
                              style: AppTextStyles.headingSmall
                                  .copyWith(fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(widget.notification.body,
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.charcoalLight),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: widget.onDismiss,
                      child: Icon(Icons.close_rounded,
                          size: 18, color: AppColors.charcoalLight),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

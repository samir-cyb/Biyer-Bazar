import 'dart:developer' as dev;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map m) => AppNotification(
    id:        m['id'] as String,
    userId:    m['user_id'] as String,
    title:     m['title'] as String? ?? '',
    body:      m['body'] as String? ?? '',
    type:      m['type'] as String? ?? 'info',
    isRead:    (m['is_read'] as bool?) ?? false,
    createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
  );
}

class NotificationService {
  static final _db = SupabaseService.client;

  // ── Send a notification to a user ────────────────────────────────────────────
  static Future<void> send({
    required String toUserId,
    required String title,
    required String body,
    String type = 'info',
    Map<String, dynamic> data = const {},
  }) async {
    try {
      await _db.from('notifications').insert({
        'user_id':    toUserId,
        'title':      title,
        'body':       body,
        'type':       type,
        'data':       data,
        'is_read':    false,
      });
      dev.log('[Notification] Sent to $toUserId: $title', name: 'BiyerBajar');
    } catch (e) {
      dev.log('[Notification] Send error: $e', name: 'BiyerBajar');
    }
  }

  // ── Get all notifications for current user ────────────────────────────────────
  static Future<List<AppNotification>> getMyNotifications(String userId) async {
    try {
      final rows = await _db
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);
      return (rows as List).map((r) => AppNotification.fromMap(r)).toList();
    } catch (e) {
      dev.log('[Notification] fetch error: $e', name: 'BiyerBajar');
      return [];
    }
  }

  // ── Unread count ──────────────────────────────────────────────────────────────
  static Future<int> unreadCount(String userId) async {
    try {
      final rows = await _db
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('is_read', false);
      return (rows as List).length;
    } catch (e) {
      return 0;
    }
  }

  // ── Mark all read ─────────────────────────────────────────────────────────────
  static Future<void> markAllRead(String userId) async {
    try {
      await _db
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      dev.log('[Notification] markAllRead error: $e', name: 'BiyerBajar');
    }
  }

  // ── Realtime subscription ─────────────────────────────────────────────────────
  static RealtimeChannel subscribeToMyNotifications(
    String userId,
    void Function(AppNotification) onNew,
  ) {
    return _db
        .channel('notifications:$userId')
        .onPostgresChanges(
          event:  PostgresChangeEvent.insert,
          schema: 'public',
          table:  'notifications',
          filter: PostgresChangeFilter(
            type:   PostgresChangeFilterType.eq,
            column: 'user_id',
            value:  userId,
          ),
          callback: (payload) {
            try {
              final n = AppNotification.fromMap(payload.newRecord);
              onNew(n);
            } catch (e) {
              dev.log('[Notification] Realtime parse error: $e', name: 'BiyerBajar');
            }
          },
        )
        .subscribe();
  }
}

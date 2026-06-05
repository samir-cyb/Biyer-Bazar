import 'dart:developer' as dev;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_model.dart';
import 'notification_service.dart';
import 'supabase_service.dart';

class ChatService {
  static final _db = SupabaseService.client;

  // ── Get or create a conversation between host and vendor ─────────────────────
  static Future<ChatConversation> getOrCreateConversation({
    required String hostId,
    required String vendorId,
  }) async {
    try {
      // Try to find existing
      final existing = await _db
          .from('chat_conversations')
          .select()
          .eq('host_id', hostId)
          .eq('vendor_id', vendorId)
          .maybeSingle();

      if (existing != null) {
        return ChatConversation.fromMap(existing);
      }

      // Create new
      final created = await _db
          .from('chat_conversations')
          .insert({'host_id': hostId, 'vendor_id': vendorId})
          .select()
          .single();

      return ChatConversation.fromMap(created);
    } catch (e) {
      dev.log('[Chat] getOrCreateConversation error: $e', name: 'BiyerBajar');
      rethrow;
    }
  }

  // ── List conversations for a user (host or vendor) ───────────────────────────
  static Future<List<ChatConversation>> getMyConversations(String userId) async {
    try {
      // Step 1: fetch conversations with participant profiles only (avoid broken 3-way join)
      final rows = await _db
          .from('chat_conversations')
          .select('''
            *,
            host_profile:profiles!chat_conversations_host_id_fkey(name, profile_picture_url),
            vendor_profile:profiles!chat_conversations_vendor_id_fkey(name, profile_picture_url)
          ''')
          .or('host_id.eq.$userId,vendor_id.eq.$userId')
          .eq('is_archived', false)
          .order('last_message_at', ascending: false);

      final convList = rows as List;

      // Step 2: fetch business names for all vendor IDs in one query
      final vendorIds = convList.map((r) => r['vendor_id'] as String).toSet().toList();
      Map<String, String> vendorBizMap = {};
      if (vendorIds.isNotEmpty) {
        try {
          final vpRows = await _db
              .from('vendor_profiles')
              .select('user_id, business_name')
              .inFilter('user_id', vendorIds);
          for (final vp in vpRows as List) {
            final uid = vp['user_id'] as String?;
            final biz = vp['business_name'] as String?;
            if (uid != null && biz != null) vendorBizMap[uid] = biz;
          }
        } catch (_) { /* business names are optional */ }
      }

      return convList.map((r) {
        final isHost   = r['host_id'] == userId;
        final other    = isHost ? r['vendor_profile'] : r['host_profile'];
        final vendorId = r['vendor_id'] as String? ?? '';
        // Only show vendor business name to the HOST — vendor should see host's name
        final bizName  = isHost ? vendorBizMap[vendorId] : null;
        final enriched = Map<String, dynamic>.from(r as Map)
          ..['other_profile']       = other
          ..['vendor_profile_data'] = bizName != null ? {'business_name': bizName} : null;
        return ChatConversation.fromMap(enriched);
      }).toList();
    } catch (e) {
      dev.log('[Chat] getMyConversations error: $e', name: 'BiyerBajar');
      return [];
    }
  }

  // ── Fetch messages for a conversation ────────────────────────────────────────
  static Future<List<ChatMessage>> getMessages(
    String conversationId, {
    int limit = 50,
    String? before, // message id for pagination
  }) async {
    try {
      var query = _db
          .from('chat_messages')
          .select()
          .eq('conversation_id', conversationId)
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .limit(limit);

      final rows = await query;
      final msgs = (rows as List)
          .map((r) => ChatMessage.fromMap(r))
          .toList();
      return msgs.reversed.toList(); // oldest first for display
    } catch (e) {
      dev.log('[Chat] getMessages error: $e', name: 'BiyerBajar');
      return [];
    }
  }

  // ── Send a message ────────────────────────────────────────────────────────────
  static Future<ChatMessage?> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
  }) async {
    // Check for forbidden content
    final (flagged, reason) = ChatMessage.checkContent(content);

    try {
      final row = await _db.from('chat_messages').insert({
        'conversation_id': conversationId,
        'sender_id':       senderId,
        'content':         flagged ? '[Message blocked]' : content,
        'is_flagged':      flagged,
        'flag_reason':     reason,
      }).select().single();

      // Update conversation preview
      await _db.from('chat_conversations').update({
        'last_message_at':      DateTime.now().toIso8601String(),
        'last_message_preview': flagged ? '[Blocked]' : content.substring(
            0, content.length > 60 ? 60 : content.length),
      }).eq('id', conversationId);

      // Notify the OTHER participant (not the sender)
      if (!flagged) {
        try {
          final convo = await _db
              .from('chat_conversations')
              .select('host_id, vendor_id')
              .eq('id', conversationId)
              .single();
          final hostId   = convo['host_id'] as String;
          final vendorId = convo['vendor_id'] as String;
          final recipientId = senderId == hostId ? vendorId : hostId;

          // Get sender name
          final senderProfile = await _db
              .from('profiles')
              .select('name, role')
              .eq('id', senderId)
              .maybeSingle();
          final senderName = senderProfile?['name'] as String? ?? 'Someone';
          final preview    = content.length > 40
              ? '${content.substring(0, 40)}…'
              : content;

          await NotificationService.send(
            toUserId: recipientId,
            title: '💬 New message from $senderName',
            body: preview,
            type: 'message',
            data: {'conversation_id': conversationId},
          );
        } catch (e) {
          dev.log('[Chat] notify recipient error: $e', name: 'BiyerBajar');
        }
      }

      if (flagged) {
        return ChatMessage.fromMap(row);
      }
      return ChatMessage.fromMap(row);
    } catch (e) {
      dev.log('[Chat] sendMessage error: $e', name: 'BiyerBajar');
      return null;
    }
  }

  // ── Get all admin user IDs ────────────────────────────────────────────────────
  static Future<Set<String>> getAdminIds() async {
    try {
      final rows = await _db
          .from('profiles')
          .select('id')
          .eq('role', 'admin');
      return (rows as List).map((r) => r['id'] as String).toSet();
    } catch (e) {
      return {};
    }
  }

  // ── Mark messages as read ─────────────────────────────────────────────────────
  static Future<void> markRead({
    required String conversationId,
    required String readerUserId,
  }) async {
    try {
      await _db
          .from('chat_messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_id', readerUserId)
          .eq('is_read', false);
    } catch (e) {
      dev.log('[Chat] markRead error: $e', name: 'BiyerBajar');
    }
  }

  // ── Realtime subscription for new messages ────────────────────────────────────
  static RealtimeChannel subscribeToMessages(
    String conversationId,
    void Function(ChatMessage) onNew,
  ) {
    return _db
        .channel('messages:$conversationId')
        .onPostgresChanges(
          event:  PostgresChangeEvent.insert,
          schema: 'public',
          table:  'chat_messages',
          filter: PostgresChangeFilter(
            type:   PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value:  conversationId,
          ),
          callback: (payload) {
            try {
              final msg = ChatMessage.fromMap(payload.newRecord);
              onNew(msg);
            } catch (e) {
              dev.log('[Chat] Realtime parse error: $e', name: 'BiyerBajar');
            }
          },
        )
        .subscribe();
  }

  // ── Admin: get user-to-user conversations (host↔vendor, excludes support) ───
  static Future<List<ChatConversation>> adminGetAllConversations({
    String? adminId,
  }) async {
    try {
      var query = _db
          .from('chat_conversations')
          .select('''
            *,
            host_profile:profiles!chat_conversations_host_id_fkey(name),
            vendor_profile:profiles!chat_conversations_vendor_id_fkey(name)
          ''')
          .order('last_message_at', ascending: false)
          .limit(100);

      final rows = await query;
      final all = rows as List;

      // Filter client-side: exclude conversations where admin is vendor_id (those are support)
      final userChats = adminId != null
          ? all.where((r) => r['vendor_id'] != adminId).toList()
          : all;

      return userChats.map((r) {
        final enriched = Map<String, dynamic>.from(r as Map);
        // Leave both host_profile and vendor_profile for the model to pick up
        return ChatConversation.fromMap(enriched);
      }).toList();
    } catch (e) {
      dev.log('[Chat] adminGetAll error: $e', name: 'BiyerBajar');
      return [];
    }
  }

  // ── Support chat: get or create between user and admin ───────────────────────
  static Future<ChatConversation?> getOrCreateSupportConversation(
      String userId) async {
    try {
      // Find admin user ID
      final adminRows = await _db
          .from('profiles')
          .select('id')
          .eq('role', 'admin')
          .limit(1);
      if ((adminRows as List).isEmpty) return null;
      final adminId = adminRows.first['id'] as String;

      // Check existing support conversation (user as host_id, admin as vendor_id)
      final existing = await _db
          .from('chat_conversations')
          .select()
          .eq('host_id', userId)
          .eq('vendor_id', adminId)
          .maybeSingle();

      if (existing != null) return ChatConversation.fromMap(existing);

      // Create new support conversation
      final created = await _db
          .from('chat_conversations')
          .insert({
            'host_id':    userId,
            'vendor_id':  adminId,
          })
          .select()
          .single();
      return ChatConversation.fromMap(created);
    } catch (e) {
      dev.log('[Chat] getOrCreateSupportConversation error: $e', name: 'BiyerBajar');
      return null;
    }
  }

  // ── Admin: get support (help) conversations ───────────────────────────────────
  static Future<List<ChatConversation>> adminGetSupportConversations(
      String adminId) async {
    try {
      final rows = await _db
          .from('chat_conversations')
          .select('''
            *,
            host_profile:profiles!chat_conversations_host_id_fkey(name, role)
          ''')
          .eq('vendor_id', adminId)
          .order('last_message_at', ascending: false);
      return (rows as List).map((r) {
        final enriched = Map<String, dynamic>.from(r as Map)
          ..['other_profile'] = r['host_profile'];
        return ChatConversation.fromMap(enriched);
      }).toList();
    } catch (e) {
      dev.log('[Chat] adminGetSupport error: $e', name: 'BiyerBajar');
      return [];
    }
  }

  // ── Admin: get flagged messages ───────────────────────────────────────────────
  static Future<List<ChatMessage>> adminGetFlaggedMessages() async {
    try {
      final rows = await _db
          .from('chat_messages')
          .select()
          .eq('is_flagged', true)
          .order('created_at', ascending: false)
          .limit(100);
      return (rows as List).map((r) => ChatMessage.fromMap(r)).toList();
    } catch (e) {
      dev.log('[Chat] adminFlagged error: $e', name: 'BiyerBajar');
      return [];
    }
  }
}

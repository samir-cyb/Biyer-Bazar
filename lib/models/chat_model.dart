// ── Chat Models ───────────────────────────────────────────────────────────────

class ChatConversation {
  final String id;
  final String hostId;
  final String vendorId;
  final String? bookingId;
  final DateTime lastMessageAt;
  final String? lastMessagePreview;
  final int hostUnreadCount;
  final int vendorUnreadCount;
  final bool isArchived;
  final DateTime createdAt;

  // Joined fields (populated from profiles join)
  final String? otherUserName;
  final String? otherUserAvatar;
  final String? otherUserBusiness; // vendor's business name

  // Admin-view fields: explicit names for both sides
  final String? hostProfileName;
  final String? vendorProfileName;

  const ChatConversation({
    required this.id,
    required this.hostId,
    required this.vendorId,
    this.bookingId,
    required this.lastMessageAt,
    this.lastMessagePreview,
    this.hostUnreadCount = 0,
    this.vendorUnreadCount = 0,
    this.isArchived = false,
    required this.createdAt,
    this.otherUserName,
    this.otherUserAvatar,
    this.otherUserBusiness,
    this.hostProfileName,
    this.vendorProfileName,
  });

  int unreadCountFor(String userId) {
    if (userId == hostId) return hostUnreadCount;
    if (userId == vendorId) return vendorUnreadCount;
    return 0;
  }

  factory ChatConversation.fromMap(Map<dynamic, dynamic> m) {
    // Support joined profile data
    final other      = m['other_profile'] as Map?;
    final vp         = m['vendor_profile_data'] as Map?;
    final hostProf   = m['host_profile'] as Map?;
    final vendorProf = m['vendor_profile'] as Map?;
    return ChatConversation(
      id:                  m['id'] as String,
      hostId:              m['host_id'] as String,
      vendorId:            m['vendor_id'] as String,
      bookingId:           m['booking_id'] as String?,
      lastMessageAt:       DateTime.tryParse(m['last_message_at'] as String? ?? '') ?? DateTime.now(),
      lastMessagePreview:  m['last_message_preview'] as String?,
      hostUnreadCount:     (m['host_unread_count'] as int?) ?? 0,
      vendorUnreadCount:   (m['vendor_unread_count'] as int?) ?? 0,
      isArchived:          (m['is_archived'] as bool?) ?? false,
      createdAt:           DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
      otherUserName:       other?['name'] as String?,
      otherUserAvatar:     other?['profile_picture_url'] as String?,
      otherUserBusiness:   vp?['business_name'] as String?,
      // Admin-view: grab both sides if available
      hostProfileName:     (hostProf?['name'] ?? other?['name']) as String?,
      vendorProfileName:   (vendorProf?['name']) as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'host_id':   hostId,
    'vendor_id': vendorId,
  };
}

// ─────────────────────────────────────────────────────────────────────────────

enum MessageStatus { sending, sent, read, failed }

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final bool isFlagged;
  final String? flagReason;
  final bool isDeleted;
  final bool isRead;
  final DateTime createdAt;

  // UI-only — not from DB
  final MessageStatus status;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.isFlagged = false,
    this.flagReason,
    this.isDeleted = false,
    this.isRead = false,
    required this.createdAt,
    this.status = MessageStatus.sent,
  });

  bool get isVisible => !isDeleted && !isFlagged;

  factory ChatMessage.fromMap(Map<dynamic, dynamic> m) => ChatMessage(
    id:             m['id'] as String,
    conversationId: m['conversation_id'] as String,
    senderId:       m['sender_id'] as String,
    content:        m['content'] as String? ?? '',
    isFlagged:      (m['is_flagged'] as bool?) ?? false,
    flagReason:     m['flag_reason'] as String?,
    isDeleted:      (m['is_deleted'] as bool?) ?? false,
    isRead:         (m['is_read'] as bool?) ?? false,
    createdAt:      DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'conversation_id': conversationId,
    'sender_id':       senderId,
    'content':         content,
    'is_flagged':      isFlagged,
    'flag_reason':     flagReason,
  };

  /// Checks content for links and phone numbers.
  /// Returns ('flagged', 'reason') or (null, null).
  static (bool, String?) checkContent(String text) {
    final linkPattern = RegExp(
      r'(https?://|www\.|\.com|\.net|\.org|\.io|bit\.ly|t\.me|wa\.me)',
      caseSensitive: false,
    );
    final phonePattern = RegExp(
      r'(\+?880|01[3-9])\d{8,9}|\b\d{10,11}\b',
    );
    if (linkPattern.hasMatch(text)) return (true, 'link');
    if (phonePattern.hasMatch(text)) return (true, 'phone');
    return (false, null);
  }
}

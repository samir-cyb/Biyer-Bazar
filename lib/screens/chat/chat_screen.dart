import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/app_strings.dart';
import '../../models/chat_model.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../widgets/notification_bell.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserName;
  /// Pass the set of admin user-IDs so their bubbles render differently.
  final Set<String> adminUserIds;
  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserName,
    this.adminUserIds = const {},
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl     = TextEditingController();
  final _scrollCtrl  = ScrollController();
  final _focusNode   = FocusNode();
  List<ChatMessage> _messages = [];
  bool _loading     = true;
  bool _sending     = false;
  bool _showBlocked = false;
  RealtimeChannel? _channel;
  Timer? _pollTimer;
  String? _currentUserId;
  String? _lastMessageId;
  // All admin user IDs — populated on init so their bubbles are highlighted
  Set<String> _adminUserIds = {};

  @override
  void initState() {
    super.initState();
    _currentUserId = AuthService.currentUser?.id;
    // Seed with any IDs already known (e.g. passed from admin monitor)
    _adminUserIds = Set.of(widget.adminUserIds);
    _loadMessages();
    _subscribeRealtime();
    _fetchAdminIds();
  }

  Future<void> _fetchAdminIds() async {
    final ids = await ChatService.getAdminIds();
    if (mounted && ids.isNotEmpty) {
      setState(() => _adminUserIds = {..._adminUserIds, ...ids});
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _pollTimer?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final msgs = await ChatService.getMessages(widget.conversationId);
    if (mounted) {
      setState(() {
        _messages = msgs;
        _loading  = false;
        _lastMessageId = msgs.isNotEmpty ? msgs.last.id : null;
      });
    }
    _markRead();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _subscribeRealtime() {
    // Primary: Supabase Realtime (requires supabase_enable_realtime.sql to be run)
    _channel = ChatService.subscribeToMessages(widget.conversationId, (msg) {
      if (!mounted) return;
      // Skip if we already have this message (real or optimistic)
      if (_messages.any((m) => m.id == msg.id)) return;
      // Skip messages we sent — _sendMessage handles replacing optimistic with real
      if (msg.senderId == _currentUserId && _sending) return;
      setState(() => _messages.add(msg));
      _scrollToBottom(animated: true);
      _markRead();
    });

    // Fallback: poll every 3 seconds in case realtime is not enabled
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _pollNewMessages());
  }

  Future<void> _pollNewMessages() async {
    if (!mounted || _sending) return;
    final msgs = await ChatService.getMessages(widget.conversationId);
    if (!mounted) return;

    // Collect IDs of real (non-optimistic) messages already shown
    final existingIds = _messages
        .where((m) => !m.id.startsWith('temp_'))
        .map((m) => m.id)
        .toSet();

    // Only add messages we haven't seen yet
    final genuinelyNew = msgs.where((m) => !existingIds.contains(m.id)).toList();
    if (genuinelyNew.isNotEmpty) {
      setState(() => _messages.addAll(genuinelyNew));
      _scrollToBottom(animated: true);
      _markRead();
    }
  }

  void _markRead() {
    if (_currentUserId == null) return;
    ChatService.markRead(
      conversationId: widget.conversationId,
      readerUserId: _currentUserId!,
    );
  }

  void _scrollToBottom({bool animated = false}) {
    if (!_scrollCtrl.hasClients) return;
    if (animated) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending || _currentUserId == null) return;

    // Check for blocked content client-side first for immediate feedback
    final (flagged, reason) = ChatMessage.checkContent(text);
    if (flagged) {
      setState(() => _showBlocked = true);
      _msgCtrl.clear();
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showBlocked = false);
      });
      return;
    }

    _msgCtrl.clear();
    setState(() => _sending = true);

    // Optimistic UI: add message immediately
    final optimistic = ChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: widget.conversationId,
      senderId: _currentUserId!,
      content: text,
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
    );
    setState(() => _messages.add(optimistic));
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollToBottom(animated: true));

    final sent = await ChatService.sendMessage(
      conversationId: widget.conversationId,
      senderId: _currentUserId!,
      content: text,
    );

    if (mounted) {
      setState(() {
        _sending = false;
        if (sent != null) {
          // Remove any duplicate added by realtime before we could replace optimistic
          _messages.removeWhere((m) => m.id == sent.id);
        }
        final idx = _messages.indexWhere((m) => m.id == optimistic.id);
        if (idx != -1 && sent != null) {
          _messages[idx] = sent;
        } else if (sent != null) {
          // Optimistic was already removed (e.g. by poll), just append
          _messages.add(sent);
        } else if (sent == null) {
          _messages.removeWhere((m) => m.id == optimistic.id);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Could not send message. You may not have permission to write in this conversation.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Blocked warning banner
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _showBlocked
                ? Container(
                    width: double.infinity,
                    color: AppColors.error.withOpacity(0.10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(children: [
                      const Icon(Icons.block_rounded,
                          color: AppColors.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(AppStrings.messageFlagged,
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.error)),
                      ),
                    ]),
                  )
                : const SizedBox.shrink(),
          ),
          // Messages
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.crimson))
                : _messages.isEmpty
                    ? _EmptyChat(name: widget.otherUserName)
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        physics: const BouncingScrollPhysics(),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final msg  = _messages[i];
                          final prev = i > 0 ? _messages[i - 1] : null;
                          final isMe    = msg.senderId == _currentUserId;
                          final isAdmin = _adminUserIds.contains(msg.senderId);
                          final showDate = prev == null ||
                              !_sameDay(prev.createdAt, msg.createdAt);
                          return Column(
                            children: [
                              if (showDate) _DateDivider(dt: msg.createdAt),
                              _MessageBubble(
                                  message: msg,
                                  isMe: isMe,
                                  isAdmin: isAdmin,
                                  index: i),
                            ],
                          );
                        },
                      ),
          ),
          // Input bar
          _InputBar(
            controller: _msgCtrl,
            focusNode: _focusNode,
            sending: _sending,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded,
            color: AppColors.charcoal, size: 20),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [AppColors.gold, AppColors.crimson]),
          ),
          child: Center(
            child: Text(
              widget.otherUserName.isNotEmpty
                  ? widget.otherUserName[0].toUpperCase()
                  : '?',
              style: AppTextStyles.headingSmall
                  .copyWith(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.otherUserName,
                  style: AppTextStyles.headingSmall.copyWith(fontSize: 14),
                  overflow: TextOverflow.ellipsis),
              Text(AppStrings.chat,
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.charcoalLight, fontSize: 10)),
            ],
          ),
        ),
      ]),
      actions: const [
        NotificationBell(iconColor: AppColors.charcoal),
        SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.divider),
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) {
    final bdA = a.toUtc().add(const Duration(hours: 6));
    final bdB = b.toUtc().add(const Duration(hours: 6));
    return bdA.year == bdB.year && bdA.month == bdB.month && bdA.day == bdB.day;
  }
}

// ── Message Bubble ─────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool isAdmin;
  final int index;
  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.index,
    this.isAdmin = false,
  });

  // Admin messages use a distinct teal/purple colour so they stand out
  static const Color _adminColor = Color(0xFF6C63FF);

  @override
  Widget build(BuildContext context) {
    final isFlagged = message.isFlagged;

    Color bubbleColor;
    Color textColor;
    if (isFlagged) {
      bubbleColor = AppColors.error.withOpacity(0.10);
      textColor = AppColors.error;
    } else if (isAdmin && isMe) {
      bubbleColor = _adminColor;
      textColor = Colors.white;
    } else if (isAdmin && !isMe) {
      bubbleColor = _adminColor.withOpacity(0.12);
      textColor = _adminColor;
    } else if (isMe) {
      bubbleColor = AppColors.crimson;
      textColor = Colors.white;
    } else {
      bubbleColor = Colors.white;
      textColor = AppColors.charcoal;
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Admin label badge (shown above the bubble for non-self admin msgs)
            if (isAdmin && !isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 3, left: 4),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.admin_panel_settings_rounded,
                      size: 11, color: _adminColor),
                  const SizedBox(width: 3),
                  Text('Admin',
                      style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 9,
                          color: _adminColor,
                          fontWeight: FontWeight.w700)),
                ]),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                border: isAdmin && !isMe
                    ? Border.all(color: _adminColor.withOpacity(0.3), width: 1)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isFlagged
                  ? Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.block_rounded,
                          size: 13, color: AppColors.error),
                      const SizedBox(width: 5),
                      Text(
                        'Message blocked',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.error,
                            fontStyle: FontStyle.italic),
                      ),
                    ])
                  : Text(
                      message.content,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: textColor,
                        height: 1.4,
                      ),
                    ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.createdAt),
                  style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 9, color: AppColors.charcoalLight),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.status == MessageStatus.sending
                        ? Icons.access_time_rounded
                        : Icons.done_all_rounded,
                    size: 11,
                    color: message.status == MessageStatus.sending
                        ? AppColors.charcoalLight
                        : AppColors.freshTalent,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: (index % 8) * 30))
        .fadeIn(duration: 200.ms)
        .slideY(begin: 0.05, end: 0);
  }

  String _formatTime(DateTime dt) {
    // Convert UTC → Bangladesh Standard Time (UTC+6)
    final bd = dt.toUtc().add(const Duration(hours: 6));
    final h  = bd.hour.toString().padLeft(2, '0');
    final m  = bd.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ── Date Divider ───────────────────────────────────────────────────────────────

class _DateDivider extends StatelessWidget {
  final DateTime dt;
  const _DateDivider({required this.dt});

  @override
  Widget build(BuildContext context) {
    // Convert both timestamps to BD time (UTC+6) for accurate date labels
    final now  = DateTime.now().toUtc().add(const Duration(hours: 6));
    final bdDt = dt.toUtc().add(const Duration(hours: 6));
    final label = now.year == bdDt.year && now.month == bdDt.month && now.day == bdDt.day
        ? AppStrings.today
        : now.difference(bdDt).inDays == 1
            ? AppStrings.yesterday
            : '${bdDt.day}/${bdDt.month}/${bdDt.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        Expanded(child: Divider(color: AppColors.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(label,
              style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 10, color: AppColors.charcoalLight)),
        ),
        Expanded(child: Divider(color: AppColors.divider)),
      ]),
    );
  }
}

// ── Empty Chat ─────────────────────────────────────────────────────────────────

class _EmptyChat extends StatelessWidget {
  final String name;
  const _EmptyChat({required this.name});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('💬', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('Say hi to $name!',
              style: AppTextStyles.headingMedium),
          const SizedBox(height: 6),
          Text(
            'This is the start of your conversation.\n'
            'Note: links and phone numbers are not allowed.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.charcoalLight),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

// ── Input Bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final VoidCallback onSend;
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12, offset: const Offset(0, -3)),
        ],
      ),
      child: Row(children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.charcoal.withOpacity(0.10)),
            ),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              maxLines: 4,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: AppStrings.typeMessage,
                hintStyle: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.charcoalLight),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: sending ? null : onSend,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: sending
                  ? AppColors.crimson.withOpacity(0.5)
                  : AppColors.crimson,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.crimson.withOpacity(0.30),
                  blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: sending
                ? const Center(
                    child: SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white)))
                : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }
}

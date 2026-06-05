import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/app_strings.dart';
import '../../models/chat_model.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/mesh_background.dart';
import '../../widgets/notification_bell.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<ChatConversation> _convos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = AuthService.currentUser;
    if (user == null) return;
    final convos = await ChatService.getMyConversations(user.id);
    if (mounted) setState(() { _convos = convos; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StaticMeshBackground(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppColors.crimson,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverAppBar(
                floating: true,
                snap: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Text(AppStrings.messages, style: AppTextStyles.headingLarge),
                actions: const [
                  NotificationBell(iconColor: AppColors.charcoal),
                  SizedBox(width: 8),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (_loading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(60),
                          child: CircularProgressIndicator(color: AppColors.crimson),
                        ),
                      )
                    else if (_convos.isEmpty)
                      _EmptyState()
                    else
                      ..._convos.asMap().entries.map((e) => _ConversationTile(
                        convo: e.value,
                        index: e.key,
                        onTap: () async {
                          await Navigator.push(context, PageRouteBuilder(
                            pageBuilder: (_, __, ___) => ChatScreen(
                              conversationId: e.value.id,
                              otherUserName: e.value.otherUserBusiness
                                  ?? e.value.otherUserName
                                  ?? 'Chat',
                            ),
                            transitionsBuilder: (_, a, __, c) =>
                                FadeTransition(opacity: a, child: c),
                          ));
                          _load();
                        },
                      )),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ChatConversation convo;
  final int index;
  final VoidCallback onTap;
  const _ConversationTile({
    required this.convo, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final unread = user != null ? convo.unreadCountFor(user.id) : 0;
    final otherName = convo.otherUserBusiness ?? convo.otherUserName ?? 'Unknown';
    final initials = otherName.isNotEmpty
        ? otherName.substring(0, 1).toUpperCase()
        : '?';

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.gold, AppColors.crimson]),
              ),
              child: Center(
                child: Text(initials,
                    style: AppTextStyles.headingSmall.copyWith(
                        color: Colors.white, fontSize: 18)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(otherName, style: AppTextStyles.headingSmall),
                  const SizedBox(height: 3),
                  Text(
                    convo.lastMessagePreview ?? AppStrings.startChat,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
                      color: unread > 0 ? AppColors.charcoal : AppColors.charcoalLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(convo.lastMessageAt),
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                ),
                if (unread > 0) ...[
                  const SizedBox(height: 5),
                  Container(
                    width: 20, height: 20,
                    decoration: const BoxDecoration(
                        color: AppColors.crimson, shape: BoxShape.circle),
                    child: Center(
                      child: Text('$unread',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 60))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.05, end: 0);
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    if (diff.inDays == 1) return AppStrings.yesterday;
    return '${dt.day}/${dt.month}';
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.all(32),
    child: Column(children: [
      const Text('💬', style: TextStyle(fontSize: 44)),
      const SizedBox(height: 14),
      Text(AppStrings.noMessages, style: AppTextStyles.headingMedium),
      const SizedBox(height: 6),
      Text(
        'Browse vendors and tap "Chat" on a vendor profile to start a conversation.',
        style: AppTextStyles.bodySmall,
        textAlign: TextAlign.center,
      ),
    ]),
  ).animate(delay: 200.ms).fadeIn(duration: 400.ms);
}

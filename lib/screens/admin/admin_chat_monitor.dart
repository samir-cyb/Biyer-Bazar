import 'dart:async';
import 'dart:developer' as dev;
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
import '../chat/chat_screen.dart';

class AdminChatMonitorScreen extends StatefulWidget {
  const AdminChatMonitorScreen({super.key});

  @override
  State<AdminChatMonitorScreen> createState() => _AdminChatMonitorScreenState();
}

class _AdminChatMonitorScreenState extends State<AdminChatMonitorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<ChatConversation> _allConvos     = [];
  List<ChatConversation> _supportConvos = [];
  List<ChatMessage> _flaggedMsgs        = [];
  bool _loading = true;
  String? _adminId;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _adminId = AuthService.currentUser?.id;
    _tabCtrl = TabController(length: 3, vsync: this);
    _load();
    // Auto-reload every 15 seconds
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _load(),
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final adminId = _adminId ?? '';
      final results = await Future.wait([
        ChatService.adminGetAllConversations(adminId: adminId),
        ChatService.adminGetSupportConversations(adminId),
        ChatService.adminGetFlaggedMessages(),
      ]);
      if (mounted) {
        setState(() {
          _allConvos     = results[0] as List<ChatConversation>;
          _supportConvos = results[1] as List<ChatConversation>;
          _flaggedMsgs   = results[2] as List<ChatMessage>;
          _loading       = false;
        });
      }
    } catch (e) {
      dev.log('[Admin] chatMonitor load error: $e', name: 'BiyerBajar');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminIdSet = _adminId != null ? {_adminId!} : <String>{};

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StaticMeshBackground(
        child: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.background,
              elevation: 0,
              title: Text(AppStrings.chatMonitor, style: AppTextStyles.headingLarge),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.charcoal),
                  onPressed: _load,
                ),
              ],
              bottom: TabBar(
                controller: _tabCtrl,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: AppColors.crimson,
                unselectedLabelColor: AppColors.charcoalLight,
                indicatorColor: AppColors.crimson,
                indicatorWeight: 2.5,
                labelStyle: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700),
                unselectedLabelStyle: AppTextStyles.bodySmall,
                tabs: [
                  Tab(text: '💬 User Chats (${_allConvos.length})'),
                  Tab(text: '🆘 Help (${_supportConvos.length})'),
                  Tab(text: '🚨 Flagged (${_flaggedMsgs.length})'),
                ],
              ),
            ),
          ],
          body: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.crimson))
              : TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _AllConversationsTab(convos: _allConvos, adminIdSet: adminIdSet),
                    _SupportConversationsTab(convos: _supportConvos, adminIdSet: adminIdSet),
                    _FlaggedMessagesTab(messages: _flaggedMsgs),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── All Conversations Tab ──────────────────────────────────────────────────────

class _AllConversationsTab extends StatelessWidget {
  final List<ChatConversation> convos;
  final Set<String> adminIdSet;
  const _AllConversationsTab({required this.convos, required this.adminIdSet});

  @override
  Widget build(BuildContext context) {
    if (convos.isEmpty) {
      return Center(child: Text('No conversations yet',
          style: AppTextStyles.bodyMedium));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      itemCount: convos.length,
      itemBuilder: (_, i) {
        final c = convos[i];
        final hostName   = c.hostProfileName   ?? 'Host ${c.hostId.substring(0, 6)}…';
        final vendorName = c.vendorProfileName ?? 'Vendor ${c.vendorId.substring(0, 6)}…';
        final chatTitle  = '$hostName ↔ $vendorName';
        return GestureDetector(
          onTap: () => Navigator.push(context, PageRouteBuilder(
            pageBuilder: (_, __, ___) => ChatScreen(
              conversationId: c.id,
              otherUserName: chatTitle,
              adminUserIds: adminIdSet,
            ),
            transitionsBuilder: (_, a, __, c2) =>
                FadeTransition(opacity: a, child: c2),
          )),
          child: GlassCard(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppColors.charcoal.withOpacity(0.08),
                  shape: BoxShape.circle),
                child: const Center(
                    child: Icon(Icons.chat_rounded,
                        color: AppColors.charcoalMid, size: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.person_rounded, size: 11,
                        color: AppColors.charcoalMid),
                    const SizedBox(width: 3),
                    Flexible(child: Text(hostName,
                        style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w700, fontSize: 12),
                        overflow: TextOverflow.ellipsis)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text('↔',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.charcoalLight, fontSize: 11)),
                    ),
                    const Icon(Icons.storefront_rounded, size: 11,
                        color: AppColors.gold),
                    const SizedBox(width: 3),
                    Flexible(child: Text(vendorName,
                        style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w700, fontSize: 12,
                            color: AppColors.gold),
                        overflow: TextOverflow.ellipsis)),
                  ]),
                  if (c.lastMessagePreview != null) ...[
                    const SizedBox(height: 3),
                    Text(c.lastMessagePreview!,
                        style: AppTextStyles.bodySmall,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ],
              )),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.charcoalLight, size: 18),
            ]),
          ),
        )
            .animate(delay: Duration(milliseconds: i * 40))
            .fadeIn(duration: 250.ms);
      },
    );
  }
}

// ── Support / Help Conversations Tab ──────────────────────────────────────────

class _SupportConversationsTab extends StatelessWidget {
  final List<ChatConversation> convos;
  final Set<String> adminIdSet;
  const _SupportConversationsTab({required this.convos, required this.adminIdSet});

  @override
  Widget build(BuildContext context) {
    if (convos.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🆘', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 12),
        Text('No support requests yet', style: AppTextStyles.headingMedium),
        const SizedBox(height: 6),
        Text('Users can contact you via the Help button on their profile.',
            style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      itemCount: convos.length,
      itemBuilder: (_, i) {
        final c = convos[i];
        final userName = c.otherUserName ?? 'User ${c.hostId.substring(0, 6)}…';
        return GestureDetector(
          onTap: () => Navigator.push(context, PageRouteBuilder(
            pageBuilder: (_, __, ___) => ChatScreen(
              conversationId: c.id,
              otherUserName: userName,
              adminUserIds: adminIdSet,
            ),
            transitionsBuilder: (_, a, __, c2) =>
                FadeTransition(opacity: a, child: c2),
          )),
          child: GlassCard(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            backgroundColor: const Color(0xFF6C63FF).withOpacity(0.05),
            borderColor: const Color(0xFF6C63FF).withOpacity(0.2),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.1),
                  shape: BoxShape.circle),
                child: const Center(
                    child: Icon(Icons.support_agent_rounded,
                        color: Color(0xFF6C63FF), size: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(userName,
                      style: AppTextStyles.headingSmall.copyWith(fontSize: 13)),
                  if (c.lastMessagePreview != null) ...[
                    const SizedBox(height: 2),
                    Text(c.lastMessagePreview!,
                        style: AppTextStyles.bodySmall,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ] else
                    Text('New support request',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: const Color(0xFF6C63FF))),
                ],
              )),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.charcoalLight, size: 18),
            ]),
          ),
        )
            .animate(delay: Duration(milliseconds: i * 40))
            .fadeIn(duration: 250.ms);
      },
    );
  }
}

// ── Flagged Messages Tab ───────────────────────────────────────────────────────

class _FlaggedMessagesTab extends StatelessWidget {
  final List<ChatMessage> messages;
  const _FlaggedMessagesTab({required this.messages});

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('✅', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 12),
        Text('No flagged messages', style: AppTextStyles.headingMedium),
        const SizedBox(height: 6),
        Text('All chats are clean.', style: AppTextStyles.bodySmall),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      itemCount: messages.length,
      itemBuilder: (_, i) {
        final msg = messages[i];
        return GlassCard(
          margin: const EdgeInsets.only(bottom: 10),
          backgroundColor: AppColors.error.withOpacity(0.04),
          borderColor: AppColors.error.withOpacity(0.2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.block_rounded, color: AppColors.error, size: 16),
                const SizedBox(width: 6),
                Expanded(child: Text(
                  'From: ${msg.senderId.substring(0, 12)}…',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                )),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6)),
                  child: Text(msg.flagReason ?? 'unknown',
                      style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 9, color: AppColors.error,
                          fontWeight: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 8),
              Text(msg.content,
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.charcoalLight,
                      fontStyle: FontStyle.italic)),
              const SizedBox(height: 4),
              Text(
                '${msg.createdAt.day}/${msg.createdAt.month}/${msg.createdAt.year} '
                '${msg.createdAt.hour}:${msg.createdAt.minute.toString().padLeft(2, '0')}',
                style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 9, color: AppColors.charcoalLight),
              ),
            ],
          ),
        )
            .animate(delay: Duration(milliseconds: i * 40))
            .fadeIn(duration: 250.ms);
      },
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/auth_service.dart';
import '../../../core/services/chat_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_extensions.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  late final ChatService _chatService;
  List<Map<String, dynamic>> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    final token = await widget.authService.getToken ?? '';
    _chatService = ChatService(authToken: token);

    _chatService.onNewMessage = (msg) {
      _loadConversations();
    };

    _chatService.connect();
    await _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      final res = await _chatService.listConversations();
      final data = res['data'] as List? ?? [];
      if (!mounted) return;
      setState(() {
        _conversations = data.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _chatService.disconnect();
    super.dispose();
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return DateFormat.Hm().format(date.toLocal());
    if (diff.inDays < 7) return DateFormat.E().format(date.toLocal());
    return DateFormat.MMMd().format(date.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: AppColors.bgDark,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 64, color: context.textSecondaryColor),
                      const SizedBox(height: 16),
                      Text(
                        'No conversations yet',
                        style: TextStyle(color: context.textSecondaryColor),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start a conversation from a user\'s profile',
                        style: TextStyle(
                          color: context.textSecondaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  child: ListView.builder(
                    itemCount: _conversations.length,
                    itemBuilder: (ctx, i) =>
                        _ConversationTile(
                          conversation: _conversations[i],
                          formatTime: _formatTime,
                          onTap: () => _openChat(_conversations[i]),
                        ),
                  ),
                ),
    );
  }

  void _openChat(Map<String, dynamic> conversation) {
    final participants =
        (conversation['participants'] as List?)?.cast<Map<String, dynamic>>() ??
            [];
    final otherName =
        participants.isNotEmpty ? participants.first['name'] ?? 'Chat' : 'Chat';
    final otherAvatar =
        participants.isNotEmpty ? participants.first['avatarUrl'] : null;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          authService: widget.authService,
          conversationId: conversation['id'] as String,
          title: (conversation['groupName'] ?? otherName).toString(),
          avatarUrl: (conversation['groupAvatarUrl'] ?? otherAvatar)?.toString(),
        ),
      ),
    ).then((_) => _loadConversations());
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.formatTime,
    required this.onTap,
  });

  final Map<String, dynamic> conversation;
  final String Function(String?) formatTime;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final participants =
        (conversation['participants'] as List?)?.cast<Map<String, dynamic>>() ??
            [];
    final name = conversation['groupName'] ??
        (participants.isNotEmpty
            ? participants.first['name'] ?? 'Unknown'
            : 'Unknown');
    final avatarUrl = conversation['groupAvatarUrl'] ??
        (participants.isNotEmpty ? participants.first['avatarUrl'] : null);
    final preview = conversation['lastMessagePreview'] ?? '';
    final time = formatTime(conversation['lastMessageAt']?.toString());
    final unread = (conversation['unreadCount'] ?? 0) as int;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: AppColors.primaryPurple.withValues(alpha: 0.3),
        backgroundImage:
            avatarUrl != null ? CachedNetworkImageProvider(avatarUrl.toString()) : null,
        child: avatarUrl == null
            ? Text(
                name.toString().isNotEmpty ? name.toString()[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w600),
              )
            : null,
      ),
      title: Text(
        name.toString(),
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        preview.toString(),
        style: TextStyle(
          color: unread > 0
              ? AppColors.textPrimary.withValues(alpha: 0.8)
              : AppColors.textSecondary,
          fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.w400,
          fontSize: 13,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            time,
            style: TextStyle(
              color: unread > 0
                  ? AppColors.primaryPurple
                  : AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          if (unread > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                unread > 99 ? '99+' : '$unread',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

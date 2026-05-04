import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/auth_service.dart';
import '../../../core/services/chat_service.dart';
import '../../theme/app_colors.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.authService,
    required this.conversationId,
    required this.title,
    this.avatarUrl,
  });

  final AuthService authService;
  final String conversationId;
  final String title;
  final String? avatarUrl;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatService _chatService;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _showEmoji = false;
  Map<String, dynamic>? _replyTo;
  String? _myUserId;

  // Typing
  String? _typingUser;
  Timer? _typingTimer;
  Timer? _sendTypingTimer;
  bool _iAmTyping = false;

  @override
  void initState() {
    super.initState();
    _myUserId = AuthService.currentUserId;
    _initChat();
  }

  Future<void> _initChat() async {
    final token = await widget.authService.getToken ?? '';
    _chatService = ChatService(authToken: token);

    _chatService.onNewMessage = (msg) {
      if (msg['conversationId'] == widget.conversationId) {
        setState(() => _messages.add(msg));
        _scrollToBottom();
        _chatService.markReadWs(conversationId: widget.conversationId);
      }
    };

    _chatService.onTyping = (data) {
      if (data['conversationId'] == widget.conversationId &&
          data['userId'] != _myUserId) {
        setState(() => _typingUser = data['isTyping'] == true
            ? (data['userId']?.toString() ?? '')
            : null);
        _typingTimer?.cancel();
        _typingTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _typingUser = null);
        });
      }
    };

    _chatService.onReactionUpdated = (data) {
      _loadMessages();
    };

    _chatService.connect();
    await _loadMessages();
    _chatService.markReadWs(conversationId: widget.conversationId);
  }

  Future<void> _loadMessages() async {
    try {
      final res = await _chatService.listMessages(
        conversationId: widget.conversationId,
      );
      final data = res['data'] as List? ?? [];
      if (!mounted) return;
      setState(() {
        _messages = data.cast<Map<String, dynamic>>();
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _chatService.sendMessageWs(
      conversationId: widget.conversationId,
      content: text,
      replyToId: _replyTo?['id']?.toString(),
    );

    _controller.clear();
    setState(() {
      _replyTo = null;
      _showEmoji = false;
      _iAmTyping = false;
    });
    _chatService.sendTyping(
        conversationId: widget.conversationId, isTyping: false);
  }

  void _onTextChanged(String text) {
    if (text.isNotEmpty && !_iAmTyping) {
      _iAmTyping = true;
      _chatService.sendTyping(
          conversationId: widget.conversationId, isTyping: true);
    }
    _sendTypingTimer?.cancel();
    _sendTypingTimer = Timer(const Duration(seconds: 2), () {
      if (_iAmTyping) {
        _iAmTyping = false;
        _chatService.sendTyping(
            conversationId: widget.conversationId, isTyping: false);
      }
    });
  }

  void _toggleEmoji() {
    setState(() {
      _showEmoji = !_showEmoji;
      if (_showEmoji) {
        _focusNode.unfocus();
      } else {
        _focusNode.requestFocus();
      }
    });
  }

  void _reactToMessage(String messageId, String emoji) async {
    try {
      await _chatService.toggleReaction(messageId: messageId, emoji: emoji);
      await _loadMessages();
    } catch (_) {}
  }

  @override
  void dispose() {
    _chatService.disconnect();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingTimer?.cancel();
    _sendTypingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor:
                  AppColors.primaryPurple.withValues(alpha: 0.3),
              backgroundImage: widget.avatarUrl != null
                  ? CachedNetworkImageProvider(widget.avatarUrl!)
                  : null,
              child: widget.avatarUrl == null
                  ? Text(
                      widget.title.isNotEmpty
                          ? widget.title[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 14),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_typingUser != null)
                    const Text(
                      'typing...',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.chainCyan,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'Say hello!',
                          style:
                              TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (ctx, i) => _MessageBubble(
                          message: _messages[i],
                          isMine: _messages[i]['isMine'] == true,
                          myUserId: _myUserId,
                          onReply: () =>
                              setState(() => _replyTo = _messages[i]),
                          onReact: (emoji) => _reactToMessage(
                            _messages[i]['id'].toString(),
                            emoji,
                          ),
                        ),
                      ),
          ),

          // Reply preview
          if (_replyTo != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.border,
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 32,
                    color: AppColors.primaryPurple,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _replyTo!['sender']?['name']?.toString() ??
                              'Unknown',
                          style: const TextStyle(
                            color: AppColors.primaryPurple,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _replyTo!['content']?.toString() ?? '',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _replyTo = null),
                    icon: const Icon(Icons.close, size: 18),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),

          // Input bar
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.bgDark,
              border: Border(
                top: BorderSide(color: AppColors.border),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    onPressed: _toggleEmoji,
                    icon: Icon(
                      _showEmoji
                          ? Icons.keyboard
                          : Icons.emoji_emotions_outlined,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      onChanged: _onTextChanged,
                      onTap: () {
                        if (_showEmoji) {
                          setState(() => _showEmoji = false);
                        }
                      },
                      style:
                          const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Message...',
                        hintStyle:
                            TextStyle(color: AppColors.textSecondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.border,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _send,
                      icon: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Emoji picker
          if (_showEmoji)
            SizedBox(
              height: 250,
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  _controller.text += emoji.emoji;
                  _controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: _controller.text.length),
                  );
                },
                config: Config(
                  height: 250,
                  emojiViewConfig: EmojiViewConfig(
                    backgroundColor: AppColors.bgDark,
                    columns: 7,
                    emojiSizeMax: 28,
                  ),
                  categoryViewConfig: const CategoryViewConfig(
                    backgroundColor: AppColors.bgDark,
                    indicatorColor: AppColors.primaryPurple,
                    iconColorSelected: AppColors.primaryPurple,
                    iconColor: AppColors.textSecondary,
                  ),
                  searchViewConfig: SearchViewConfig(
                    backgroundColor: AppColors.bgDark,
                    buttonIconColor: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
    this.myUserId,
    required this.onReply,
    required this.onReact,
  });

  final Map<String, dynamic> message;
  final bool isMine;
  final String? myUserId;
  final VoidCallback onReply;
  final void Function(String emoji) onReact;

  @override
  Widget build(BuildContext context) {
    final isDeleted = message['isDeleted'] == true;
    final content = message['content']?.toString() ?? '';
    final sender = message['sender'] as Map<String, dynamic>?;
    final replyTo = message['replyTo'] as Map<String, dynamic>?;
    final reactions =
        message['reactions'] as Map<String, dynamic>? ?? {};
    final isEdited = message['isEdited'] == true;
    final createdAt = message['createdAt']?.toString() ?? '';

    final time = DateTime.tryParse(createdAt);
    final timeStr =
        time != null ? DateFormat.Hm().format(time.toLocal()) : '';

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showActions(context),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDeleted
                ? AppColors.border.withValues(alpha: 0.5)
                : isMine
                    ? AppColors.primaryPurple.withValues(alpha: 0.85)
                    : AppColors.border,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMine ? 16 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMine && sender != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    sender['name']?.toString() ?? '',
                    style: TextStyle(
                      color: AppColors.chainCyan,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              // Reply preview
              if (replyTo != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      left: BorderSide(
                          color: AppColors.primaryPurple, width: 2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        replyTo['senderName']?.toString() ?? '',
                        style: TextStyle(
                          color: AppColors.primaryPurple,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        replyTo['content']?.toString() ?? '',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

              // Content
              if (isDeleted)
                Text(
                  'This message was deleted',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                  ),
                )
              else if (message['imageUrl'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: message['imageUrl'].toString(),
                    width: 200,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Text(
                  content,
                  style: TextStyle(
                    color: isMine ? Colors.white : AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),

              // Time + edited
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isEdited)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        'edited',
                        style: TextStyle(
                          color: isMine
                              ? Colors.white60
                              : AppColors.textSecondary,
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  Text(
                    timeStr,
                    style: TextStyle(
                      color:
                          isMine ? Colors.white60 : AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),

              // Reactions
              if (reactions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(
                    spacing: 4,
                    children: reactions.entries.map((entry) {
                      final emoji = entry.key;
                      final users = (entry.value as List?) ?? [];
                      return GestureDetector(
                        onTap: () => onReact(emoji),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$emoji ${users.length}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick reactions row
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['❤️', '😂', '😮', '😢', '👍', '🔥'].map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      onReact(emoji);
                    },
                    child: Text(emoji, style: const TextStyle(fontSize: 28)),
                  );
                }).toList(),
              ),
            ),
            const Divider(color: AppColors.border, height: 1),
            ListTile(
              leading: const Icon(Icons.reply, color: AppColors.textPrimary),
              title: const Text('Reply',
                  style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                onReply();
              },
            ),
            if (isMine)
              ListTile(
                leading: const Icon(Icons.copy, color: AppColors.textPrimary),
                title: const Text('Copy',
                    style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }
}

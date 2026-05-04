import 'package:dio/dio.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../api_client.dart';
import '../app_config.dart';

class ChatService {
  ChatService({required this.authToken});

  final String authToken;
  io.Socket? _socket;

  // Callbacks
  void Function(Map<String, dynamic>)? onNewMessage;
  void Function(Map<String, dynamic>)? onTyping;
  void Function(Map<String, dynamic>)? onReactionUpdated;
  void Function(Map<String, dynamic>)? onMarkedRead;
  void Function()? onConnected;
  void Function()? onDisconnected;

  // ─── WebSocket ──────────────────────────────────────────────────

  void connect() {
    final baseUrl = AppConfig.apiBaseUrl;
    _socket = io.io(
      '$baseUrl/chat',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': authToken})
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket!.onConnect((_) => onConnected?.call());
    _socket!.onDisconnect((_) => onDisconnected?.call());

    _socket!.on('new_message', (data) {
      if (data is Map<String, dynamic>) {
        onNewMessage?.call(data);
      }
    });

    _socket!.on('user_typing', (data) {
      if (data is Map<String, dynamic>) {
        onTyping?.call(data);
      }
    });

    _socket!.on('reaction_updated', (data) {
      if (data is Map<String, dynamic>) {
        onReactionUpdated?.call(data);
      }
    });

    _socket!.on('marked_read', (data) {
      if (data is Map<String, dynamic>) {
        onMarkedRead?.call(data);
      }
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void sendMessageWs({
    required String conversationId,
    String? content,
    String? imageUrl,
    String? replyToId,
  }) {
    _socket?.emit('send_message', {
      'conversationId': conversationId,
      'content': content,
      'imageUrl': imageUrl,
      'replyToId': replyToId,
    });
  }

  void sendTyping({required String conversationId, required bool isTyping}) {
    _socket?.emit('typing', {
      'conversationId': conversationId,
      'isTyping': isTyping,
    });
  }

  void markReadWs({required String conversationId}) {
    _socket?.emit('mark_read', {'conversationId': conversationId});
  }

  // ─── REST API ───────────────────────────────────────────────────

  Dio get _dio => ApiClient.instance;

  Future<Map<String, dynamic>> createConversation({
    required List<String> participantIds,
    String? groupName,
  }) async {
    final res = await _dio.post('/chat/conversations', data: {
      'participantIds': participantIds,
      if (groupName != null) 'groupName': groupName,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> listConversations({int page = 1, int limit = 20}) async {
    final res = await _dio.get('/chat/conversations', queryParameters: {
      'page': page,
      'limit': limit,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> listMessages({
    required String conversationId,
    int page = 1,
    int limit = 50,
  }) async {
    final res = await _dio.get(
      '/chat/conversations/$conversationId/messages',
      queryParameters: {'page': page, 'limit': limit},
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    String? content,
    String? imageUrl,
    String? replyToId,
  }) async {
    final res = await _dio.post(
      '/chat/conversations/$conversationId/messages',
      data: {
        if (content != null) 'content': content,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (replyToId != null) 'replyToId': replyToId,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> editMessage({
    required String messageId,
    required String content,
  }) async {
    final res = await _dio.patch('/chat/messages/$messageId', data: {
      'content': content,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<void> deleteMessage({required String messageId}) async {
    await _dio.delete('/chat/messages/$messageId');
  }

  Future<Map<String, dynamic>> toggleReaction({
    required String messageId,
    required String emoji,
  }) async {
    final res = await _dio.post('/chat/messages/$messageId/reactions', data: {
      'emoji': emoji,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<void> markAsRead({required String conversationId}) async {
    await _dio.post('/chat/conversations/$conversationId/read');
  }
}

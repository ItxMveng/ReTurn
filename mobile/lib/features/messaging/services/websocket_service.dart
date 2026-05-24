import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../../core/storage/secure_storage.dart';
import '../data/models/message_model.dart';

part 'websocket_service.g.dart';

@riverpod
WebSocketService webSocketService(Ref ref) {
  final storage = ref.watch(secureStorageProvider);
  return WebSocketService(storage: storage);
}

class WebSocketService {
  WebSocketService({required this.storage});
  final SecureStorageService storage;

  WebSocketChannel? _channel;
  final StreamController<MessageModel> _messageController =
      StreamController.broadcast();

  Stream<MessageModel> get messageStream => _messageController.stream;

  Future<void> connect(String conversationId, String baseWsUrl) async {
    final token = await storage.getAccessToken();
    final uri = Uri.parse(
      '$baseWsUrl/api/v1/messaging/ws/$conversationId?token=$token',
    );
    _channel = WebSocketChannel.connect(uri);
    _channel!.stream.listen(
      (data) {
        try {
          final json = jsonDecode(data as String) as Map<String, dynamic>;
          final msg = MessageModel.fromJson(json);
          _messageController.add(msg);
        } catch (_) {}
      },
      onError: (_) => disconnect(),
      onDone: () => disconnect(),
    );
  }

  Future<void> send(String content) async {
    _channel?.sink.add(jsonEncode({'type': 'message', 'content': content}));
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}

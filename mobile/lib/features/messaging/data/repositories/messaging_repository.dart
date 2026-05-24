import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/network/api_client.dart';
import '../models/message_model.dart';

part 'messaging_repository.g.dart';

@riverpod
MessagingRepository messagingRepository(Ref ref) {
  return MessagingRepository(apiClient: ref.watch(apiClientProvider));
}

class MessagingRepository {
  MessagingRepository({required this.apiClient});
  final ApiClient apiClient;

  WebSocketChannel? _channel;
  final _messageController = StreamController<MessageModel>.broadcast();

  Stream<MessageModel> get messageStream => _messageController.stream;

  // ── HTTP ──

  Future<List<MessageModel>> getHistory(String matchId, {int limit = 50, String? before}) async {
    try {
      final raw = await apiClient.get<List<dynamic>>(
        '/messaging/$matchId',
        fromJson: (d) => d as List<dynamic>,
        queryParameters: {
          'limit': limit,
          if (before != null) 'before': before,
        },
      );
      return raw.map((e) => MessageModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) { throw mapException(e); }
    catch (e) { throw mapException(e); }
  }

  Future<MessageModel> sendMessage(String matchId, String content) async {
    try {
      return await apiClient.post<MessageModel>(
        '/messaging/$matchId',
        fromJson: (d) => MessageModel.fromJson(d as Map<String, dynamic>),
        body: {'content': content},
      );
    } on DioException catch (e) { throw mapException(e); }
    catch (e) { throw mapException(e); }
  }

  // ── WebSocket ──

  void connectWs(String matchId, String token) {
    disconnectWs();
    final baseUrl = apiClient.baseUrl.replaceFirst('http', 'ws');
    _channel = WebSocketChannel.connect(
      Uri.parse('$baseUrl/ws/chat/$matchId?token=$token'),
    );
    _channel!.stream.listen(
      (data) {
        try {
          final json = jsonDecode(data as String) as Map<String, dynamic>;
          _messageController.add(MessageModel.fromJson(json));
        } catch (_) {}
      },
      onError: (_) {},
      onDone: () {},
    );
  }

  void sendWs(String content) {
    _channel?.sink.add(jsonEncode({'content': content}));
  }

  void disconnectWs() {
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnectWs();
    _messageController.close();
  }
}

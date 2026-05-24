import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/message.dart';

final messagingRepositoryProvider =
    Provider<MessagingRepository>(
        (ref) => MessagingRepository(ref.read(dioProvider)));

class MessagingRepository {
  final Dio _dio;
  MessagingRepository(this._dio);

  Future<List<Conversation>> conversations() async {
    final res = await _dio.get('/messages/conversations');
    final items = res.data as List;
    return items
        .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChatMessage>> history(
      String roomId, String myId) async {
    final res =
        await _dio.get('/messages/$roomId/history');
    final items = res.data as List;
    return items
        .map((e) =>
            ChatMessage.fromJson(e as Map<String, dynamic>, myId))
        .toList();
  }

  Future<void> send(String roomId, String content) =>
      _dio.post('/messages/$roomId', data: {'content': content});
}

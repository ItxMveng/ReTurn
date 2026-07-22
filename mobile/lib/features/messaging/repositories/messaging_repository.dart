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

  /// GET avec une nouvelle tentative sur erreur de connexion transitoire
  /// (« Connection closed before full header », souvent due au reload backend).
  Future<Response<dynamic>> _getWithRetry(String path) async {
    try {
      return await _dio.get(path);
    } on DioException catch (e) {
      final transient = e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown;
      if (!transient) rethrow;
      await Future.delayed(const Duration(milliseconds: 400));
      return _dio.get(path);
    }
  }

  Future<List<Conversation>> conversations() async {
    final res = await _getWithRetry('/messaging/conversations');
    final items = res.data as List;
    return items
        .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChatMessage>> history(String roomId, String myId) async {
    final res = await _getWithRetry('/messaging/$roomId/messages');
    final items = res.data as List;
    return items
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>, myId))
        .toList();
  }

  Future<void> send(String roomId, String content) =>
      _dio.post('/messaging/$roomId/messages', data: {'content': content});

  /// Signale l'autre participant (F-31). reported_id déduit côté serveur.
  Future<void> report(String roomId, String reason, {String? description}) =>
      _dio.post('/messaging/$roomId/report', data: {
        'reason': reason,
        if (description != null && description.isNotEmpty)
          'description': description,
      });
}

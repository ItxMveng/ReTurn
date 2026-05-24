import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/errors/app_exception.dart';
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

  Future<List<ConversationModel>> listConversations() async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        '/messaging/conversations',
        fromJson: (d) => d as Map<String, dynamic>,
      );
      final items = response['conversations'] as List<dynamic>? ?? [];
      return items
          .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapException(e);
    } catch (e) {
      throw AppException.unknown(e.toString());
    }
  }

  Future<List<MessageModel>> getMessages(String conversationId,
      {String? cursor}) async {
    try {
      final query = <String, dynamic>{'limit': 50};
      if (cursor != null) query['cursor'] = cursor;
      final response = await apiClient.get<Map<String, dynamic>>(
        '/messaging/conversations/$conversationId/messages',
        queryParameters: query,
        fromJson: (d) => d as Map<String, dynamic>,
      );
      final items = response['messages'] as List<dynamic>? ?? [];
      return items
          .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapException(e);
    } catch (e) {
      throw AppException.unknown(e.toString());
    }
  }

  Future<MessageModel> sendMessage(
      String conversationId, String content) async {
    try {
      return await apiClient.post<MessageModel>(
        '/messaging/conversations/$conversationId/messages',
        body: {'content': content},
        fromJson: (d) =>
            MessageModel.fromJson(d as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw mapException(e);
    } catch (e) {
      throw AppException.unknown(e.toString());
    }
  }
}

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:docretour/core/constants/app_constants.dart';
import 'package:docretour/core/network/dio_provider.dart';
import 'package:docretour/core/utils/token_storage.dart';
import 'package:docretour/shared/models/message.dart';

final messagingRepositoryProvider = Provider<MessagingRepository>((ref) {
  return MessagingRepository(ref.watch(dioProvider));
});

class MessagingRepository {
  MessagingRepository(this._dio);
  final Dio _dio;

  Future<List<ChatMessage>> getHistory(String matchId) async {
    final res = await _dio.get('/api/v1/messaging/$matchId/messages');
    return (res.data as List)
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<WebSocketChannel> connectWs(String matchId) async {
    final token = await getAccessToken();
    final wsBase = AppConstants.apiBaseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');
    final uri =
        Uri.parse('$wsBase/api/v1/messaging/$matchId/ws?token=$token');
    return WebSocketChannel.connect(uri);
  }

  Future<Map<String, dynamic>> requestVerification(String matchId) async {
    final res = await _dio.post('/api/v1/messaging/$matchId/verify');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> submitSelfie(
      String matchId, String filePath) async {
    final formData = FormData.fromMap({
      'selfie': await MultipartFile.fromFile(filePath,
          filename: filePath.split('/').last),
    });
    final res = await _dio.post(
      '/api/v1/messaging/$matchId/verify/selfie',
      data: formData,
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>?> getVerificationStatus(String matchId) async {
    try {
      final res = await _dio.get('/api/v1/messaging/$matchId/verify');
      if (res.data == null) return null;
      return res.data as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/restitution.dart';

class RestitutionRepository {
  final Dio _dio;
  RestitutionRepository(this._dio);

  /// Restitution liée à un match (null si pas encore créée).
  Future<Restitution?> byMatch(String matchId) async {
    final res = await _dio.get('/restitutions/by-match/$matchId');
    final data = res.data;
    return data is Map<String, dynamic>
        ? Restitution.fromJson(data)
        : null;
  }

  /// Historique (F-35).
  Future<List<Restitution>> list() async {
    final res = await _dio.get('/restitutions/');
    final items = res.data as List;
    return items
        .map((e) => Restitution.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Double confirmation (F-33).
  Future<Restitution> confirm(String id) async {
    final res = await _dio.post('/restitutions/$id/confirm');
    return Restitution.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Restitution> setMeeting(String id, String location) async {
    final res = await _dio.patch('/restitutions/$id',
        data: {'meeting_location': location});
    return Restitution.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Restitution> rate(String id, int stars, {String? comment}) async {
    final res = await _dio.post('/restitutions/$id/rate', data: {
      'rating': stars,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    });
    return Restitution.fromJson(res.data as Map<String, dynamic>);
  }

  /// Photo de preuve de la remise physique (requise avant confirmation).
  Future<Restitution> uploadProof(String id, String photoPath) async {
    final form = FormData.fromMap({
      'photo': await MultipartFile.fromFile(photoPath, filename: 'proof.jpg'),
    });
    final res = await _dio.post(
      '/restitutions/$id/photos',
      data: form,
      options: Options(contentType: Headers.multipartFormDataContentType),
    );
    return Restitution.fromJson(res.data as Map<String, dynamic>);
  }
}

final restitutionRepositoryProvider = Provider<RestitutionRepository>(
  (ref) => RestitutionRepository(ref.read(dioProvider)),
);

/// Restitution d'un match donné.
final restitutionByMatchProvider =
    FutureProvider.family<Restitution?, String>((ref, matchId) async {
  return ref.read(restitutionRepositoryProvider).byMatch(matchId);
});

/// Historique des restitutions.
final restitutionsProvider =
    FutureProvider<List<Restitution>>((ref) async {
  return ref.read(restitutionRepositoryProvider).list();
});

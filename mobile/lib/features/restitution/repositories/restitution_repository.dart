import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/restitution.dart';

final restitutionRepositoryProvider =
    Provider<RestitutionRepository>(
        (ref) => RestitutionRepository(ref.read(dioProvider)));

class RestitutionRepository {
  final Dio _dio;
  RestitutionRepository(this._dio);

  Future<Restitution> create(String matchId) async {
    final res =
        await _dio.post('/restitutions', data: {'match_id': matchId});
    return Restitution.fromJson(res.data as Map<String, dynamic>);
  }

  Future<RestitutionModel> getById(String id) async {
    final res = await _dio.get('/restitutions/$id');
    return RestitutionModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<RestitutionModel>> listMyRestitutions() async {
    return [];
  }

  Future<Restitution> confirm(String id, String code) async {
    final res = await _dio
        .post('/restitutions/$id/confirm', data: {'code': code});
    return Restitution.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> rate(String id,
      {required double score, required bool isOwner}) async {
    await _dio.post('/restitutions/$id/rate',
        data: {
          if (isOwner) 'rating_owner': score,
          if (!isOwner) 'rating_finder': score,
        });
  }
}

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/match_model.dart';

final matchesRepositoryProvider =
    Provider<MatchesRepository>(
        (ref) => MatchesRepository(ref.read(dioProvider)));

class MatchesRepository {
  final Dio _dio;
  MatchesRepository(this._dio);

  Future<List<MatchModel>> list() async {
    final res = await _dio.get('/matches');
    final items = res.data['items'] as List;
    return items
        .map((e) => MatchModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MatchModel> get(String id) async {
    final res = await _dio.get('/matches/$id');
    return MatchModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> confirm(String id) =>
      _dio.patch('/matches/$id/confirm');

  Future<void> reject(String id) =>
      _dio.patch('/matches/$id/reject');
}

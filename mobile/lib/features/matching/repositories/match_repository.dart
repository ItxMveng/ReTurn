import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:docretour/core/network/dio_provider.dart';
import 'package:docretour/shared/models/match.dart';

final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  return MatchRepository(ref.watch(dioProvider));
});

class MatchRepository {
  MatchRepository(this._dio);
  final Dio _dio;

  Future<List<Match>> listMatches() async {
    final res = await _dio.get('/api/v1/matches/');
    return (res.data as List)
        .map((e) => Match.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Match> getMatch(String id) async {
    final res = await _dio.get('/api/v1/matches/$id');
    return Match.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Match> actOnMatch(String id, String action) async {
    final res = await _dio.post(
      '/api/v1/matches/$id/action',
      data: {'action': action},
    );
    return Match.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getNotifications() async {
    final res = await _dio.get('/api/v1/matches/notifications');
    return res.data as Map<String, dynamic>;
  }

  Future<void> clearNotifications() =>
      _dio.delete('/api/v1/matches/notifications');
}

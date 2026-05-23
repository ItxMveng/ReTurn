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

  /// Liste tous les matchs de l'utilisateur connecté
  Future<List<Match>> listMatches() async {
    final res = await _dio.get('/api/v1/matches/');
    return (res.data as List)
        .map((e) => Match.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Détail d'un match par son ID
  Future<Match> getById(String id) async {
    final res = await _dio.get('/api/v1/matches/$id');
    return Match.fromJson(res.data as Map<String, dynamic>);
  }

  /// Confirmer ou ignorer un match
  /// [action] : 'confirmed' | 'ignored'
  Future<Match> actOnMatch(String id, String action) async {
    final res = await _dio.patch(
      '/api/v1/matches/$id',
      data: {'status': action},
    );
    return Match.fromJson(res.data as Map<String, dynamic>);
  }

  /// Nombre de notifications non lues (matchs en attente)
  Future<Map<String, dynamic>> getNotifications() async {
    final res = await _dio.get('/api/v1/matches/notifications');
    return res.data as Map<String, dynamic>;
  }
}

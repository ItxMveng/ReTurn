import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:docretour/core/network/dio_provider.dart';
import 'package:docretour/shared/models/restitution.dart';

final restitutionRepositoryProvider = Provider<RestitutionRepository>((ref) {
  return RestitutionRepository(ref.watch(dioProvider));
});

class RestitutionRepository {
  RestitutionRepository(this._dio);
  final Dio _dio;

  /// Liste toutes les restitutions de l'utilisateur connecté
  Future<List<Restitution>> listMyRestitutions() async {
    final res = await _dio.get('/api/v1/restitutions/');
    return (res.data as List)
        .map((e) => Restitution.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Détail d'une restitution par ID
  Future<Restitution> getById(String id) async {
    final res = await _dio.get('/api/v1/restitutions/$id');
    return Restitution.fromJson(res.data as Map<String, dynamic>);
  }

  /// Initie une restitution à partir d'un match confirmé
  Future<Restitution> create({
    required String matchId,
    String? meetingLocation,
    DateTime? meetingScheduledAt,
  }) async {
    final res = await _dio.post('/api/v1/restitutions/', data: {
      'match_id': matchId,
      if (meetingLocation != null) 'meeting_location': meetingLocation,
      if (meetingScheduledAt != null)
        'meeting_scheduled_at': meetingScheduledAt.toIso8601String(),
    });
    return Restitution.fromJson(res.data as Map<String, dynamic>);
  }

  /// Marque la restitution comme complétée
  Future<Restitution> complete(String id) async {
    final res = await _dio.patch(
      '/api/v1/restitutions/$id',
      data: {'status': 'completed'},
    );
    return Restitution.fromJson(res.data as Map<String, dynamic>);
  }

  /// Annule une restitution
  Future<Restitution> cancel(String id) async {
    final res = await _dio.patch(
      '/api/v1/restitutions/$id',
      data: {'status': 'cancelled'},
    );
    return Restitution.fromJson(res.data as Map<String, dynamic>);
  }

  /// Soumet une note après restitution complétée
  /// [rating] : 1.0 – 5.0
  Future<Restitution> rate(String id, double rating) async {
    final res = await _dio.post(
      '/api/v1/restitutions/$id/rate',
      data: {'rating': rating},
    );
    return Restitution.fromJson(res.data as Map<String, dynamic>);
  }

  /// Signale un litige sur une restitution
  Future<Restitution> dispute(String id, {String? reason}) async {
    final res = await _dio.post(
      '/api/v1/restitutions/$id/dispute',
      data: {if (reason != null) 'reason': reason},
    );
    return Restitution.fromJson(res.data as Map<String, dynamic>);
  }
}

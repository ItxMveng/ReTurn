import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/network/api_client.dart';
import '../models/match_model.dart';
import '../models/restitution_model.dart';

part 'matches_repository.g.dart';

@riverpod
MatchesRepository matchesRepository(Ref ref) {
  return MatchesRepository(apiClient: ref.watch(apiClientProvider));
}

class MatchesRepository {
  MatchesRepository({required this.apiClient});
  final ApiClient apiClient;

  /// Liste tous les matchs de l’utilisateur
  Future<List<MatchModel>> listMatches() async {
    try {
      final raw = await apiClient.get<List<dynamic>>(
        '/matches/',
        fromJson: (d) => d as List<dynamic>,
      );
      return raw.map((e) => MatchModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) { throw mapException(e); }
    catch (e) { throw mapException(e); }
  }

  /// Détail d’un match
  Future<MatchModel> getMatch(String id) async {
    try {
      return await apiClient.get<MatchModel>(
        '/matches/$id',
        fromJson: (d) => MatchModel.fromJson(d as Map<String, dynamic>),
      );
    } on DioException catch (e) { throw mapException(e); }
    catch (e) { throw mapException(e); }
  }

  /// Confirmer ou ignorer un match
  Future<MatchActionResponse> actOnMatch(String id, String action) async {
    try {
      return await apiClient.post<MatchActionResponse>(
        '/matches/$id/action',
        fromJson: (d) => MatchActionResponse.fromJson(d as Map<String, dynamic>),
        body: {'action': action},
      );
    } on DioException catch (e) { throw mapException(e); }
    catch (e) { throw mapException(e); }
  }

  // ── Restitutions ───────────────────────────────────────────────────

  /// Détail d’une restitution
  Future<RestitutionModel> getRestitution(String id) async {
    try {
      return await apiClient.get<RestitutionModel>(
        '/restitutions/$id',
        fromJson: (d) => RestitutionModel.fromJson(d as Map<String, dynamic>),
      );
    } on DioException catch (e) { throw mapException(e); }
    catch (e) { throw mapException(e); }
  }

  /// Mise à jour d’une restitution (lieu, statut)
  Future<RestitutionModel> updateRestitution(String id, {
    String? meetingPoint,
    String? scheduledAt,
    String? status,
  }) async {
    try {
      return await apiClient.patch<RestitutionModel>(
        '/restitutions/$id',
        fromJson: (d) => RestitutionModel.fromJson(d as Map<String, dynamic>),
        body: {
          if (meetingPoint != null) 'meeting_point': meetingPoint,
          if (scheduledAt  != null) 'scheduled_at': scheduledAt,
          if (status       != null) 'status': status,
        },
      );
    } on DioException catch (e) { throw mapException(e); }
    catch (e) { throw mapException(e); }
  }

  /// Soumettre une note (1-5)
  Future<RestitutionModel> rateRestitution(String id, int rating) async {
    try {
      return await apiClient.post<RestitutionModel>(
        '/restitutions/$id/rate',
        fromJson: (d) => RestitutionModel.fromJson(d as Map<String, dynamic>),
        body: {'rating': rating},
      );
    } on DioException catch (e) { throw mapException(e); }
    catch (e) { throw mapException(e); }
  }
}

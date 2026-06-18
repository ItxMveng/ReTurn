import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/errors/app_exception.dart';
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

  /// Alias pour compatibilité avec matches_notifier
  Future<List<MatchModel>> listMatches() => listMyMatches();

  Future<List<MatchModel>> listMyMatches() async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        '/matches/mine',
        fromJson: (d) => d as Map<String, dynamic>,
      );
      final items = response['items'] as List<dynamic>? ?? [];
      return items
          .map((e) => MatchModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapException(e);
    } catch (e) {
      throw AppException.unknown(e.toString());
    }
  }

  Future<MatchModel> getMatch(String id) async {
    try {
      return await apiClient.get<MatchModel>(
        '/matches/$id',
        fromJson: (d) => MatchModel.fromJson(d as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw mapException(e);
    } catch (e) {
      throw AppException.unknown(e.toString());
    }
  }

  Future<RestitutionModel> getRestitution(String id) async {
    try {
      return await apiClient.get<RestitutionModel>(
        '/restitutions/$id',
        fromJson: (d) => RestitutionModel.fromJson(d as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw mapException(e);
    } catch (e) {
      throw AppException.unknown(e.toString());
    }
  }

  Future<MatchActionResponse> actOnMatch(String matchId, String action) async {
    try {
      final response = await apiClient.post<Map<String, dynamic>>(
        '/matches/$matchId/action',
        body: {'action': action},
        fromJson: (d) => d as Map<String, dynamic>,
      );
      return MatchActionResponse.fromJson(response);
    } on DioException catch (e) {
      throw mapException(e);
    } catch (e) {
      throw AppException.unknown(e.toString());
    }
  }

  Future<void> confirmMatch(String matchId) async {
    try {
      await apiClient.post<Map<String, dynamic>>(
        '/matches/$matchId/confirm',
        fromJson: (d) => d as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw mapException(e);
    } catch (e) {
      throw AppException.unknown(e.toString());
    }
  }

  Future<void> rejectMatch(String matchId) async {
    try {
      await apiClient.post<Map<String, dynamic>>(
        '/matches/$matchId/reject',
        fromJson: (d) => d as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw mapException(e);
    } catch (e) {
      throw AppException.unknown(e.toString());
    }
  }

  Future<void> rateRestitution(String id, int rating) async {
    try {
      await apiClient.post<Map<String, dynamic>>(
        '/restitutions/$id/rate',
        body: {'rating': rating},
        fromJson: (d) => d as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw mapException(e);
    } catch (e) {
      throw AppException.unknown(e.toString());
    }
  }

  Future<RestitutionModel> updateRestitution(String id,
      {String? meetingPoint}) async {
    try {
      return await apiClient.post<RestitutionModel>(
        '/restitutions/$id',
        body: {if (meetingPoint != null) 'meeting_point': meetingPoint},
        fromJson: (d) =>
            RestitutionModel.fromJson(d as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw mapException(e);
    } catch (e) {
      throw AppException.unknown(e.toString());
    }
  }
}

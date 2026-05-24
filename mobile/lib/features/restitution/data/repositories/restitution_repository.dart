import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/network/api_client.dart';
import '../models/restitution_model.dart';

part 'restitution_repository.g.dart';

@riverpod
RestitutionRepository restitutionRepository(Ref ref) {
  return RestitutionRepository(apiClient: ref.watch(apiClientProvider));
}

class RestitutionRepository {
  RestitutionRepository({required this.apiClient});
  final ApiClient apiClient;

  Future<RestitutionModel> initRestitution(String matchId) async {
    try {
      return await apiClient.post<RestitutionModel>(
        '/restitutions',
        body: {'match_id': matchId},
        fromJson: (d) =>
            RestitutionModel.fromJson(d as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw mapException(e);
    } catch (e) {
      throw AppException.unknown(e.toString());
    }
  }

  Future<RestitutionModel> confirmRestitution(
      String restitutionId, Map<String, dynamic> payload) async {
    try {
      return await apiClient.post<RestitutionModel>(
        '/restitutions/$restitutionId/confirm',
        body: payload,
        fromJson: (d) =>
            RestitutionModel.fromJson(d as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw mapException(e);
    } catch (e) {
      throw AppException.unknown(e.toString());
    }
  }

  Future<RestitutionModel> rateRestitution(
      String restitutionId, double rating) async {
    try {
      return await apiClient.post<RestitutionModel>(
        '/restitutions/$restitutionId/rate',
        body: {'rating': rating},
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

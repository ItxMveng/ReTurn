import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/network/api_client.dart';
import '../models/declaration_model.dart';

part 'declarations_repository.g.dart';

@riverpod
DeclarationsRepository declarationsRepository(Ref ref) {
  return DeclarationsRepository(
    apiClient: ref.watch(apiClientProvider),
  );
}

class DeclarationsRepository {
  DeclarationsRepository({required this.apiClient});
  final ApiClient apiClient;

  Future<List<DeclarationModel>> listDeclarations({
    String? type,
    String? cursor,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{'limit': limit};
      if (type != null) queryParams['type'] = type;
      if (cursor != null) queryParams['cursor'] = cursor;

      final response = await apiClient.get<Map<String, dynamic>>(
        '/declarations',
        query: queryParams,
        fromJson: (d) => d as Map<String, dynamic>,
      );
      final items = response['items'] as List<dynamic>? ?? [];
      return items
          .map((e) => DeclarationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapException(e);
    } catch (e) {
      throw AppException.unknown(e.toString());
    }
  }

  Future<DeclarationModel> getDeclaration(String id) async {
    try {
      return await apiClient.get<DeclarationModel>(
        '/declarations/$id',
        fromJson: (d) =>
            DeclarationModel.fromJson(d as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw mapException(e);
    } catch (e) {
      throw AppException.unknown(e.toString());
    }
  }

  Future<DeclarationModel> createDeclaration(
      Map<String, dynamic> payload) async {
    try {
      return await apiClient.post<DeclarationModel>(
        '/declarations',
        body: payload,
        fromJson: (d) =>
            DeclarationModel.fromJson(d as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw mapException(e);
    } catch (e) {
      throw AppException.unknown(e.toString());
    }
  }

  Future<void> deleteDeclaration(String id) async {
    try {
      await apiClient.delete('/declarations/$id');
    } on DioException catch (e) {
      throw mapException(e);
    } catch (e) {
      throw AppException.unknown(e.toString());
    }
  }

  Future<List<String>> getDocumentTypes() async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        '/declarations/document-types',
        fromJson: (d) => d as Map<String, dynamic>,
      );
      final items = response['types'] as List<dynamic>? ?? [];
      return items.map((e) => e as String).toList();
    } on DioException catch (e) {
      throw mapException(e);
    } catch (e) {
      throw AppException.unknown(e.toString());
    }
  }
}

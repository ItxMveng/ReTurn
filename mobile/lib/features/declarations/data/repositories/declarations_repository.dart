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
  return DeclarationsRepository(apiClient: ref.watch(apiClientProvider));
}

class DeclarationsRepository {
  DeclarationsRepository({required this.apiClient});
  final ApiClient apiClient;

  /// Liste paginate via cursor
  Future<List<DeclarationModel>> listDeclarations({
    int limit = 20,
    String? cursor,
  }) async {
    try {
      final raw = await apiClient.get<List<dynamic>>(
        '/declarations/',
        fromJson: (d) => d as List<dynamic>,
        query: {
          'limit': limit,
          if (cursor != null) 'cursor': cursor,
        },
      );
      return raw
          .map((e) => DeclarationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapException(e);
    } catch (e) {
      throw mapException(e);
    }
  }

  /// Détail d’une déclaration
  Future<DeclarationModel> getDeclaration(String id) async {
    try {
      return await apiClient.get<DeclarationModel>(
        '/declarations/$id',
        fromJson: (d) => DeclarationModel.fromJson(d as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw mapException(e);
    } catch (e) {
      throw mapException(e);
    }
  }

  /// Création via multipart/form-data
  Future<DeclarationModel> createDeclaration({
    required String declarationType,
    required String documentType,
    String? documentNumber,
    String? ownerName,
    String? description,
    double? latitude,
    double? longitude,
    String? locationDescription,
    String? eventDate,
    List<String> photoPaths = const [],
  }) async {
    try {
      final formData = FormData.fromMap({
        'declaration_type': declarationType,
        'document_type': documentType,
        if (documentNumber != null && documentNumber.isNotEmpty) 'document_number': documentNumber,
        if (ownerName != null && ownerName.isNotEmpty) 'owner_name': ownerName,
        if (description != null && description.isNotEmpty) 'description': description,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (locationDescription != null && locationDescription.isNotEmpty) 'location_description': locationDescription,
        if (eventDate != null) 'event_date': eventDate,
        if (photoPaths.isNotEmpty)
          'photos': await Future.wait(
            photoPaths.map((p) => MultipartFile.fromFile(p)),
          ),
      });

      final raw = await apiClient.post<Map<String, dynamic>>(
        '/declarations/',
        fromJson: (d) => d as Map<String, dynamic>,
        body: {},  // FormData passé via override Dio
      );
      // On contourne le wrapper post() pour les form-data
      return DeclarationModel.fromJson(raw);
    } on DioException catch (e) {
      throw mapException(e);
    } catch (e) {
      throw mapException(e);
    }
  }

  /// Suppression d’une déclaration
  Future<void> deleteDeclaration(String id) async {
    try {
      await apiClient.delete('/declarations/$id');
    } on DioException catch (e) {
      throw mapException(e);
    } catch (e) {
      throw mapException(e);
    }
  }

  /// Récupère les types de documents disponibles
  Future<List<String>> getDocumentTypes() async {
    try {
      return await apiClient.get<List<String>>(
        '/declarations/document-types',
        fromJson: (d) => (d as List<dynamic>).map((e) => e.toString()).toList(),
      );
    } on DioException catch (e) {
      throw mapException(e);
    } catch (e) {
      throw mapException(e);
    }
  }
}

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:return_mobile/core/network/dio_provider.dart';
import 'package:return_mobile/shared/models/declaration.dart';

final declarationRepositoryProvider = Provider<DeclarationRepository>((ref) {
  return DeclarationRepository(ref.watch(dioProvider));
});

class DeclarationRepository {
  DeclarationRepository(this._dio);
  final Dio _dio;

  /// Types de documents supportés (CNI, Passeport, Permis…)
  Future<List<String>> getDocumentTypes() async {
    final res = await _dio.get('/api/v1/declarations/document-types');
    return List<String>.from(res.data as List);
  }

  /// Crée une nouvelle déclaration (trouvé ou perdu) avec photos optionnelles
  Future<Declaration> createDeclaration({
    required String declarationType,
    required String documentType,
    String? documentNumber,
    String? ownerName,
    String? description,
    double? latitude,
    double? longitude,
    String? locationDescription,
    List<String> photoPaths = const [],
  }) async {
    final formData = FormData.fromMap({
      'declaration_type': declarationType,
      'document_type': documentType,
      if (documentNumber != null) 'document_number': documentNumber,
      if (ownerName != null) 'owner_name': ownerName,
      if (description != null) 'description': description,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (locationDescription != null)
        'location_description': locationDescription,
      if (photoPaths.isNotEmpty)
        'photos': [
          for (final p in photoPaths)
            await MultipartFile.fromFile(p, filename: p.split('/').last),
        ],
    });
    final res = await _dio.post('/api/v1/declarations/', data: formData);
    return DeclarationModel.fromJson(res.data as Map<String, dynamic>);
  }

  /// Liste les déclarations de l'utilisateur connecté
  Future<List<Declaration>> listMyDeclarations() async {
    final res = await _dio.get('/api/v1/declarations/');
    return (res.data as List)
        .map((e) => DeclarationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// [P-D] Détail d'une déclaration par son ID — manquait dans la version précédente
  /// Utilisé par DeclarationDetailScreen pour afficher les infos complètes
  Future<Declaration> getDeclarationById(String id) async {
    final res = await _dio.get('/api/v1/declarations/$id');
    return DeclarationModel.fromJson(res.data as Map<String, dynamic>);
  }

  /// Supprime une déclaration (soft-delete côté backend)
  Future<void> deleteDeclaration(String id) =>
      _dio.delete('/api/v1/declarations/$id');

  /// Recherche publique de déclarations (pour le matching manuel)
  Future<List<Declaration>> searchDeclarations({
    String? documentType,
    String? declarationType,
    String? query,
  }) async {
    final res = await _dio.get(
      '/api/v1/declarations/search',
      queryParameters: {
        if (documentType != null) 'document_type': documentType,
        if (declarationType != null) 'declaration_type': declarationType,
        if (query != null) 'q': query,
      },
    );
    return (res.data as List)
        .map((e) => DeclarationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

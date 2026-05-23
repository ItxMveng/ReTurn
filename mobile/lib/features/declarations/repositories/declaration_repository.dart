import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:docretour/core/network/dio_provider.dart';
import 'package:docretour/shared/models/declaration.dart';

final declarationRepositoryProvider = Provider<DeclarationRepository>((ref) {
  return DeclarationRepository(ref.watch(dioProvider));
});

class DeclarationRepository {
  DeclarationRepository(this._dio);
  final Dio _dio;

  Future<List<String>> getDocumentTypes() async {
    final res = await _dio.get('/api/v1/declarations/document-types');
    return List<String>.from(res.data as List);
  }

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
      if (locationDescription != null) 'location_description': locationDescription,
      if (photoPaths.isNotEmpty)
        'photos': [
          for (final p in photoPaths)
            await MultipartFile.fromFile(p, filename: p.split('/').last),
        ],
    });

    final res = await _dio.post('/api/v1/declarations/', data: formData);
    return Declaration.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<Declaration>> listMyDeclarations() async {
    final res = await _dio.get('/api/v1/declarations/');
    return (res.data as List)
        .map((e) => Declaration.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteDeclaration(String id) =>
      _dio.delete('/api/v1/declarations/$id');
}

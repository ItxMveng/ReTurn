import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/declaration.dart';

final declarationsRepositoryProvider =
    Provider<DeclarationsRepository>(
        (ref) => DeclarationsRepository(ref.read(dioProvider)));

class DeclarationsRepository {
  final Dio _dio;
  DeclarationsRepository(this._dio);

  Future<List<Declaration>> list({String? cursor, int limit = 20}) async {
    final res = await _dio.get('/declarations/', queryParameters: {
      if (cursor != null) 'cursor': cursor,
      'limit': limit,
    });
    final items = res.data as List<dynamic>;
    return items
        .map((e) => DeclarationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Declaration> get(String id) async {
    final res = await _dio.get('/declarations/$id');
    return DeclarationModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Declaration> create(
    Map<String, dynamic> data, {
    List<String> photoPaths = const [],
  }) async {
    // Le backend attend du multipart/form-data (Form/File) — pas du JSON.
    // Sinon il renvoie 422. Slash final pour éviter le redirect 307.
    final form = FormData.fromMap({
      for (final entry in data.entries)
        if (entry.value != null) entry.key: '${entry.value}',
    });
    for (final path in photoPaths.take(3)) {
      form.files.add(MapEntry(
        'photos',
        await MultipartFile.fromFile(path),
      ));
    }
    final res = await _dio.post(
      '/declarations/',
      data: form,
      options: Options(contentType: Headers.multipartFormDataContentType),
    );
    return DeclarationModel.fromJson(res.data as Map<String, dynamic>);
  }

  /// Dossier multi-documents : déclare plusieurs documents en une seule
  /// requête (ex. portefeuille avec CNI + permis). Le dossier compte pour
  /// UNE seule déclaration dans la limite d'actives.
  Future<List<Declaration>> createBatch(
    Map<String, dynamic> shared,
    List<Map<String, dynamic>> items, {
    List<String> photoPaths = const [],
  }) async {
    final form = FormData.fromMap({
      for (final entry in shared.entries)
        if (entry.value != null) entry.key: '${entry.value}',
      'items': jsonEncode(items),
    });
    for (final path in photoPaths.take(3)) {
      form.files.add(MapEntry(
        'photos',
        await MultipartFile.fromFile(path),
      ));
    }
    final res = await _dio.post(
      '/declarations/batch',
      data: form,
      options: Options(contentType: Headers.multipartFormDataContentType),
    );
    return (res.data as List)
        .map((e) => DeclarationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Compteur de déclarations actives + limite dynamique (chip UI).
  Future<({int activeCount, int limit})> limits() async {
    final res = await _dio.get('/declarations/limits');
    final data = res.data as Map;
    return (
      activeCount: (data['active_count'] as num?)?.toInt() ?? 0,
      limit: (data['limit'] as num?)?.toInt() ?? 3,
    );
  }

  /// Annule une déclaration (statut → closed) sans la supprimer.
  Future<Declaration> cancel(String id) async {
    final res =
        await _dio.patch('/declarations/$id', data: {'status': 'cancelled'});
    return DeclarationModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) => _dio.delete('/declarations/$id');
}

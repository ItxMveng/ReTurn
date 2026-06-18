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
    final res = await _dio.get('/declarations', queryParameters: {
      if (cursor != null) 'cursor': cursor,
      'limit': limit,
    });
    final items = (res.data['items'] as List);
    return items
        .map((e) => DeclarationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Declaration> get(String id) async {
    final res = await _dio.get('/declarations/$id');
    return DeclarationModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Declaration> create(Map<String, dynamic> data) async {
    final res = await _dio.post('/declarations', data: data);
    return DeclarationModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) => _dio.delete('/declarations/$id');
}

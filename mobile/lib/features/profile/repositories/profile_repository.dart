import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/user_profile.dart';

final profileRepositoryProvider =
    Provider<ProfileRepository>(
        (ref) => ProfileRepository(ref.read(dioProvider)));

class ProfileRepository {
  final Dio _dio;
  ProfileRepository(this._dio);

  Future<UserProfile> me() async {
    final res = await _dio.get('/users/me');
    return UserProfile.fromJson(res.data as Map<String, dynamic>);
  }

  Future<UserProfile> update(Map<String, dynamic> data) async {
    final res = await _dio.patch('/users/me', data: data);
    return UserProfile.fromJson(res.data as Map<String, dynamic>);
  }
}

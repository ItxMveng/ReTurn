import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:docretour/core/network/dio_provider.dart';
import 'package:docretour/shared/models/user_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(dioProvider));
});

class ProfileRepository {
  ProfileRepository(this._dio);
  final Dio _dio;

  /// Récupère le profil de l'utilisateur connecté
  Future<UserProfile> fetchProfile() async {
    final res = await _dio.get('/api/v1/profile/');
    return UserProfile.fromJson(res.data as Map<String, dynamic>);
  }

  /// Met à jour les champs du profil (PATCH partiel)
  Future<UserProfile> updateProfile(Map<String, dynamic> data) async {
    final res = await _dio.patch('/api/v1/profile/', data: data);
    return UserProfile.fromJson(res.data as Map<String, dynamic>);
  }

  /// Upload d'un nouvel avatar depuis la galerie
  Future<UserProfile> updateAvatar() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
    );
    if (xFile == null) throw Exception('Aucune image sélectionnée');

    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(xFile.path, filename: xFile.name),
    });
    final res = await _dio.patch('/api/v1/profile/avatar', data: formData);
    return UserProfile.fromJson(res.data as Map<String, dynamic>);
  }

  /// Enregistre ou met à jour le token FCM pour les notifications push
  Future<void> registerFcmToken(String fcmToken) async {
    await _dio.patch('/api/v1/profile/', data: {'fcm_token': fcmToken});
  }

  /// Récupère le profil public d'un autre utilisateur (pour les écrans de match)
  Future<UserProfile> fetchPublicProfile(String userId) async {
    final res = await _dio.get('/api/v1/profile/$userId');
    return UserProfile.fromJson(res.data as Map<String, dynamic>);
  }
}

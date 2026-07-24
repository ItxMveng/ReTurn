import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:return_mobile/core/network/dio_provider.dart';
import 'package:return_mobile/core/services/media_service.dart';
import 'package:return_mobile/core/services/notification_service.dart';
import 'package:return_mobile/core/utils/token_storage.dart';

class UserProfile {
  final String id;
  final String phoneNumber;
  final String? email;
  final String fullName;
  final String? dateOfBirth;
  final String? nationalIdNumber;
  final String? gender;
  final String? city;
  final String? region;
  final String? address;
  final String? avatarUrl;
  final double scoreReputation;
  final bool isProfileComplete;

  const UserProfile({
    required this.id,
    required this.phoneNumber,
    this.email,
    required this.fullName,
    this.dateOfBirth,
    this.nationalIdNumber,
    this.gender,
    this.city,
    this.region,
    this.address,
    this.avatarUrl,
    this.scoreReputation = 5.0,
    required this.isProfileComplete,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: (json['id'] as String?) ?? '',
        phoneNumber: (json['phone_number'] as String?) ?? '',
        email: json['email'] as String?,
        fullName: (json['full_name'] as String?) ?? '',
        dateOfBirth: json['date_of_birth'] as String?,
        nationalIdNumber: json['national_id_number'] as String?,
        gender: json['gender'] as String?,
        city: json['city'] as String?,
        region: json['region'] as String?,
        address: json['address'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        scoreReputation:
            (json['score_reputation'] as num?)?.toDouble() ?? 5.0,
        isProfileComplete: (json['is_profile_complete'] as bool?) ?? false,
      );
}

class ProfileNotifier extends AsyncNotifier<UserProfile?> {
  Dio get _dio => ref.read(dioProvider);

  @override
  Future<UserProfile?> build() => _fetch();

  Future<UserProfile?> _fetch() async {
    final token = await getAccessToken();
    if (token == null) return null;
    final res = await _dio.get(
      '/profile/',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final profile = UserProfile.fromJson(res.data as Map<String, dynamic>);
    _registerFcmToken(token);
    return profile;
  }

  Future<void> _registerFcmToken(String accessToken) async {
    try {
      final fcmToken = await NotificationService.getToken();
      if (fcmToken == null) return;
      await _dio.patch(
        '/profile/',
        data: {'fcm_token': fcmToken},
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
    } catch (_) {}
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  /// Retourne `null` si succès, sinon un message d'erreur lisible.
  Future<String?> updateProfile(Map<String, dynamic> data) async {
    try {
      final token = await getAccessToken();
      if (token == null) return 'Session expirée, reconnectez-vous.';
      final res = await _dio.patch(
        '/profile/',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final updated = UserProfile.fromJson(res.data as Map<String, dynamic>);
      state = AsyncData(updated);
      return null;
    } on DioException catch (e) {
      // Remonte le détail du backend (409 déjà utilisé, 422 invalide…).
      final body = e.response?.data;
      final detail = body is Map ? body['detail'] : null;
      if (detail is String) return detail;
      if (e.response?.statusCode == 409) {
        return 'Cet email ou numéro est déjà utilisé par un autre compte.';
      }
      return 'Mise à jour impossible. Réessayez.';
    } catch (_) {
      return 'Mise à jour impossible. Réessayez.';
    }
  }

  /// Prend une photo (caméra ou galerie) avec permission runtime, l'upload
  /// et met à jour l'état. Retourne :
  ///   - `null` si succès,
  ///   - `''` (chaîne vide) si l'utilisateur a annulé (pas une erreur),
  ///   - un message d'erreur lisible sinon.
  Future<String?> pickAndUploadAvatar(ImageSource source) async {
    final picked = await MediaService.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 512,
    );
    if (picked.error != null) return picked.error;
    final file = picked.file;
    if (file == null) return ''; // annulé
    return _uploadAvatar(file);
  }

  Future<String?> _uploadAvatar(XFile xFile) async {
    try {
      final token = await getAccessToken();
      if (token == null) return 'Session expirée, reconnectez-vous.';
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          xFile.path,
          filename: xFile.name,
        ),
      });
      final res = await _dio.patch(
        '/profile/avatar',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final updated = UserProfile.fromJson(res.data as Map<String, dynamic>);
      state = AsyncData(updated);
      return null;
    } on DioException catch (e) {
      final body = e.response?.data;
      final detail = body is Map ? body['detail'] : null;
      if (detail is String) return detail;
      return 'Envoi de la photo impossible. Réessayez.';
    } catch (_) {
      return 'Envoi de la photo impossible. Réessayez.';
    }
  }

  /// Suppression définitive du compte et des données (RGPD — F-04).
  Future<bool> deleteAccount() async {
    try {
      final token = await getAccessToken();
      if (token == null) return false;
      await _dio.delete(
        '/profile/',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Vérifie si un email est disponible (non utilisé par un autre compte)
  Future<bool> checkEmailAvailable(String email) async {
    try {
      final token = await getAccessToken();
      if (token == null) return false;
      final res = await _dio.get(
        '/profile/check-email',
        queryParameters: {'email': email},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = res.data as Map<String, dynamic>;
      return (data['available'] as bool?) ?? false;
    } on DioException catch (e) {
      // 409 = email déjà pris
      if (e.response?.statusCode == 409) return false;
      return false;
    } catch (_) {
      return false;
    }
  }
}

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, UserProfile?>(ProfileNotifier.new);

final isProfileCompleteProvider = Provider<bool>((ref) {
  return ref.watch(profileProvider).valueOrNull?.isProfileComplete ?? false;
});

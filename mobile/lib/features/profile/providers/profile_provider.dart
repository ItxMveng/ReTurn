import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:docretour/core/network/dio_provider.dart';
import 'package:docretour/core/services/notification_service.dart';
import 'package:docretour/core/utils/token_storage.dart';
import 'package:docretour/features/auth/presentation/providers/auth_provider.dart';

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
        isProfileComplete: (json['is_profile_complete'] as bool?) ?? false,
      );
}

class ProfileNotifier extends AsyncNotifier<UserProfile?> {
  Dio get _dio => ref.read(dioProvider);

  @override
  Future<UserProfile?> build() async {
    final authState = ref.watch(authProvider);
    final isAuth = authState.maybeWhen(
      authenticated: (_, __, ___) => true,
      orElse: () => false,
    );
    if (!isAuth) return null;
    return _fetch();
  }

  Future<UserProfile?> _fetch() async {
    try {
      final token = await getAccessToken();
      if (token == null) return null;
      final res = await _dio.get(
        '/api/v1/profile/',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final profile = UserProfile.fromJson(res.data as Map<String, dynamic>);
      _registerFcmToken(token);
      return profile;
    } catch (_) {
      return null;
    }
  }

  Future<void> _registerFcmToken(String accessToken) async {
    try {
      final fcmToken = await NotificationService.getToken();
      if (fcmToken == null) return;
      await _dio.patch(
        '/api/v1/profile/',
        data: {'fcm_token': fcmToken},
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
    } catch (_) {}
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final token = await getAccessToken();
      if (token == null) return false;
      final res = await _dio.patch(
        '/api/v1/profile/',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final updated = UserProfile.fromJson(res.data as Map<String, dynamic>);
      state = AsyncData(updated);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Upload avatar depuis un XFile (image_picker)
  Future<bool> updateAvatarFromFile(XFile xFile) async {
    try {
      final token = await getAccessToken();
      if (token == null) return false;
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          xFile.path,
          filename: xFile.name,
        ),
      });
      final res = await _dio.patch(
        '/api/v1/profile/avatar',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final updated = UserProfile.fromJson(res.data as Map<String, dynamic>);
      state = AsyncData(updated);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Méthode legacy (garde la compatibilité avec le code existant)
  Future<bool> updateAvatar() async {
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(
          source: ImageSource.gallery, imageQuality: 80, maxWidth: 512);
      if (xFile == null) return false;
      return updateAvatarFromFile(xFile);
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
        '/api/v1/profile/check-email',
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

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../models/auth_token_model.dart';
import '../models/user_model.dart';

part 'auth_repository.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepository(
    apiClient: ref.watch(apiClientProvider),
    storage: ref.watch(secureStorageProvider),
  );
}

class AuthRepository {
  AuthRepository({required this.apiClient, required this.storage});
  final ApiClient apiClient;
  final SecureStorageService storage;

  /// Login via Firebase token (Phone Auth SMS ou Google Sign-In)
  Future<AuthTokenModel> loginWithFirebase(String firebaseToken) async {
    try {
      final tokens = await apiClient.post<AuthTokenModel>(
        '/auth/verify-firebase-token',
        body: {'firebase_token': firebaseToken},
        fromJson: (d) => AuthTokenModel.fromJson(d as Map<String, dynamic>),
      );
      await storage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      return tokens;
    } on DioException catch (e) {
      throw mapException(e);
    } catch (e) {
      throw mapException(e);
    }
  }

  /// Récupère le profil de l’utilisateur connecté
  Future<UserModel> getMe() async {
    try {
      return await apiClient.get<UserModel>(
        '/auth/me',
        fromJson: (d) => UserModel.fromJson(d as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw mapException(e);
    } catch (e) {
      throw mapException(e);
    }
  }

  /// Déconnexion : efface les tokens + caches
  Future<void> logout() async {
    await storage.clearAll();
  }

  /// Vérifie si l’utilisateur est authentifié localement
  Future<bool> isAuthenticated() => storage.isAuthenticated();
}

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/repositories/auth_repository.dart';
import '../domain/auth_state.dart';

part 'auth_notifier.g.dart';

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() => const AuthState.initial();

  Future<void> requestOtp(String phoneNumber) async {
    state = const AuthState.loading();
    try {
      await ref.read(authRepositoryProvider).requestOtp(phoneNumber);
      state = AuthState.otpSent(phoneNumber: phoneNumber);
    } catch (e) {
      state = AuthState.error(message: e.toString());
    }
  }

  Future<void> verifyOtp({
    required String phoneNumber,
    required String otpCode,
  }) async {
    state = const AuthState.loading();
    try {
      await ref.read(authRepositoryProvider).verifyOtp(
            phoneNumber: phoneNumber,
            otpCode: otpCode,
          );
      final user = await ref.read(authRepositoryProvider).getMe();
      state = AuthState.authenticated(user: user);
    } catch (e) {
      state = AuthState.error(message: e.toString());
    }
  }

  Future<void> checkAuth() async {
    final isAuth = await ref.read(authRepositoryProvider).isAuthenticated();
    if (isAuth) {
      try {
        final user = await ref.read(authRepositoryProvider).getMe();
        state = AuthState.authenticated(user: user);
      } catch (_) {
        state = const AuthState.unauthenticated();
      }
    } else {
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AuthState.unauthenticated();
  }
}

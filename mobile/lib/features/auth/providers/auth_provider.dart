import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../domain/auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AuthState.initial()) {
    _init();
  }

  Future<void> _init() async {
    state = const AuthState.loading();
    final session = await _repo.restoreSession();
    if (session != null) {
      state = AuthState.authenticated(
          userId: session.userId, phone: session.phone);
    } else {
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> register({
    required String phone,
    required String fullName,
    required String password,
  }) async {
    state = const AuthState.loading();
    try {
      final tokens = await _repo.register(
          phone: phone, fullName: fullName, password: password);
      state =
          AuthState.authenticated(userId: tokens.userId, phone: tokens.phone);
    } on Exception catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> login({
    required String phone,
    required String password,
  }) async {
    state = const AuthState.loading();
    try {
      final tokens = await _repo.login(phone: phone, password: password);
      state =
          AuthState.authenticated(userId: tokens.userId, phone: tokens.phone);
    } on Exception catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState.unauthenticated();
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

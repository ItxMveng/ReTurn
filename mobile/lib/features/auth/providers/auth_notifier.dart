import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_models.dart';
import '../repositories/auth_repository.dart';

enum AuthStatus { idle, loading, success, error }

class AuthState {
  final AuthStatus status;
  final String? error;
  const AuthState({this.status = AuthStatus.idle, this.error});
  AuthState copyWith({AuthStatus? status, String? error}) =>
      AuthState(status: status ?? this.status, error: error ?? this.error);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  AuthNotifier(this._repo) : super(const AuthState());

  Future<bool> login(String phone, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _repo.login(LoginRequest(phone: phone, password: password));
      state = state.copyWith(status: AuthStatus.success);
      return true;
    } catch (e) {
      state = state.copyWith(
          status: AuthStatus.error, error: _extractError(e));
      return false;
    }
  }

  Future<bool> register(
      String phone, String password, String nom, String prenom) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _repo.register(RegisterRequest(
          phone: phone, password: password, nom: nom, prenom: prenom));
      state = state.copyWith(status: AuthStatus.success);
      return true;
    } catch (e) {
      state = state.copyWith(
          status: AuthStatus.error, error: _extractError(e));
      return false;
    }
  }

  Future<void> logout() => _repo.logout();

  String _extractError(Object e) {
    if (e is Exception) return e.toString().replaceFirst('Exception: ', '');
    return 'Erreur inconnue';
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) =>
        AuthNotifier(ref.read(authRepositoryProvider)));

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import 'package:docretour/core/constants/app_constants.dart';
import 'package:docretour/features/auth/data/repositories/auth_repository.dart';
import 'package:docretour/features/auth/domain/models/auth_state.dart';

final _log = Logger();

final authRepositoryProvider = Provider<AuthRepository>((_) => AuthRepository());

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

// Expose uniquement le booléen d'authentification pour le router
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).maybeWhen(
        authenticated: (_, __, ___) => true,
        orElse: () => false,
      );
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(const AuthState.initial()) {
    _tryRestore();
  }

  final Ref _ref;
  Timer? _resendTimer;
  int _resendSecondsLeft = 0;
  int? _lastResendToken;
  String? _lastPhone;

  AuthRepository get _repo => _ref.read(authRepositoryProvider);

  int get resendSecondsLeft => _resendSecondsLeft;

  Future<void> _tryRestore() async {
    state = const AuthState.loading();
    final restored = await _repo.tryRestoreSession();
    state = restored ?? const AuthState.initial();
  }

  Future<void> sendOtp(String rawPhone) async {
    _log.d('sendOtp appelé');
    state = const AuthState.loading();

    final result = await _repo.sendOtp(
      rawPhone,
      resendToken: _lastResendToken,
      onStateChange: (s) {
        state = s;
        // Capturer le resendToken pour les renvois
        s.maybeWhen(
          codeSent: (_, phone, token) {
            _lastPhone = phone;
            _lastResendToken = token;
            _startResendTimer();
          },
          orElse: () {},
        );
      },
    );

    state = result;
    result.maybeWhen(
      codeSent: (_, phone, token) {
        _lastPhone = phone;
        _lastResendToken = token;
        _startResendTimer();
      },
      orElse: () {},
    );
  }

  Future<void> resendOtp() async {
    if (_lastPhone == null) return;
    _resendTimer?.cancel();
    await sendOtp(_lastPhone!);
  }

  Future<void> verifyOtp({
    required String verificationId,
    required String code,
  }) async {
    state = const AuthState.loading();
    final result = await _repo.verifySmsCode(
      verificationId: verificationId,
      smsCode: code,
    );
    state = result;
  }

  Future<void> signInWithGoogle() async {
    state = const AuthState.loading();
    final result = await _repo.signInWithGoogle();
    state = result;
  }

  Future<void> logout() async {
    await _repo.logout();
    _resendTimer?.cancel();
    state = const AuthState.initial();
  }

  void _startResendTimer() {
    _resendSecondsLeft = AppConstants.otpResendDelaySeconds;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendSecondsLeft <= 0) {
        t.cancel();
      } else {
        _resendSecondsLeft--;
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }
}

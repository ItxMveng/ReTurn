import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:logger/logger.dart';

import 'package:docretour/core/constants/app_constants.dart';
import 'package:docretour/core/providers/settings_provider.dart';
import 'package:docretour/core/services/biometric_service.dart';

part 'biometric_provider.freezed.dart';

final _log = Logger();

// ── BiometricState ─────────────────────────────────────────────────────────────

@freezed
class BiometricState with _$BiometricState {
  const factory BiometricState.initial() = _Initial;
  const factory BiometricState.loading() = _Loading;
  const factory BiometricState.available({
    required bool isSupported,
    required bool isEnrolled,
    required List<BiometricType> availableTypes,
    required bool isEnabled,
  }) = _Available;
  const factory BiometricState.authenticated() = _Authenticated;
  const factory BiometricState.error({
    required String message,
    required BiometricErrorType type,
  }) = _Error;
}

enum BiometricErrorType {
  notAvailable,
  notEnrolled,
  notEnabled,
  authenticationFailed,
  cancelled,
  unknown,
}

// ── BiometricNotifier ─────────────────────────────────────────────────────────────

class BiometricNotifier extends StateNotifier<BiometricState> {
  BiometricNotifier(this._service, this._ref) : super(const BiometricState.initial()) {
    _checkAvailability();
  }

  final BiometricService _service;
  final Ref _ref;

  Future<void> _checkAvailability() async {
    state = const BiometricState.loading();
    
    final isSupported = await _service.isDeviceSupported();
    if (!isSupported) {
      state = const BiometricState.available(
        isSupported: false,
        isEnrolled: false,
        availableTypes: [],
        isEnabled: false,
      );
      return;
    }

    final isEnrolled = await _service.isBiometricEnrolled();
    final availableTypes = await _service.getAvailableBiometrics();
    final isEnabled = _ref.read(settingsProvider).biometricEnabled;

    state = BiometricState.available(
      isSupported: true,
      isEnrolled: isEnrolled,
      availableTypes: availableTypes,
      isEnabled: isEnabled,
    );
  }

  Future<void> enableBiometric() async {
    state = const BiometricState.loading();
    
    // Vérifier disponibilité
    final isAvailable = await _service.isBiometricAvailable();
    if (!isAvailable) {
      state = const BiometricState.error(
        message: 'La biométrie n\'est pas disponible sur cet appareil',
        type: BiometricErrorType.notAvailable,
      );
      return;
    }

    await _ref.read(settingsProvider.notifier).setBiometricEnabled(true);
    
    await _checkAvailability();
  }

  Future<void> disableBiometric() async {
    state = const BiometricState.loading();
    
    await _ref.read(settingsProvider.notifier).setBiometricEnabled(false);
    
    await _checkAvailability();
  }

  Future<bool> authenticateWithBiometric({String? userName}) async {
    final currentState = state;
    final available = currentState.maybeWhen(
      available: (_, __, ___, isEnabled) => isEnabled,
      orElse: () => false,
    );

    if (!available) {
      _log.w('Tentative d\'authentification biométrique mais non activée');
      return false;
    }

    state = const BiometricState.loading();

    final reason = userName != null
        ? await _service.getLocalizedReason(userName)
        : 'Authentifiez-vous pour continuer';

    final success = await _service.authenticate(
      localizedReason: reason,
      useErrorDialogs: true,
      stickyAuth: false,
      biometricOnly: false,
    );

    if (success) {
      state = const BiometricState.authenticated();
      // Retourner à l'état available après un court délai
      await Future.delayed(const Duration(milliseconds: 500));
      await _checkAvailability();
      return true;
    } else {
      state = const BiometricState.error(
        message: 'Échec de l\'authentification biométrique',
        type: BiometricErrorType.authenticationFailed,
      );
      await _checkAvailability();
      return false;
    }
  }

  Future<void> refreshAvailability() async {
    await _checkAvailability();
  }

  @override
  void dispose() {
    _service.cancelAuthentication();
    super.dispose();
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────────

final biometricServiceProvider = Provider<BiometricService>((_) => BiometricService());

final biometricProvider =
    StateNotifierProvider<BiometricNotifier, BiometricState>(
        (ref) => BiometricNotifier(ref.watch(biometricServiceProvider), ref));

final isBiometricAvailableProvider = Provider<bool>((ref) {
  return ref.watch(biometricProvider).maybeWhen(
    available: (isSupported, isEnrolled, _, __) => isSupported && isEnrolled,
    orElse: () => false,
  );
});

final isBiometricEnabledProvider = Provider<bool>((ref) {
  return ref.watch(biometricProvider).maybeWhen(
    available: (_, __, ___, isEnabled) => isEnabled,
    orElse: () => false,
  );
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:logger/logger.dart';

import 'package:return_mobile/core/providers/settings_provider.dart';
import 'package:return_mobile/core/services/biometric_service.dart';

part 'biometric_provider.freezed.dart';

final _log = Logger();

// ── BiometricState ────────────────────────────────────────────────────────────

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

// ── BiometricNotifier ─────────────────────────────────────────────────────────

class BiometricNotifier extends StateNotifier<BiometricState> {
  BiometricNotifier(this._service, this._ref) : super(const BiometricState.initial()) {
    _checkAvailability();
  }

  final BiometricService _service;
  final Ref _ref;

  /// Attend que le SettingsNotifier ait fini de charger Hive avant de lire
  /// biometricEnabled. Sans cet await, on lit la valeur par défaut (false)
  /// au lieu de la valeur persistée, ce qui empêche la biométrie de se
  /// déclencher automatiquement au démarrage (race condition).
  Future<void> _waitForSettingsReady() async {
    // SettingsNotifier expose un Future<void> _ready via la propriété `ready`
    // qui se complète après _load(). On attend au maximum 3 secondes.
    final notifier = _ref.read(settingsProvider.notifier);
    await notifier.ready.timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        _log.w('SettingsNotifier.ready timeout — using default biometric=false');
      },
    );
  }

  Future<void> _checkAvailability() async {
    state = const BiometricState.loading();

    // ✅ Fix race condition : attendre la fin du chargement Hive
    await _waitForSettingsReady();

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
    // Lecture safe après await _waitForSettingsReady()
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
    // ✅ Fix race condition : s'assurer que settings est chargé avant de lire isEnabled
    await _waitForSettingsReady();

    final isEnabled = _ref.read(settingsProvider).biometricEnabled;
    if (!isEnabled) {
      _log.w('Tentative d\'auth biométrique mais non activée dans les settings');
      return false;
    }

    final isAvailable = await _service.isBiometricAvailable();
    if (!isAvailable) {
      state = const BiometricState.error(
        message: 'La biométrie n\'est pas disponible ou configurée',
        type: BiometricErrorType.notAvailable,
      );
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

// ── Providers ─────────────────────────────────────────────────────────────────

final biometricServiceProvider =
    Provider<BiometricService>((_) => BiometricService());

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

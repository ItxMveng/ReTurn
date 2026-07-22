import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage.dart';

/// Préférence « verrouillage biométrique activé » (F-03), persistée.
class BiometricEnabledNotifier extends StateNotifier<bool> {
  final SecureStorageService _storage;
  BiometricEnabledNotifier(this._storage) : super(false) {
    _load();
  }

  Future<void> _load() async {
    state = await _storage.isBiometricEnabled();
  }

  Future<void> setEnabled(bool enabled) async {
    await _storage.setBiometricEnabled(enabled);
    state = enabled;
  }
}

final biometricEnabledProvider =
    StateNotifierProvider<BiometricEnabledNotifier, bool>(
  (ref) => BiometricEnabledNotifier(ref.read(secureStorageProvider)),
);

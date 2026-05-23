import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

const _boxName = 'settings';
const _themeKey = 'theme_mode';
const _localeKey = 'locale';
const _biometricEnabledKey = 'biometric_enabled';
const _pinCodeKey = 'pin_code';
const _biometricTimeoutKey = 'biometric_timeout';

enum AppThemeMode { light, dark, nightBlue }

class SettingsState {
  final AppThemeMode themeMode;
  final String? localeCode; // null = system locale
  final bool biometricEnabled;
  final String? pinCode;
  final Duration biometricTimeout;

  const SettingsState({
    this.themeMode = AppThemeMode.light,
    this.localeCode,
    this.biometricEnabled = false,
    this.pinCode,
    this.biometricTimeout = const Duration(minutes: 5),
  });

  SettingsState copyWith({
    AppThemeMode? themeMode,
    Object? localeCode = _sentinel,
    bool? biometricEnabled,
    String? pinCode,
    Duration? biometricTimeout,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      localeCode: localeCode == _sentinel ? this.localeCode : localeCode as String?,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      pinCode: pinCode ?? this.pinCode,
      biometricTimeout: biometricTimeout ?? this.biometricTimeout,
    );
  }

  ThemeMode get flutterThemeMode => themeMode == AppThemeMode.light
      ? ThemeMode.light
      : ThemeMode.dark;

  Locale? get locale => localeCode == null ? null : Locale(localeCode!);
  
  bool get hasPinCode => pinCode != null && pinCode!.isNotEmpty;
}

const _sentinel = Object();

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _load();
  }

  Box? _box;

  Future<void> _load() async {
    _box = await Hive.openBox(_boxName);
    final themeStr = _box!.get(_themeKey, defaultValue: 'light') as String;
    final localeStr = _box!.get(_localeKey) as String?;
    final biometricEnabled = _box!.get(_biometricEnabledKey, defaultValue: false) as bool;
    final pinCode = _box!.get(_pinCodeKey) as String?;
    final timeoutMinutes = _box!.get(_biometricTimeoutKey, defaultValue: 5) as int;
    
    state = SettingsState(
      themeMode: _parseTheme(themeStr),
      localeCode: localeStr,
      biometricEnabled: biometricEnabled,
      pinCode: pinCode,
      biometricTimeout: Duration(minutes: timeoutMinutes),
    );
  }

  AppThemeMode _parseTheme(String s) => switch (s) {
        'dark' => AppThemeMode.dark,
        'nightBlue' => AppThemeMode.nightBlue,
        _ => AppThemeMode.light,
      };

  Future<void> setThemeMode(AppThemeMode mode) async {
    await _box?.put(_themeKey, mode.name);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setLocale(String? code) async {
    if (code == null) {
      await _box?.delete(_localeKey);
    } else {
      await _box?.put(_localeKey, code);
    }
    state = state.copyWith(localeCode: code);
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _box?.put(_biometricEnabledKey, enabled);
    state = state.copyWith(biometricEnabled: enabled);
  }

  Future<void> setPinCode(String? code) async {
    if (code == null) {
      await _box?.delete(_pinCodeKey);
    } else {
      await _box?.put(_pinCodeKey, code);
    }
    state = state.copyWith(pinCode: code);
  }

  Future<void> setBiometricTimeout(Duration timeout) async {
    await _box?.put(_biometricTimeoutKey, timeout.inMinutes);
    state = state.copyWith(biometricTimeout: timeout);
  }

  Future<void> clearBiometricSettings() async {
    await _box?.delete(_biometricEnabledKey);
    await _box?.delete(_pinCodeKey);
    state = state.copyWith(
      biometricEnabled: false,
      pinCode: null,
    );
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>(
        (_) => SettingsNotifier());

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'hive_storage.g.dart';

@Riverpod(keepAlive: true)
HiveStorageService hiveStorage(Ref ref) => HiveStorageService();

const _kProfileBox   = 'profile_cache';
const _kProfileKey   = 'current_user';
const _kSettingsBox  = 'settings';

class HiveStorageService {
  /// Initialiser Hive (appeler dans main() avant runApp)
  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox<Map>(_kProfileBox),
      Hive.openBox<dynamic>(_kSettingsBox),
    ]);
  }

  // ── Profil utilisateur ──────────────────────────────────────
  void cacheProfile(Map<String, dynamic> profile) {
    Hive.box<Map>(_kProfileBox).put(_kProfileKey, profile);
  }

  Map<String, dynamic>? getCachedProfile() {
    final raw = Hive.box<Map>(_kProfileBox).get(_kProfileKey);
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw);
  }

  void clearProfile() => Hive.box<Map>(_kProfileBox).delete(_kProfileKey);

  // ── Settings généraux ───────────────────────────────────────
  T? getSetting<T>(String key) => Hive.box<dynamic>(_kSettingsBox).get(key) as T?;
  Future<void> setSetting<T>(String key, T value) =>
      Hive.box<dynamic>(_kSettingsBox).put(key, value);

  Future<void> clearAll() async {
    await Future.wait([
      Hive.box<Map>(_kProfileBox).clear(),
      Hive.box<dynamic>(_kSettingsBox).clear(),
    ]);
  }
}

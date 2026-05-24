import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'hive_storage.g.dart';

/// Noms de boîtes Hive
const String kBoxDeclarations = 'declarations_cache';
const String kBoxMatches = 'matches_cache';
const String kBoxSettings = 'settings';
const String kBoxProfile = 'profile_cache';

@Riverpod(keepAlive: true)
HiveStorageService hiveStorage(Ref ref) => HiveStorageService();

class HiveStorageService {
  /// Initialisation de Hive — appeler dans main() avant runApp()
  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox<Map>(kBoxDeclarations),
      Hive.openBox<Map>(kBoxMatches),
      Hive.openBox<dynamic>(kBoxSettings),
      Hive.openBox<Map>(kBoxProfile),
    ]);
  }

  // ── Déclarations (cache offline) ─────────────────────────────────────────
  Box<Map> get _declarations => Hive.box<Map>(kBoxDeclarations);

  Future<void> cacheDeclaration(String id, Map<String, dynamic> data) =>
      _declarations.put(id, data);

  Map<String, dynamic>? getDeclaration(String id) =>
      _declarations.get(id)?.cast<String, dynamic>();

  List<Map<String, dynamic>> getAllDeclarations() =>
      _declarations.values.map((e) => e.cast<String, dynamic>()).toList();

  Future<void> deleteDeclaration(String id) => _declarations.delete(id);

  // ── Matchs (cache offline) ───────────────────────────────────────────────
  Box<Map> get _matches => Hive.box<Map>(kBoxMatches);

  Future<void> cacheMatch(String id, Map<String, dynamic> data) =>
      _matches.put(id, data);

  List<Map<String, dynamic>> getAllMatches() =>
      _matches.values.map((e) => e.cast<String, dynamic>()).toList();

  // ── Paramètres ────────────────────────────────────────────────────────────
  Box<dynamic> get _settings => Hive.box<dynamic>(kBoxSettings);

  Future<void> setSetting(String key, dynamic value) => _settings.put(key, value);
  T? getSetting<T>(String key) => _settings.get(key) as T?;

  // ── Profil (cache offline) ───────────────────────────────────────────────
  Box<Map> get _profile => Hive.box<Map>(kBoxProfile);

  Future<void> cacheProfile(Map<String, dynamic> data) =>
      _profile.put('current', data);

  Map<String, dynamic>? getCachedProfile() =>
      _profile.get('current')?.cast<String, dynamic>();

  /// Efface tous les caches (déconnexion)
  Future<void> clearAll() async {
    await Future.wait([
      _declarations.clear(),
      _matches.clear(),
      _profile.clear(),
    ]);
  }
}

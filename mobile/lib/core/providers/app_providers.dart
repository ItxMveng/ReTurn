import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// FlutterSecureStorage — singleton partagé
final secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  ),
);

/// Box Hive pour le cache utilisateur
final userCacheBoxProvider = Provider<Box>(
  (_) => Hive.box('user_cache'),
);

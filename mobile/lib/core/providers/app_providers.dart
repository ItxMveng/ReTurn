import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../storage/secure_storage.dart';
import '../storage/hive_storage.dart';

// ── Secure Storage ─────────────────────────────────────────────
final flutterSecureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  ),
);

final secureStorageProvider = Provider<SecureStorageService>(
  (ref) => SecureStorageService(ref.watch(flutterSecureStorageProvider)),
);

// ── Hive (cache offline) ────────────────────────────────────────
final hiveStorageProvider = Provider<HiveStorageService>((_) => HiveStorageService());

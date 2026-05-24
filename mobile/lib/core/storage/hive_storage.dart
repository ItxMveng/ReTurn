import 'package:hive_flutter/hive_flutter.dart';

class HiveStorageService {
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<String>('cache');
    await Hive.openBox<String>('drafts');
  }

  static Box<String> get cache => Hive.box<String>('cache');
  static Box<String> get drafts => Hive.box<String>('drafts');
}

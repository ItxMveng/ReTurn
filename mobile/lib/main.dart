import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/firebase/firebase_init.dart';
import 'core/providers/settings_provider.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/storage/hive_storage.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/biometric_lock.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveStorageService.init();
  // Initialisation Firebase robuste (avec retries pour les appareils lents).
  // On n'attend pas le résultat dans le flux principal : l'auth réessaiera au
  // besoin, et l'app reste utilisable même si Firebase met du temps.
  ensureFirebaseReady().then((ok) {
    // Notifications push (F-21) : permission + écoute des messages FCM
    // (match, nouveau message…). Nécessite Firebase prêt.
    if (ok) NotificationService.init();
  });
  runApp(const ProviderScope(child: ReTurnApp()));
}

class ReTurnApp extends ConsumerWidget {
  const ReTurnApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final settings = ref.watch(settingsProvider);
    // Synchronise la palette AppColors (legacy) avec le thème courant pour que
    // les écrans basés sur AppColors s'affichent correctement en sombre.
    AppColors.brightness = settings.flutterThemeMode == ThemeMode.dark
        ? Brightness.dark
        : Brightness.light;
    return MaterialApp.router(
      title: 'ReTurn',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.flutterThemeMode,
      routerConfig: router,
      // Verrou biométrique (F-03) superposé à toutes les pages.
      builder: (context, child) =>
          BiometricLock(child: child ?? const SizedBox.shrink()),
      locale: settings.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}

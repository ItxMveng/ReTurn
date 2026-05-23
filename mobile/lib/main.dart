import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:docretour/core/providers/settings_provider.dart';
import 'package:docretour/core/router/app_router.dart';
import 'package:docretour/core/services/notification_service.dart';
import 'package:docretour/core/theme/app_theme.dart';
import 'package:docretour/l10n/app_localizations.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr', null);
  await initializeDateFormatting('en', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Hive.initFlutter();
  await NotificationService.init();
  runApp(const ProviderScope(child: DocRetourApp()));
}

class DocRetourApp extends ConsumerStatefulWidget {
  const DocRetourApp({super.key});

  @override
  ConsumerState<DocRetourApp> createState() => _DocRetourAppState();
}

class _DocRetourAppState extends ConsumerState<DocRetourApp> {
  @override
  void initState() {
    super.initState();
    // Handle notification tap when app was terminated
    FirebaseMessaging.instance.getInitialMessage().then((msg) {
      if (msg != null) _routeFromMessage(msg);
    });
    // Handle notification tap when app was in background
    FirebaseMessaging.onMessageOpenedApp.listen(_routeFromMessage);
  }

  void _routeFromMessage(RemoteMessage msg) {
    final type = msg.data['type'] as String? ?? '';
    final id = msg.data['match_id'] as String? ?? '';
    if (id.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final router = ref.read(routerProvider);
      if (type == 'match_found') {
        router.go('/matches/$id');
      } else if (type == 'new_message') {
        router.go('/matches/$id/chat');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router   = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider);

    final themeMode = settings.themeMode == AppThemeMode.light
        ? ThemeMode.light
        : ThemeMode.dark;

    return MaterialApp.router(
      title: 'ReTurn',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: settings.themeMode == AppThemeMode.nightBlue
          ? nightBlueTheme
          : darkTheme,
      themeMode: themeMode,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (deviceLocale, supported) {
        if (settings.localeCode != null) return settings.locale;
        if (deviceLocale != null) {
          for (final sl in supported) {
            if (sl.languageCode == deviceLocale.languageCode) return sl;
          }
        }
        return const Locale('fr');
      },
      routerConfig: router,
    );
  }
}

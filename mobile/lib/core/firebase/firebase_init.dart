import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// Initialise Firebase de façon robuste.
///
/// Sur certains appareils lents (ex. entrée de gamme), le canal natif de
/// `firebase_core` n'est pas encore connecté au moteur Flutter au tout premier
/// appel `Firebase.initializeApp`, ce qui lève
/// `PlatformException(channel-error, Unable to establish connection on channel)`.
/// On réessaie alors quelques fois avec un court délai, le temps que
/// l'enregistrement natif des plugins se termine.
///
/// Retourne `true` si Firebase est prêt, `false` sinon (l'app continue de
/// fonctionner, mais l'auth Firebase sera indisponible).
Future<bool> ensureFirebaseReady({int maxAttempts = 8}) async {
  if (Firebase.apps.isNotEmpty) return true;

  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      return true;
    } catch (e) {
      // Une autre init concurrente a pu réussir entre-temps.
      if (Firebase.apps.isNotEmpty) return true;
      debugPrint('[Firebase] init tentative $attempt/$maxAttempts échouée : $e');
      if (attempt == maxAttempts) return false;
      await Future.delayed(Duration(milliseconds: 350 * attempt));
    }
  }
  return false;
}

// Ce fichier redirige vers l'architecture unifiée (application/).
// L'ancien AuthNotifier Firebase/StateNotifier a été remplacé.
//
// Utilise directement :
//   - authNotifierProvider  → AuthNotifier (session utilisateur)
//   - otpNotifierProvider   → OtpNotifier  (flux OTP)
//
// depuis : package:docretour/features/auth/application/auth_notifier.dart

export '../../application/auth_notifier.dart'
    show authNotifierProvider, otpNotifierProvider;
export '../../application/auth_state.dart';

// Alias pour compatibilité avec les écrans qui utilisent `authProvider`
import '../../application/auth_notifier.dart' as auth_app;

final authProvider = auth_app.authNotifierProvider;

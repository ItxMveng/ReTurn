// Re-export du nouveau provider Firebase — garder pour compatibilité des imports existants
export 'package:docretour/features/auth/presentation/providers/auth_provider.dart';
// Alias de l'ancien authStateProvider vers le nouveau authProvider
// Les fichiers qui utilisaient authStateProvider.notifier.logout() doivent migrer vers authProvider.notifier

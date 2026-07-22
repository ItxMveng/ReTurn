import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `true` quand l'appareil est hors-ligne (aucune interface réseau active).
/// Alimente le bandeau global « Mode hors ligne » (S-32).
final isOfflineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();

  bool offline(List<ConnectivityResult> r) =>
      r.isEmpty || r.every((c) => c == ConnectivityResult.none);

  // État initial puis flux des changements.
  yield offline(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(offline);
});

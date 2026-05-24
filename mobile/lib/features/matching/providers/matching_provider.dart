import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/matching_repository.dart';
import '../../matches/models/match.dart';

/// Provider liste des matchs actifs
final matchingProvider = FutureProvider<List<Match>>((ref) async {
  final repo = ref.watch(matchingRepositoryProvider);
  return repo.fetchMatches();
});

/// Provider pour confirmer un match
final confirmMatchProvider =
    FutureProvider.family<void, String>((ref, matchId) async {
  final repo = ref.watch(matchingRepositoryProvider);
  await repo.confirmMatch(matchId);
  ref.invalidate(matchingProvider);
});

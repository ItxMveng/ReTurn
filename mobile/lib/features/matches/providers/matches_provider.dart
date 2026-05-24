import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/matches_repository.dart';
import '../models/match.dart';

final matchesProvider = FutureProvider<List<Match>>((ref) async {
  final repo = ref.watch(matchesRepositoryProvider);
  return repo.fetchMatches();
});

final matchDetailProvider =
    FutureProvider.family<Match, String>((ref, id) async {
  final repo = ref.watch(matchesRepositoryProvider);
  return repo.fetchMatch(id);
});

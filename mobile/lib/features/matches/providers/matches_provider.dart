import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/match_model.dart';
import '../repositories/matches_repository.dart';

final matchesProvider =
    FutureProvider<List<MatchModel>>((ref) async {
  return ref.read(matchesRepositoryProvider).list();
});

final matchDetailProvider =
    FutureProvider.family<MatchModel, String>((ref, id) async {
  return ref.read(matchesRepositoryProvider).get(id);
});

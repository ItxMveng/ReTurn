import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/models/match_model.dart';
import '../data/repositories/matches_repository.dart';

part 'matches_provider.g.dart';

@riverpod
class MatchesNotifier extends _$MatchesNotifier {
  @override
  Future<List<MatchModel>> build() async {
    return ref.read(matchesRepositoryProvider).listMyMatches();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ref.read(matchesRepositoryProvider).listMyMatches());
  }

  Future<void> confirm(String matchId) async {
    await ref.read(matchesRepositoryProvider).confirmMatch(matchId);
    await refresh();
  }

  Future<void> reject(String matchId) async {
    await ref.read(matchesRepositoryProvider).rejectMatch(matchId);
    await refresh();
  }
}

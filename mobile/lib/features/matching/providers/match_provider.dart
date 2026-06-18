import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:return_mobile/features/matching/repositories/match_repository.dart';
import 'package:return_mobile/shared/models/match.dart';

export 'package:return_mobile/features/matching/repositories/match_repository.dart'
    show matchRepositoryProvider;

final matchListProvider =
    AsyncNotifierProvider<MatchListNotifier, List<Match>>(
        MatchListNotifier.new);

class MatchListNotifier extends AsyncNotifier<List<Match>> {
  MatchRepository get _repo => ref.read(matchRepositoryProvider);

  @override
  Future<List<Match>> build() => _repo.listMatches();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repo.listMatches);
  }

  Future<void> confirm(String id) => _act(id, 'confirmed');
  Future<void> ignore(String id) => _act(id, 'ignored');

  Future<void> _act(String id, String action) async {
    final updated = await _repo.actOnMatch(id, action);
    state = AsyncData(
      state.valueOrNull
              ?.map((m) => m.id == id ? updated : m)
              .toList() ??
          [],
    );
  }
}

final notificationCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.read(matchRepositoryProvider);
  final data = await repo.getNotifications();
  return data['count'] as int? ?? 0;
});

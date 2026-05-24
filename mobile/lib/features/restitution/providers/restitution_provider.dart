import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:docretour/features/restitution/repositories/restitution_repository.dart';
import 'package:docretour/shared/models/restitution.dart';

export 'package:docretour/features/restitution/repositories/restitution_repository.dart'
    show restitutionRepositoryProvider;

// ── Liste de toutes les restitutions ─────────────────────────────────────────────
final restitutionListProvider =
    AsyncNotifierProvider<RestitutionListNotifier, List<Restitution>>(
        RestitutionListNotifier.new);

class RestitutionListNotifier extends AsyncNotifier<List<Restitution>> {
  RestitutionRepository get _repo => ref.read(restitutionRepositoryProvider);

  @override
  Future<List<Restitution>> build() => _repo.listMyRestitutions();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repo.listMyRestitutions);
  }

  Future<Restitution> create({
    required String matchId,
    String? meetingLocation,
    DateTime? meetingScheduledAt,
  }) async {
    final r = await _repo.create(
      matchId: matchId,
      meetingLocation: meetingLocation,
      meetingScheduledAt: meetingScheduledAt,
    );
    state = AsyncData([r, ...?state.valueOrNull]);
    return r;
  }

  Future<void> _updateInList(Future<Restitution> Function() action) async {
    final updated = await action();
    state = AsyncData(
      state.valueOrNull
              ?.map((r) => r.id == updated.id ? updated : r)
              .toList() ??
          [updated],
    );
  }

  Future<void> complete(String id) =>
      _updateInList(() => _repo.complete(id));

  Future<void> cancel(String id) =>
      _updateInList(() => _repo.cancel(id));

  Future<void> rate(String id, double rating) =>
      _updateInList(() => _repo.rate(id, rating));

  Future<void> dispute(String id, {String? reason}) =>
      _updateInList(() => _repo.dispute(id, reason: reason));
}

// ── Détail d'une restitution (family) ─────────────────────────────────────────
final restitutionDetailProvider =
    FutureProvider.family<Restitution, String>((ref, id) {
  return ref.read(restitutionRepositoryProvider).getById(id);
});

// ── Providers dérivés (filtres) ────────────────────────────────────────────────
final activeRestituionsProvider = Provider<List<Restitution>>((ref) {
  return ref.watch(restitutionListProvider).valueOrNull
          ?.where((r) => r.isActive)
          .toList() ??
      [];
});

final completedRestitutionsProvider = Provider<List<Restitution>>((ref) {
  return ref.watch(restitutionListProvider).valueOrNull
          ?.where((r) => r.isCompleted)
          .toList() ??
      [];
});

final pendingRatingProvider = Provider<List<Restitution>>((ref) {
  // Restitutions complétées où l'utilisateur n'a pas encore noté
  // (on ne peut pas filtrer par userId ici sans authProvider — fait dans le screen)
  return ref.watch(restitutionListProvider).valueOrNull
          ?.where((r) => r.isCompleted)
          .toList() ??
      [];
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/errors/error_handler.dart';
import '../data/models/match_model.dart';
import '../data/models/restitution_model.dart';
import '../data/repositories/matches_repository.dart';

part 'matches_notifier.g.dart';

// ── Matches list notifier ────────────────────────────────────────

class MatchesState {
  const MatchesState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });
  final List<MatchModel> items;
  final bool isLoading;
  final String? error;

  MatchesState copyWith({List<MatchModel>? items, bool? isLoading, String? error}) =>
      MatchesState(items: items ?? this.items, isLoading: isLoading ?? this.isLoading, error: error);

  /// Matchs par statut
  List<MatchModel> get pending   => items.where((m) => m.isPending).toList();
  List<MatchModel> get confirmed => items.where((m) => m.isConfirmed).toList();
  List<MatchModel> get completed => items.where((m) => m.isCompleted).toList();
}

@riverpod
class MatchesNotifier extends _$MatchesNotifier {
  @override
  MatchesState build() {
    fetch();
    return const MatchesState(isLoading: true);
  }

  MatchesRepository get _repo => ref.read(matchesRepositoryProvider);

  Future<void> fetch() async {
    state = state.copyWith(isLoading: true);
    try {
      final items = await _repo.listMatches();
      state = MatchesState(items: items);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: friendlyError(e));
    }
  }

  /// Confirme ou ignore un match, met à jour localement
  Future<MatchActionResponse?> actOnMatch(String matchId, String action) async {
    try {
      final response = await _repo.actOnMatch(matchId, action);
      // Mise à jour locale du match
      final updatedItems = state.items.map((m) {
        if (m.id != matchId) return m;
        String newStatus = m.status;
        if (action == 'ignored') newStatus = 'ignored';
        else if (response.bothConfirmed) newStatus = 'confirmed';
        return m.copyWith(
          status: newStatus,
          confirmedByOwner: response.confirmedByOwner,
          confirmedByFinder: response.confirmedByFinder,
          restitutionId: response.restitutionId,
        );
      }).toList();
      state = state.copyWith(items: updatedItems);
      return response;
    } catch (e) {
      state = state.copyWith(error: friendlyError(e));
      return null;
    }
  }
}

/// Provider pour le détail d’un match
@riverpod
Future<MatchModel> matchDetail(Ref ref, String id) {
  return ref.watch(matchesRepositoryProvider).getMatch(id);
}

/// Provider pour le détail d’une restitution
@riverpod
Future<RestitutionModel> restitutionDetail(Ref ref, String id) {
  return ref.watch(matchesRepositoryProvider).getRestitution(id);
}

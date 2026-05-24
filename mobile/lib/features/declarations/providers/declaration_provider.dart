import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:docretour/features/declarations/repositories/declaration_repository.dart';
import 'package:docretour/features/matching/providers/match_provider.dart';
import 'package:docretour/shared/models/declaration.dart';

final declarationListProvider =
    AsyncNotifierProvider<DeclarationListNotifier, List<Declaration>>(
        DeclarationListNotifier.new);

class DeclarationListNotifier extends AsyncNotifier<List<Declaration>> {
  DeclarationRepository get _repo =>
      ref.read(declarationRepositoryProvider);

  @override
  Future<List<Declaration>> build() {
    // Écouter les changements de matchs pour auto-synchroniser les statuts
    ref.listen(matchListProvider, (_, next) {
      next.whenData((matches) => _syncStatusFromMatches(matches));
    });
    return _repo.listMyDeclarations();
  }

  /// Met à jour automatiquement le statut des déclarations selon les matchs actifs
  void _syncStatusFromMatches(List<dynamic> matches) {
    final current = state.valueOrNull;
    if (current == null) return;
    final matchedDeclIds = <String>{};
    for (final m in matches) {
      // Un match actif (non rejeté) marque les deux déclarations comme 'matched'
      if (m.status != 'rejected') {
        matchedDeclIds.add(m.declarationFoundId as String);
        matchedDeclIds.add(m.declarationLostId as String);
      }
    }
    final updated = current.map((d) {
      if (matchedDeclIds.contains(d.id) && d.status == 'active') {
        return d.copyWith(status: 'matched');
      }
      return d;
    }).toList();
    if (updated != current) {
      state = AsyncData(updated);
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repo.listMyDeclarations);
  }

  Future<Declaration> create({
    required String declarationType,
    required String documentType,
    String? documentNumber,
    String? ownerName,
    String? description,
    double? latitude,
    double? longitude,
    String? locationDescription,
    List<String> photoPaths = const [],
  }) async {
    final decl = await _repo.createDeclaration(
      declarationType: declarationType,
      documentType: documentType,
      documentNumber: documentNumber,
      ownerName: ownerName,
      description: description,
      latitude: latitude,
      longitude: longitude,
      locationDescription: locationDescription,
      photoPaths: photoPaths,
    );
    state = AsyncData([decl, ...?state.valueOrNull]);
    return decl;
  }

  Future<void> delete(String id) async {
    await _repo.deleteDeclaration(id);
    state = AsyncData(
      state.valueOrNull?.where((d) => d.id != id).toList() ?? [],
    );
  }
}

final documentTypesProvider = FutureProvider<List<String>>((ref) {
  return ref.read(declarationRepositoryProvider).getDocumentTypes();
});

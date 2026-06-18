import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/errors/error_handler.dart';
import '../data/models/declaration_model.dart';
import '../data/repositories/declarations_repository.dart';

part 'declarations_notifier.g.dart';

// ── State ───────────────────────────────────────────────────────────

class DeclarationsState {
  const DeclarationsState({
    this.items = const [],
    this.isLoading = false,
    this.isFetchingMore = false,
    this.hasMore = true,
    this.error,
    this.cursor,
  });

  final List<DeclarationModel> items;
  final bool isLoading;
  final bool isFetchingMore;
  final bool hasMore;
  final String? error;
  final String? cursor; // ISO datetime du dernier item

  DeclarationsState copyWith({
    List<DeclarationModel>? items,
    bool? isLoading,
    bool? isFetchingMore,
    bool? hasMore,
    String? error,
    String? cursor,
  }) {
    return DeclarationsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      cursor: cursor ?? this.cursor,
    );
  }
}

// ── Notifier ───────────────────────────────────────────────────────

@riverpod
class DeclarationsNotifier extends _$DeclarationsNotifier {
  @override
  DeclarationsState build() {
    fetch();
    return const DeclarationsState(isLoading: true);
  }

  DeclarationsRepository get _repo => ref.read(declarationsRepositoryProvider);

  /// Charge la première page
  Future<void> fetch() async {
    state = state.copyWith(isLoading: true, cursor: null);
    try {
      final items = await _repo.listDeclarations();
      state = DeclarationsState(
        items: items,
        isLoading: false,
        hasMore: items.length == 20,
        cursor: items.isNotEmpty ? items.last.createdAt : null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: friendlyError(e));
    }
  }

  /// Pagination — charge la page suivante
  Future<void> fetchMore() async {
    if (!state.hasMore || state.isFetchingMore || state.cursor == null) return;
    state = state.copyWith(isFetchingMore: true);
    try {
      final more = await _repo.listDeclarations(cursor: state.cursor);
      state = state.copyWith(
        items: [...state.items, ...more],
        isFetchingMore: false,
        hasMore: more.length == 20,
        cursor: more.isNotEmpty ? more.last.createdAt : state.cursor,
      );
    } catch (e) {
      state = state.copyWith(isFetchingMore: false, error: friendlyError(e));
    }
  }

  /// Rafraîchissement
  Future<void> refresh() => fetch();

  /// Suppression locale + API
  Future<void> delete(String id) async {
    try {
      await _repo.deleteDeclaration(id);
      state = state.copyWith(
        items: state.items.where((d) => d.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: friendlyError(e));
    }
  }

  /// Ajout optimiste après création
  void addItem(DeclarationModel decl) {
    state = state.copyWith(items: [decl, ...state.items]);
  }

  /// Création d'une déclaration via l'API
  Future<DeclarationModel?> create(Map<String, dynamic> payload) async {
    try {
      final decl = await _repo.createDeclaration(payload);
      addItem(decl);
      return decl;
    } catch (e) {
      state = state.copyWith(error: friendlyError(e));
      return null;
    }
  }
}

/// Provider pour le détail d’une déclaration spécifique
@riverpod
Future<DeclarationModel> declarationDetail(Ref ref, String id) {
  return ref.watch(declarationsRepositoryProvider).getDeclaration(id);
}

/// Provider pour les types de documents
@riverpod
Future<List<String>> documentTypes(Ref ref) {
  return ref.watch(declarationsRepositoryProvider).getDocumentTypes();
}

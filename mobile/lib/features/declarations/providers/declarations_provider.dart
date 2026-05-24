import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/models/declaration_model.dart';
import '../data/repositories/declarations_repository.dart';

part 'declarations_provider.g.dart';

@riverpod
class DeclarationsNotifier extends _$DeclarationsNotifier {
  @override
  Future<List<DeclarationModel>> build() async {
    return _fetch();
  }

  Future<List<DeclarationModel>> _fetch({String? type}) {
    return ref
        .read(declarationsRepositoryProvider)
        .listDeclarations(type: type);
  }

  Future<void> refresh({String? type}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch(type: type));
  }

  Future<void> create(Map<String, dynamic> payload) async {
    await ref.read(declarationsRepositoryProvider).createDeclaration(payload);
    await refresh();
  }
}

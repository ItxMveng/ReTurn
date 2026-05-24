import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/declaration.dart';
import '../repositories/declarations_repository.dart';

final declarationsProvider =
    FutureProvider<List<Declaration>>((ref) async {
  final repo = ref.read(declarationsRepositoryProvider);
  return repo.list();
});

final declarationDetailProvider =
    FutureProvider.family<Declaration, String>((ref, id) async {
  final repo = ref.read(declarationsRepositoryProvider);
  return repo.get(id);
});

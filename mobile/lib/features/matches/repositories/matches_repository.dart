import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/match.dart';

final matchesRepositoryProvider =
    Provider<MatchesRepository>((ref) => MatchesRepository(ref));

class MatchesRepository {
  MatchesRepository(this._ref);
  final Ref _ref;

  Future<List<Match>> fetchMatches() async {
    final client = _ref.read(apiClientProvider);
    final res = await client.get('/matches');
    return (res.data as List)
        .map((e) => Match.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Match> fetchMatch(String id) async {
    final client = _ref.read(apiClientProvider);
    final res = await client.get('/matches/$id');
    return Match.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> confirmMatch(String id) async {
    final client = _ref.read(apiClientProvider);
    await client.patch('/matches/$id/confirm');
  }
}

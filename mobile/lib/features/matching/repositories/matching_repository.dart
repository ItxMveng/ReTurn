import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../matches/models/match.dart';

final matchingRepositoryProvider =
    Provider<MatchingRepository>((ref) => MatchingRepository(ref));

class MatchingRepository {
  MatchingRepository(this._ref);
  final Ref _ref;

  Future<List<Match>> fetchMatches() async {
    final client = _ref.read(apiClientProvider);
    final res = await client.get('/matches');
    final data = res.data as List<dynamic>;
    return data.map((e) => Match.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> confirmMatch(String id) async {
    final client = _ref.read(apiClientProvider);
    await client.patch('/matches/$id/confirm');
  }
}

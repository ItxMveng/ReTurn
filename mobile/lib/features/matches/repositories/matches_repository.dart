import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/match.dart';

final matchesRepositoryProvider =
    Provider<MatchesRepository>((ref) => MatchesRepository(ref));

class MatchesRepository {
  MatchesRepository(this._ref);
  final Ref _ref;

  ApiClient get _client => _ref.read(apiClientProvider);

  Future<List<Match>> fetchMatches() async {
    final res = await _client.get<List<dynamic>>(
      '/matches',
      fromJson: (d) => d as List<dynamic>,
    );
    return res.map((e) => Match.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Match> fetchMatch(String id) async {
    return _client.get<Match>(
      '/matches/$id',
      fromJson: (d) => Match.fromJson(d as Map<String, dynamic>),
    );
  }

  Future<void> confirmMatch(String id) async {
    await _client.patch<Map<String, dynamic>>(
      '/matches/$id/confirm',
      fromJson: (d) => d as Map<String, dynamic>,
    );
  }

  Future<void> rejectMatch(String id) async {
    await _client.patch<Map<String, dynamic>>(
      '/matches/$id/reject',
      fromJson: (d) => d as Map<String, dynamic>,
    );
  }
}

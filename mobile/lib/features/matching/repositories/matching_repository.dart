import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../matches/models/match.dart';

final matchingRepositoryProvider =
    Provider<MatchingRepository>((ref) => MatchingRepository(ref));

class MatchingRepository {
  MatchingRepository(this._ref);
  final Ref _ref;

  ApiClient get _client => _ref.read(apiClientProvider);

  Future<List<Match>> fetchMatches() async {
    final data = await _client.get<List<dynamic>>(
      '/matches',
      fromJson: (d) => d as List<dynamic>,
    );
    return data.map((e) => Match.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> confirmMatch(String id) async {
    await _client.patch<Map<String, dynamic>>(
      '/matches/$id/confirm',
      fromJson: (d) => d as Map<String, dynamic>,
    );
  }
}

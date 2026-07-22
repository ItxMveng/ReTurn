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
    // Slash final obligatoire : le backend expose GET /matches/ ; sans slash
    // FastAPI renvoie un redirect 307 qui peut casser certains clients.
    final res = await _client.get<List<dynamic>>(
      '/matches/',
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

  /// Notifications en attente (Redis, 7 jours) : matchs détectés, etc.
  Future<List<Map<String, dynamic>>> notifications() async {
    final res = await _client.get<Map<String, dynamic>>(
      '/matches/notifications',
      fromJson: (d) => (d as Map).cast<String, dynamic>(),
    );
    final items = res['notifications'] as List? ?? const [];
    return items
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();
  }

  Future<void> clearNotifications() async {
    await _client.delete('/matches/notifications');
  }

  // Le backend expose un unique endpoint POST /matches/{id}/action
  // avec body {"action": "confirmed" | "ignored"}.
  Future<void> confirmMatch(String id) async {
    await _client.post<Map<String, dynamic>>(
      '/matches/$id/action',
      body: {'action': 'confirmed'},
      fromJson: (d) => d as Map<String, dynamic>,
    );
  }

  Future<void> rejectMatch(String id) async {
    await _client.post<Map<String, dynamic>>(
      '/matches/$id/action',
      body: {'action': 'ignored'},
      fromJson: (d) => d as Map<String, dynamic>,
    );
  }
}

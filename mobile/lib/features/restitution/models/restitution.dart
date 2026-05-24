class Restitution {
  final String id;
  final String matchId;
  final String status;
  final String? codeConfirmation;
  final double? ratingFinder;
  final double? ratingOwner;
  final DateTime createdAt;

  const Restitution({
    required this.id,
    required this.matchId,
    required this.status,
    this.codeConfirmation,
    this.ratingFinder,
    this.ratingOwner,
    required this.createdAt,
  });

  factory Restitution.fromJson(Map<String, dynamic> j) => Restitution(
        id: j['id'] as String,
        matchId: j['match_id'] as String,
        status: j['status'] as String,
        codeConfirmation: j['code_confirmation'] as String?,
        ratingFinder: (j['rating_finder'] as num?)?.toDouble(),
        ratingOwner: (j['rating_owner'] as num?)?.toDouble(),
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

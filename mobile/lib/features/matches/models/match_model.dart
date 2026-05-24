class MatchModel {
  final String id;
  final String declarationFoundId;
  final String declarationLostId;
  final double score;
  final String status;
  final DateTime createdAt;

  const MatchModel({
    required this.id,
    required this.declarationFoundId,
    required this.declarationLostId,
    required this.score,
    required this.status,
    required this.createdAt,
  });

  factory MatchModel.fromJson(Map<String, dynamic> j) => MatchModel(
        id: j['id'] as String,
        declarationFoundId: j['declaration_found_id'] as String,
        declarationLostId: j['declaration_lost_id'] as String,
        score: (j['score'] as num).toDouble(),
        status: j['status'] as String,
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  int get scorePercent => (score * 100).round();
  bool get isConfirmed => status == 'confirmed';
  bool get isPending => status == 'pending';
}

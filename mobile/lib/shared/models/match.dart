import 'package:return_mobile/shared/models/declaration.dart';

class Match {
  final String id;
  final String declarationFoundId;
  final String declarationLostId;
  final String userFoundId;
  final String userLostId;
  final double score;
  final String status; // pending | confirmed | ignored | closed
  final DateTime createdAt;
  final Declaration? declarationFound;
  final Declaration? declarationLost;

  const Match({
    required this.id,
    required this.declarationFoundId,
    required this.declarationLostId,
    required this.userFoundId,
    required this.userLostId,
    required this.score,
    required this.status,
    required this.createdAt,
    this.declarationFound,
    this.declarationLost,
  });

  factory Match.fromJson(Map<String, dynamic> json) => Match(
        id: json['id'] as String,
        declarationFoundId: json['declaration_found_id'] as String,
        declarationLostId: json['declaration_lost_id'] as String,
        userFoundId: json['user_found_id'] as String,
        userLostId: json['user_lost_id'] as String,
        score: (json['score'] as num).toDouble(),
        status: json['status'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        declarationFound: json['declaration_found'] != null
            ? DeclarationModel.fromJson(
                json['declaration_found'] as Map<String, dynamic>)
            : null,
        declarationLost: json['declaration_lost'] != null
            ? DeclarationModel.fromJson(
                json['declaration_lost'] as Map<String, dynamic>)
            : null,
      );

  int get scorePercent => (score * 100).round();
  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'match_model.freezed.dart';
part 'match_model.g.dart';

/// Réponse de l'API lors d'une action sur un match (confirm/ignore)
class MatchActionResponse {
  final bool bothConfirmed;
  final bool? confirmedByOwner;
  final bool? confirmedByFinder;
  final String? restitutionId;

  const MatchActionResponse({
    required this.bothConfirmed,
    this.confirmedByOwner,
    this.confirmedByFinder,
    this.restitutionId,
  });

  factory MatchActionResponse.fromJson(Map<String, dynamic> json) =>
      MatchActionResponse(
        bothConfirmed: json['both_confirmed'] as bool? ?? false,
        confirmedByOwner: json['confirmed_by_owner'] as bool?,
        confirmedByFinder: json['confirmed_by_finder'] as bool?,
        restitutionId: json['restitution_id'] as String?,
      );
}

@freezed
class MatchModel with _$MatchModel {
  const MatchModel._(); // nécessaire pour les getters sur un freezed

  const factory MatchModel({
    required String id,
    @JsonKey(name: 'found_declaration_id') required String foundDeclarationId,
    @JsonKey(name: 'lost_declaration_id') required String lostDeclarationId,
    @JsonKey(name: 'score') required double score,
    @JsonKey(name: 'status') @Default('pending') String status,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'confirmed_by_owner') bool? confirmedByOwner,
    @JsonKey(name: 'confirmed_by_finder') bool? confirmedByFinder,
    @JsonKey(name: 'restitution_id') String? restitutionId,
  }) = _MatchModel;

  factory MatchModel.fromJson(Map<String, dynamic> json) =>
      _$MatchModelFromJson(json);

  // ── Getters utilitaires ──────────────────────────────────────────────
  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCompleted => status == 'completed';
  bool get isIgnored => status == 'ignored';

  double get scorePercent => score * 100;

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'confirmed':
        return 'Confirmé';
      case 'completed':
        return 'Terminé';
      case 'ignored':
        return 'Ignoré';
      default:
        return status;
    }
  }
}

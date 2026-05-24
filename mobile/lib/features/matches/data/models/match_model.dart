import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../declarations/data/models/declaration_model.dart';

part 'match_model.freezed.dart';
part 'match_model.g.dart';

/// Correspond à MatchRead du backend
@freezed
class MatchModel with _$MatchModel {
  const factory MatchModel({
    required String id,
    @JsonKey(name: 'declaration_found_id') required String declarationFoundId,
    @JsonKey(name: 'declaration_lost_id')  required String declarationLostId,
    @JsonKey(name: 'user_found_id')        required String userFoundId,
    @JsonKey(name: 'user_lost_id')         required String userLostId,
    @JsonKey(name: 'score',  defaultValue: 0.0) required double score,
    @JsonKey(name: 'status', defaultValue: 'pending') required String status,
    @JsonKey(name: 'confirmed_by_owner',  defaultValue: false) required bool confirmedByOwner,
    @JsonKey(name: 'confirmed_by_finder', defaultValue: false) required bool confirmedByFinder,
    @JsonKey(name: 'restitution_id') String? restitutionId,
    @JsonKey(name: 'declaration_found') DeclarationModel? declarationFound,
    @JsonKey(name: 'declaration_lost')  DeclarationModel? declarationLost,
    @JsonKey(name: 'created_at') required String createdAt,
  }) = _MatchModel;

  factory MatchModel.fromJson(Map<String, dynamic> json) =>
      _$MatchModelFromJson(json);
}

extension MatchModelX on MatchModel {
  int get scorePercent => (score * 100).round().clamp(0, 100);
  bool get isPending   => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isIgnored   => status == 'ignored';
  bool get isCompleted => status == 'completed';

  String get statusLabel {
    switch (status) {
      case 'pending':   return 'En attente';
      case 'confirmed': return 'Confirmé';
      case 'ignored':   return 'Ignoré';
      case 'completed': return 'Terminé';
      default:          return status;
    }
  }
}

/// Réponse de l’action confirm/ignore
@freezed
class MatchActionResponse with _$MatchActionResponse {
  const factory MatchActionResponse({
    @JsonKey(name: 'match_id')           required String matchId,
    @JsonKey(name: 'confirmed_by_owner',  defaultValue: false) required bool confirmedByOwner,
    @JsonKey(name: 'confirmed_by_finder', defaultValue: false) required bool confirmedByFinder,
    @JsonKey(name: 'both_confirmed',      defaultValue: false) required bool bothConfirmed,
    @JsonKey(name: 'restitution_id') String? restitutionId,
  }) = _MatchActionResponse;

  factory MatchActionResponse.fromJson(Map<String, dynamic> json) =>
      _$MatchActionResponseFromJson(json);
}

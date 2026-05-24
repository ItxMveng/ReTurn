import 'package:freezed_annotation/freezed_annotation.dart';

part 'match_model.freezed.dart';
part 'match_model.g.dart';

@freezed
class MatchModel with _$MatchModel {
  const factory MatchModel({
    required String id,
    @JsonKey(name: 'found_declaration_id') required String foundDeclarationId,
    @JsonKey(name: 'lost_declaration_id') required String lostDeclarationId,
    @JsonKey(name: 'score') required double score,
    @JsonKey(name: 'status') @Default('pending') String status,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _MatchModel;

  factory MatchModel.fromJson(Map<String, dynamic> json) =>
      _$MatchModelFromJson(json);
}

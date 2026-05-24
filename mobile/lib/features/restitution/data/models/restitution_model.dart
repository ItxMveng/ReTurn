import 'package:freezed_annotation/freezed_annotation.dart';

part 'restitution_model.freezed.dart';
part 'restitution_model.g.dart';

@freezed
class RestitutionModel with _$RestitutionModel {
  const factory RestitutionModel({
    required String id,
    @JsonKey(name: 'match_id') required String matchId,
    @JsonKey(name: 'status') @Default('pending') String status,
    @JsonKey(name: 'meeting_place') String? meetingPlace,
    @JsonKey(name: 'meeting_time') DateTime? meetingTime,
    @JsonKey(name: 'photo_proof_url') String? photoProofUrl,
    @JsonKey(name: 'finder_rating') double? finderRating,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _RestitutionModel;

  factory RestitutionModel.fromJson(Map<String, dynamic> json) =>
      _$RestitutionModelFromJson(json);
}

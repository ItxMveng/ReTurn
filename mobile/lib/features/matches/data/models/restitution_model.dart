import 'package:freezed_annotation/freezed_annotation.dart';

part 'restitution_model.freezed.dart';
part 'restitution_model.g.dart';

@freezed
class RestitutionModel with _$RestitutionModel {
  const factory RestitutionModel({
    required String id,
    @JsonKey(name: 'match_id')    required String matchId,
    @JsonKey(name: 'status', defaultValue: 'pending') required String status,
    @JsonKey(name: 'meeting_point') String? meetingPoint,
    @JsonKey(name: 'scheduled_at') String? scheduledAt,
    @JsonKey(name: 'completed_at') String? completedAt,
    @JsonKey(name: 'proof_photo_urls', defaultValue: <String>[]) required List<String> proofPhotoUrls,
    @JsonKey(name: 'rating_by_owner',  defaultValue: 0) required int ratingByOwner,
    @JsonKey(name: 'rating_by_finder', defaultValue: 0) required int ratingByFinder,
    @JsonKey(name: 'created_at') required String createdAt,
  }) = _RestitutionModel;

  factory RestitutionModel.fromJson(Map<String, dynamic> json) =>
      _$RestitutionModelFromJson(json);
}

extension RestitutionModelX on RestitutionModel {
  bool get isPending   => status == 'pending';
  bool get isCompleted => status == 'completed';

  String get statusLabel {
    switch (status) {
      case 'pending':   return 'En attente de rendez-vous';
      case 'scheduled': return 'Rendez-vous planifié';
      case 'completed': return 'Restitution effectuée';
      default:          return status;
    }
  }
}

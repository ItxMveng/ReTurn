import 'package:freezed_annotation/freezed_annotation.dart';

part 'declaration_model.freezed.dart';
part 'declaration_model.g.dart';

enum DeclarationType { found, lost }

@freezed
class DeclarationModel with _$DeclarationModel {
  const factory DeclarationModel({
    required String id,
    @JsonKey(name: 'declaration_type') required String declarationType,
    @JsonKey(name: 'document_type') required String documentType,
    @JsonKey(name: 'owner_name') required String ownerName,
    String? description,
    @JsonKey(name: 'location_name') String? locationName,
    double? latitude,
    double? longitude,
    @JsonKey(name: 'photo_url') String? photoUrl,
    @JsonKey(name: 'status') @Default('active') String status,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'user_id') String? userId,
  }) = _DeclarationModel;

  factory DeclarationModel.fromJson(Map<String, dynamic> json) =>
      _$DeclarationModelFromJson(json);
}

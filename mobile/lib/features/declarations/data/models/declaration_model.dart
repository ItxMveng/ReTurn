import 'package:freezed_annotation/freezed_annotation.dart';

part 'declaration_model.freezed.dart';
part 'declaration_model.g.dart';

/// Correspond à DeclarationRead du backend
@freezed
class DeclarationModel with _$DeclarationModel {
  const factory DeclarationModel({
    required String id,
    @JsonKey(name: 'declaration_type') required String declarationType,   // 'found' | 'lost'
    @JsonKey(name: 'document_type')   required String documentType,
    @JsonKey(name: 'document_number') String? documentNumber,
    @JsonKey(name: 'owner_name')      String? ownerName,
    String? description,
    double? latitude,
    double? longitude,
    @JsonKey(name: 'location_description') String? locationDescription,
    @JsonKey(name: 'event_date') String? eventDate,
    @JsonKey(name: 'status', defaultValue: 'active') required String status,
    @JsonKey(name: 'photo_urls', defaultValue: <String>[]) required List<String> photoUrls,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
    @JsonKey(name: 'user_id') required String userId,
  }) = _DeclarationModel;

  factory DeclarationModel.fromJson(Map<String, dynamic> json) =>
      _$DeclarationModelFromJson(json);
}

extension DeclarationModelX on DeclarationModel {
  bool get isFound => declarationType == 'found';
  bool get isLost  => declarationType == 'lost';

  String get typeLabel     => isFound ? 'Document trouvé' : 'Document perdu';
  String get documentLabel => documentType.replaceAll('_', ' ').toUpperCase();
}

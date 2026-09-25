// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'declaration_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

DeclarationModel _$DeclarationModelFromJson(Map<String, dynamic> json) {
  return _DeclarationModel.fromJson(json);
}

/// @nodoc
mixin _$DeclarationModel {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'declaration_type')
  String get declarationType => throw _privateConstructorUsedError;
  @JsonKey(name: 'document_type')
  String get documentType => throw _privateConstructorUsedError;
  @JsonKey(name: 'owner_name')
  String? get ownerName => throw _privateConstructorUsedError;
  String? get description =>
      throw _privateConstructorUsedError; // Champs localisation
  @JsonKey(name: 'location_name')
  String? get locationName => throw _privateConstructorUsedError;
  @JsonKey(name: 'location_description')
  String? get locationDescription => throw _privateConstructorUsedError;
  double? get latitude => throw _privateConstructorUsedError;
  double? get longitude =>
      throw _privateConstructorUsedError; // Photos : l'API peut renvoyer une URL unique ou une liste
  @JsonKey(name: 'photo_url')
  String? get photoUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'photo_urls')
  List<String> get photoUrls =>
      throw _privateConstructorUsedError; // Numéro de document (optionnel)
  @JsonKey(name: 'document_number')
  String? get documentNumber =>
      throw _privateConstructorUsedError; // Date de l'événement
  @JsonKey(name: 'event_date')
  DateTime? get eventDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'status')
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String? get userId =>
      throw _privateConstructorUsedError; // Dossier multi-documents : plusieurs déclarations d'un même dépôt
// (un propriétaire, plusieurs documents) partagent ce group_id.
  @JsonKey(name: 'group_id')
  String? get groupId => throw _privateConstructorUsedError;

  /// Serializes this DeclarationModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DeclarationModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DeclarationModelCopyWith<DeclarationModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeclarationModelCopyWith<$Res> {
  factory $DeclarationModelCopyWith(
          DeclarationModel value, $Res Function(DeclarationModel) then) =
      _$DeclarationModelCopyWithImpl<$Res, DeclarationModel>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'declaration_type') String declarationType,
      @JsonKey(name: 'document_type') String documentType,
      @JsonKey(name: 'owner_name') String? ownerName,
      String? description,
      @JsonKey(name: 'location_name') String? locationName,
      @JsonKey(name: 'location_description') String? locationDescription,
      double? latitude,
      double? longitude,
      @JsonKey(name: 'photo_url') String? photoUrl,
      @JsonKey(name: 'photo_urls') List<String> photoUrls,
      @JsonKey(name: 'document_number') String? documentNumber,
      @JsonKey(name: 'event_date') DateTime? eventDate,
      @JsonKey(name: 'status') String status,
      @JsonKey(name: 'created_at') String? createdAt,
      @JsonKey(name: 'user_id') String? userId,
      @JsonKey(name: 'group_id') String? groupId});
}

/// @nodoc
class _$DeclarationModelCopyWithImpl<$Res, $Val extends DeclarationModel>
    implements $DeclarationModelCopyWith<$Res> {
  _$DeclarationModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DeclarationModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? declarationType = null,
    Object? documentType = null,
    Object? ownerName = freezed,
    Object? description = freezed,
    Object? locationName = freezed,
    Object? locationDescription = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? photoUrl = freezed,
    Object? photoUrls = null,
    Object? documentNumber = freezed,
    Object? eventDate = freezed,
    Object? status = null,
    Object? createdAt = freezed,
    Object? userId = freezed,
    Object? groupId = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      declarationType: null == declarationType
          ? _value.declarationType
          : declarationType // ignore: cast_nullable_to_non_nullable
              as String,
      documentType: null == documentType
          ? _value.documentType
          : documentType // ignore: cast_nullable_to_non_nullable
              as String,
      ownerName: freezed == ownerName
          ? _value.ownerName
          : ownerName // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      locationName: freezed == locationName
          ? _value.locationName
          : locationName // ignore: cast_nullable_to_non_nullable
              as String?,
      locationDescription: freezed == locationDescription
          ? _value.locationDescription
          : locationDescription // ignore: cast_nullable_to_non_nullable
              as String?,
      latitude: freezed == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double?,
      longitude: freezed == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double?,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      photoUrls: null == photoUrls
          ? _value.photoUrls
          : photoUrls // ignore: cast_nullable_to_non_nullable
              as List<String>,
      documentNumber: freezed == documentNumber
          ? _value.documentNumber
          : documentNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      eventDate: freezed == eventDate
          ? _value.eventDate
          : eventDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
      userId: freezed == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String?,
      groupId: freezed == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DeclarationModelImplCopyWith<$Res>
    implements $DeclarationModelCopyWith<$Res> {
  factory _$$DeclarationModelImplCopyWith(_$DeclarationModelImpl value,
          $Res Function(_$DeclarationModelImpl) then) =
      __$$DeclarationModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'declaration_type') String declarationType,
      @JsonKey(name: 'document_type') String documentType,
      @JsonKey(name: 'owner_name') String? ownerName,
      String? description,
      @JsonKey(name: 'location_name') String? locationName,
      @JsonKey(name: 'location_description') String? locationDescription,
      double? latitude,
      double? longitude,
      @JsonKey(name: 'photo_url') String? photoUrl,
      @JsonKey(name: 'photo_urls') List<String> photoUrls,
      @JsonKey(name: 'document_number') String? documentNumber,
      @JsonKey(name: 'event_date') DateTime? eventDate,
      @JsonKey(name: 'status') String status,
      @JsonKey(name: 'created_at') String? createdAt,
      @JsonKey(name: 'user_id') String? userId,
      @JsonKey(name: 'group_id') String? groupId});
}

/// @nodoc
class __$$DeclarationModelImplCopyWithImpl<$Res>
    extends _$DeclarationModelCopyWithImpl<$Res, _$DeclarationModelImpl>
    implements _$$DeclarationModelImplCopyWith<$Res> {
  __$$DeclarationModelImplCopyWithImpl(_$DeclarationModelImpl _value,
      $Res Function(_$DeclarationModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of DeclarationModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? declarationType = null,
    Object? documentType = null,
    Object? ownerName = freezed,
    Object? description = freezed,
    Object? locationName = freezed,
    Object? locationDescription = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? photoUrl = freezed,
    Object? photoUrls = null,
    Object? documentNumber = freezed,
    Object? eventDate = freezed,
    Object? status = null,
    Object? createdAt = freezed,
    Object? userId = freezed,
    Object? groupId = freezed,
  }) {
    return _then(_$DeclarationModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      declarationType: null == declarationType
          ? _value.declarationType
          : declarationType // ignore: cast_nullable_to_non_nullable
              as String,
      documentType: null == documentType
          ? _value.documentType
          : documentType // ignore: cast_nullable_to_non_nullable
              as String,
      ownerName: freezed == ownerName
          ? _value.ownerName
          : ownerName // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      locationName: freezed == locationName
          ? _value.locationName
          : locationName // ignore: cast_nullable_to_non_nullable
              as String?,
      locationDescription: freezed == locationDescription
          ? _value.locationDescription
          : locationDescription // ignore: cast_nullable_to_non_nullable
              as String?,
      latitude: freezed == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double?,
      longitude: freezed == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double?,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      photoUrls: null == photoUrls
          ? _value._photoUrls
          : photoUrls // ignore: cast_nullable_to_non_nullable
              as List<String>,
      documentNumber: freezed == documentNumber
          ? _value.documentNumber
          : documentNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      eventDate: freezed == eventDate
          ? _value.eventDate
          : eventDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
      userId: freezed == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String?,
      groupId: freezed == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DeclarationModelImpl extends _DeclarationModel {
  const _$DeclarationModelImpl(
      {required this.id,
      @JsonKey(name: 'declaration_type') required this.declarationType,
      @JsonKey(name: 'document_type') required this.documentType,
      @JsonKey(name: 'owner_name') this.ownerName,
      this.description,
      @JsonKey(name: 'location_name') this.locationName,
      @JsonKey(name: 'location_description') this.locationDescription,
      this.latitude,
      this.longitude,
      @JsonKey(name: 'photo_url') this.photoUrl,
      @JsonKey(name: 'photo_urls') final List<String> photoUrls = const [],
      @JsonKey(name: 'document_number') this.documentNumber,
      @JsonKey(name: 'event_date') this.eventDate,
      @JsonKey(name: 'status') this.status = 'active',
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'user_id') this.userId,
      @JsonKey(name: 'group_id') this.groupId})
      : _photoUrls = photoUrls,
        super._();

  factory _$DeclarationModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$DeclarationModelImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'declaration_type')
  final String declarationType;
  @override
  @JsonKey(name: 'document_type')
  final String documentType;
  @override
  @JsonKey(name: 'owner_name')
  final String? ownerName;
  @override
  final String? description;
// Champs localisation
  @override
  @JsonKey(name: 'location_name')
  final String? locationName;
  @override
  @JsonKey(name: 'location_description')
  final String? locationDescription;
  @override
  final double? latitude;
  @override
  final double? longitude;
// Photos : l'API peut renvoyer une URL unique ou une liste
  @override
  @JsonKey(name: 'photo_url')
  final String? photoUrl;
  final List<String> _photoUrls;
  @override
  @JsonKey(name: 'photo_urls')
  List<String> get photoUrls {
    if (_photoUrls is EqualUnmodifiableListView) return _photoUrls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_photoUrls);
  }

// Numéro de document (optionnel)
  @override
  @JsonKey(name: 'document_number')
  final String? documentNumber;
// Date de l'événement
  @override
  @JsonKey(name: 'event_date')
  final DateTime? eventDate;
  @override
  @JsonKey(name: 'status')
  final String status;
  @override
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @override
  @JsonKey(name: 'user_id')
  final String? userId;
// Dossier multi-documents : plusieurs déclarations d'un même dépôt
// (un propriétaire, plusieurs documents) partagent ce group_id.
  @override
  @JsonKey(name: 'group_id')
  final String? groupId;

  @override
  String toString() {
    return 'DeclarationModel(id: $id, declarationType: $declarationType, documentType: $documentType, ownerName: $ownerName, description: $description, locationName: $locationName, locationDescription: $locationDescription, latitude: $latitude, longitude: $longitude, photoUrl: $photoUrl, photoUrls: $photoUrls, documentNumber: $documentNumber, eventDate: $eventDate, status: $status, createdAt: $createdAt, userId: $userId, groupId: $groupId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeclarationModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.declarationType, declarationType) ||
                other.declarationType == declarationType) &&
            (identical(other.documentType, documentType) ||
                other.documentType == documentType) &&
            (identical(other.ownerName, ownerName) ||
                other.ownerName == ownerName) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.locationName, locationName) ||
                other.locationName == locationName) &&
            (identical(other.locationDescription, locationDescription) ||
                other.locationDescription == locationDescription) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            const DeepCollectionEquality()
                .equals(other._photoUrls, _photoUrls) &&
            (identical(other.documentNumber, documentNumber) ||
                other.documentNumber == documentNumber) &&
            (identical(other.eventDate, eventDate) ||
                other.eventDate == eventDate) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.groupId, groupId) || other.groupId == groupId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      declarationType,
      documentType,
      ownerName,
      description,
      locationName,
      locationDescription,
      latitude,
      longitude,
      photoUrl,
      const DeepCollectionEquality().hash(_photoUrls),
      documentNumber,
      eventDate,
      status,
      createdAt,
      userId,
      groupId);

  /// Create a copy of DeclarationModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DeclarationModelImplCopyWith<_$DeclarationModelImpl> get copyWith =>
      __$$DeclarationModelImplCopyWithImpl<_$DeclarationModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DeclarationModelImplToJson(
      this,
    );
  }
}

abstract class _DeclarationModel extends DeclarationModel {
  const factory _DeclarationModel(
      {required final String id,
      @JsonKey(name: 'declaration_type') required final String declarationType,
      @JsonKey(name: 'document_type') required final String documentType,
      @JsonKey(name: 'owner_name') final String? ownerName,
      final String? description,
      @JsonKey(name: 'location_name') final String? locationName,
      @JsonKey(name: 'location_description') final String? locationDescription,
      final double? latitude,
      final double? longitude,
      @JsonKey(name: 'photo_url') final String? photoUrl,
      @JsonKey(name: 'photo_urls') final List<String> photoUrls,
      @JsonKey(name: 'document_number') final String? documentNumber,
      @JsonKey(name: 'event_date') final DateTime? eventDate,
      @JsonKey(name: 'status') final String status,
      @JsonKey(name: 'created_at') final String? createdAt,
      @JsonKey(name: 'user_id') final String? userId,
      @JsonKey(name: 'group_id')
      final String? groupId}) = _$DeclarationModelImpl;
  const _DeclarationModel._() : super._();

  factory _DeclarationModel.fromJson(Map<String, dynamic> json) =
      _$DeclarationModelImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'declaration_type')
  String get declarationType;
  @override
  @JsonKey(name: 'document_type')
  String get documentType;
  @override
  @JsonKey(name: 'owner_name')
  String? get ownerName;
  @override
  String? get description; // Champs localisation
  @override
  @JsonKey(name: 'location_name')
  String? get locationName;
  @override
  @JsonKey(name: 'location_description')
  String? get locationDescription;
  @override
  double? get latitude;
  @override
  double?
      get longitude; // Photos : l'API peut renvoyer une URL unique ou une liste
  @override
  @JsonKey(name: 'photo_url')
  String? get photoUrl;
  @override
  @JsonKey(name: 'photo_urls')
  List<String> get photoUrls; // Numéro de document (optionnel)
  @override
  @JsonKey(name: 'document_number')
  String? get documentNumber; // Date de l'événement
  @override
  @JsonKey(name: 'event_date')
  DateTime? get eventDate;
  @override
  @JsonKey(name: 'status')
  String get status;
  @override
  @JsonKey(name: 'created_at')
  String? get createdAt;
  @override
  @JsonKey(name: 'user_id')
  String?
      get userId; // Dossier multi-documents : plusieurs déclarations d'un même dépôt
// (un propriétaire, plusieurs documents) partagent ce group_id.
  @override
  @JsonKey(name: 'group_id')
  String? get groupId;

  /// Create a copy of DeclarationModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DeclarationModelImplCopyWith<_$DeclarationModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

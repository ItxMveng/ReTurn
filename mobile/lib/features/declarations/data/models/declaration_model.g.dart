// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'declaration_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DeclarationModelImpl _$$DeclarationModelImplFromJson(
        Map<String, dynamic> json) =>
    _$DeclarationModelImpl(
      id: json['id'] as String,
      declarationType: json['declaration_type'] as String,
      documentType: json['document_type'] as String,
      ownerName: json['owner_name'] as String?,
      description: json['description'] as String?,
      locationName: json['location_name'] as String?,
      locationDescription: json['location_description'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      photoUrl: json['photo_url'] as String?,
      photoUrls: (json['photo_urls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      documentNumber: json['document_number'] as String?,
      eventDate: json['event_date'] == null
          ? null
          : DateTime.parse(json['event_date'] as String),
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] as String?,
      userId: json['user_id'] as String?,
      groupId: json['group_id'] as String?,
    );

Map<String, dynamic> _$$DeclarationModelImplToJson(
        _$DeclarationModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'declaration_type': instance.declarationType,
      'document_type': instance.documentType,
      'owner_name': instance.ownerName,
      'description': instance.description,
      'location_name': instance.locationName,
      'location_description': instance.locationDescription,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'photo_url': instance.photoUrl,
      'photo_urls': instance.photoUrls,
      'document_number': instance.documentNumber,
      'event_date': instance.eventDate?.toIso8601String(),
      'status': instance.status,
      'created_at': instance.createdAt,
      'user_id': instance.userId,
      'group_id': instance.groupId,
    };

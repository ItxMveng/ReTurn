// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserModelImpl _$$UserModelImplFromJson(Map<String, dynamic> json) =>
    _$UserModelImpl(
      id: json['id'] as String,
      phoneNumber: json['phone_number'] as String?,
      email: json['email'] as String?,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      reputationScore: (json['score_reputation'] as num?)?.toDouble() ?? 5.0,
      isVerified: json['is_verified'] as bool? ?? false,
      isProfileComplete: json['is_profile_complete'] as bool? ?? false,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$UserModelImplToJson(_$UserModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'phone_number': instance.phoneNumber,
      'email': instance.email,
      'full_name': instance.fullName,
      'avatar_url': instance.avatarUrl,
      'score_reputation': instance.reputationScore,
      'is_verified': instance.isVerified,
      'is_profile_complete': instance.isProfileComplete,
      'created_at': instance.createdAt?.toIso8601String(),
    };

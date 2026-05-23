/// UserProfile — source of truth partagée dans shared/models
/// profile_provider.dart peut continuer d'importer depuis ici.
/// L'ancienne définition inline dans profile_provider.dart est gardée
/// pour compatibilité mais doit être migrée vers cet import.
class UserProfile {
  final String id;
  final String phoneNumber;
  final String? email;
  final String fullName;
  final String? dateOfBirth;
  final String? nationalIdNumber;
  final String? gender;
  final String? city;
  final String? region;
  final String? address;
  final String? avatarUrl;
  final double? reputationScore;
  final bool isProfileComplete;

  const UserProfile({
    required this.id,
    required this.phoneNumber,
    this.email,
    required this.fullName,
    this.dateOfBirth,
    this.nationalIdNumber,
    this.gender,
    this.city,
    this.region,
    this.address,
    this.avatarUrl,
    this.reputationScore,
    required this.isProfileComplete,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: (json['id'] as String?) ?? '',
        phoneNumber: (json['phone_number'] as String?) ?? '',
        email: json['email'] as String?,
        fullName: (json['full_name'] as String?) ?? '',
        dateOfBirth: json['date_of_birth'] as String?,
        nationalIdNumber: json['national_id_number'] as String?,
        gender: json['gender'] as String?,
        city: json['city'] as String?,
        region: json['region'] as String?,
        address: json['address'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        reputationScore: (json['reputation_score'] as num?)?.toDouble(),
        isProfileComplete: (json['is_profile_complete'] as bool?) ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone_number': phoneNumber,
        if (email != null) 'email': email,
        'full_name': fullName,
        if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
        if (nationalIdNumber != null) 'national_id_number': nationalIdNumber,
        if (gender != null) 'gender': gender,
        if (city != null) 'city': city,
        if (region != null) 'region': region,
        if (address != null) 'address': address,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (reputationScore != null) 'reputation_score': reputationScore,
        'is_profile_complete': isProfileComplete,
      };

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  String get displayCity => city != null && region != null
      ? '$city, $region'
      : city ?? region ?? 'Localisation inconnue';
}

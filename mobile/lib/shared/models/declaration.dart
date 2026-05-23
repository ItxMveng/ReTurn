class Declaration {
  final String id;
  final String userId;
  final String declarationType;
  final String documentType;
  final String? documentNumber;
  final String? ownerName;
  final String? description;
  final double? latitude;
  final double? longitude;
  final String? locationDescription;
  final List<String> photoUrls;
  final String status; // active | matched | closed
  final bool isMatched;
  final DateTime createdAt;

  const Declaration({
    required this.id,
    required this.userId,
    required this.declarationType,
    required this.documentType,
    this.documentNumber,
    this.ownerName,
    this.description,
    this.latitude,
    this.longitude,
    this.locationDescription,
    required this.photoUrls,
    required this.status,
    this.isMatched = false,
    required this.createdAt,
  });

  factory Declaration.fromJson(Map<String, dynamic> json) => Declaration(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        declarationType: json['declaration_type'] as String,
        documentType: json['document_type'] as String,
        documentNumber: json['document_number'] as String?,
        ownerName: json['owner_name'] as String?,
        description: json['description'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        locationDescription: json['location_description'] as String?,
        photoUrls: List<String>.from(json['photo_urls'] as List? ?? []),
        status: json['status'] as String,
        isMatched: (json['status'] as String?) == 'matched',
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  bool get isFound => declarationType == 'found';
  bool get isLost => declarationType == 'lost';
  bool get isActive => status == 'active';
}

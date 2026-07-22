class Match {
  const Match({
    required this.id,
    required this.documentType,
    required this.score,
    required this.status,
    required this.foundDeclarationId,
    required this.lostDeclarationId,
    this.userFoundId = '',
    this.userLostId = '',
    this.acceptedByOwner = false,
    this.acceptedByFinder = false,
    this.createdAt,
    this.confirmedAt,
    this.otherUserName,
    this.otherUserAvatar,
    this.ownerName,
    this.location,
    this.foundPhotoUrls = const [],
  });

  final String id;
  final String documentType;
  final double score;
  final String status;
  final String foundDeclarationId;
  final String lostDeclarationId;
  // Rôles et double acceptation (F-33) — qui a déjà accepté le match ?
  final String userFoundId; // trouveur
  final String userLostId; // propriétaire présumé
  final bool acceptedByOwner;
  final bool acceptedByFinder;
  final DateTime? createdAt;
  final DateTime? confirmedAt;
  // Enrichissements pour l'affichage
  final String? otherUserName;
  final String? otherUserAvatar;
  final String? ownerName; // nom du propriétaire lu sur le document
  final String? location; // lieu de découverte/perte
  final List<String> foundPhotoUrls; // photos du document trouvé

  String? get foundPhotoUrl =>
      foundPhotoUrls.isNotEmpty ? foundPhotoUrls.first : null;

  factory Match.fromJson(Map<String, dynamic> json) {
    final found = json['declaration_found'] as Map<String, dynamic>?;
    final lost = json['declaration_lost'] as Map<String, dynamic>?;
    final docType =
        (found?['document_type'] ?? lost?['document_type']) as String?;
    final ownerName =
        (found?['owner_name'] ?? lost?['owner_name']) as String?;
    final location = (found?['location_description'] ??
        lost?['location_description']) as String?;
    final foundPhotos = (found?['photo_urls'] as List?)?.cast<String>();

    return Match(
      id: json['id'] as String,
      documentType: docType ?? json['document_type'] as String? ?? 'Document',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'pending',
      foundDeclarationId:
          (json['declaration_found_id'] ?? json['found_declaration_id'])
                  as String? ??
              '',
      lostDeclarationId:
          (json['declaration_lost_id'] ?? json['lost_declaration_id'])
                  as String? ??
              '',
      userFoundId: json['user_found_id'] as String? ?? '',
      userLostId: json['user_lost_id'] as String? ?? '',
      acceptedByOwner: (json['accepted_by_owner'] ??
          json['confirmed_by_owner']) as bool? ??
          false,
      acceptedByFinder: (json['accepted_by_finder'] ??
          json['confirmed_by_finder']) as bool? ??
          false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.tryParse(json['confirmed_at'] as String)
          : null,
      otherUserName: json['other_user_name'] as String?,
      otherUserAvatar: json['other_user_avatar'] as String?,
      ownerName: ownerName,
      location: location,
      foundPhotoUrls: foundPhotos ?? const [],
    );
  }

  int get scorePercent => (score * 100).round();
  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';

  /// Vrai si [userId] est le propriétaire présumé (déclarant de la perte).
  bool isOwner(String userId) => userId.isNotEmpty && userId == userLostId;

  /// Vrai si [userId] a déjà accepté sa part du match.
  bool hasConfirmed(String userId) =>
      isOwner(userId) ? acceptedByOwner : acceptedByFinder;

  /// Vrai si l'autre partie a déjà accepté.
  bool otherHasConfirmed(String userId) =>
      isOwner(userId) ? acceptedByFinder : acceptedByOwner;
}

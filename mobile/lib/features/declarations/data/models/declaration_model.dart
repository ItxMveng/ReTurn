import 'package:freezed_annotation/freezed_annotation.dart';

part 'declaration_model.freezed.dart';
part 'declaration_model.g.dart';

enum DeclarationType { found, lost }

@freezed
class DeclarationModel with _$DeclarationModel {
  const DeclarationModel._(); // nécessaire pour définir des getters sur un freezed

  const factory DeclarationModel({
    required String id,
    @JsonKey(name: 'declaration_type') required String declarationType,
    @JsonKey(name: 'document_type') required String documentType,
    @JsonKey(name: 'owner_name') String? ownerName,
    String? description,
    // Champs localisation
    @JsonKey(name: 'location_name') String? locationName,
    @JsonKey(name: 'location_description') String? locationDescription,
    double? latitude,
    double? longitude,
    // Photos : l'API peut renvoyer une URL unique ou une liste
    @JsonKey(name: 'photo_url') String? photoUrl,
    @JsonKey(name: 'photo_urls') @Default([]) List<String> photoUrls,
    // Numéro de document (optionnel)
    @JsonKey(name: 'document_number') String? documentNumber,
    // Date de l'événement
    @JsonKey(name: 'event_date') DateTime? eventDate,
    @JsonKey(name: 'status') @Default('active') String status,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'user_id') String? userId,
  }) = _DeclarationModel;

  factory DeclarationModel.fromJson(Map<String, dynamic> json) =>
      _$DeclarationModelFromJson(json);

  // ── Getters utilitaires ────────────────────────────────────────────────────

  /// Vrai si c'est une déclaration "trouvé"
  bool get isFound => declarationType == 'found';

  /// Label lisible du type (Trouvé / Perdu)
  String get typeLabel => isFound ? 'Trouvé' : 'Perdu';

  /// Compatibilité avec les widgets legacy.
  DeclarationType get type =>
      isFound ? DeclarationType.found : DeclarationType.lost;

  /// Label lisible du type de document (CNI, Passeport, Permis…)
  String get documentLabel {
    const labels = {
      'cni': 'CNI',
      'passport': 'Passeport',
      'permis': 'Permis',
      'carte_scolaire': 'Carte scolaire',
      'carte_consulaire': 'Carte consulaire',
    };
    return labels[documentType.toLowerCase()] ?? documentType;
  }

  String get docTypeLabel => documentLabel;

  String get nomProprietaire {
    final value = ownerName?.trim();
    return value == null || value.isEmpty ? '—' : value;
  }

  String? get lieu {
    final description = locationDescription?.trim();
    if (description != null && description.isNotEmpty) {
      return description;
    }
    final name = locationName?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    return null;
  }

  double? get lat => latitude;
  double? get lon => longitude;

  DateTime? get createdAtDate =>
      createdAt == null ? null : DateTime.tryParse(createdAt!);

  /// Toutes les URLs photos : priorité à la liste, sinon photo unique
  List<String> get allPhotoUrls {
    if (photoUrls.isNotEmpty) return photoUrls;
    if (photoUrl != null && photoUrl!.isNotEmpty) return [photoUrl!];
    return [];
  }
}

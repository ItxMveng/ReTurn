enum DocType { cni, passeport, permis, diplome, autre }
enum DeclarationType { found, lost }
enum DeclarationStatus { active, matched, cloture }

class Declaration {
  final String id;
  final DeclarationType type;
  final DocType docType;
  final String nomProprietaire;
  final String? lieu;
  final String? description;
  final DeclarationStatus status;
  final DateTime createdAt;
  final double? lat;
  final double? lon;

  const Declaration({
    required this.id,
    required this.type,
    required this.docType,
    required this.nomProprietaire,
    this.lieu,
    this.description,
    required this.status,
    required this.createdAt,
    this.lat,
    this.lon,
  });

  factory Declaration.fromJson(Map<String, dynamic> j) => Declaration(
        id: j['id'] as String,
        type: j['type'] == 'found'
            ? DeclarationType.found
            : DeclarationType.lost,
        docType: _parseDocType(j['doc_type'] as String),
        nomProprietaire: j['nom_proprietaire'] as String,
        lieu: j['lieu'] as String?,
        description: j['description'] as String?,
        status: _parseStatus(j['status'] as String),
        createdAt: DateTime.parse(j['created_at'] as String),
        lat: (j['lat'] as num?)?.toDouble(),
        lon: (j['lon'] as num?)?.toDouble(),
      );

  static DocType _parseDocType(String s) {
    switch (s) {
      case 'cni': return DocType.cni;
      case 'passeport': return DocType.passeport;
      case 'permis': return DocType.permis;
      case 'diplome': return DocType.diplome;
      default: return DocType.autre;
    }
  }

  static DeclarationStatus _parseStatus(String s) {
    switch (s) {
      case 'matched': return DeclarationStatus.matched;
      case 'cloture': return DeclarationStatus.cloture;
      default: return DeclarationStatus.active;
    }
  }

  String get docTypeLabel {
    switch (docType) {
      case DocType.cni: return 'CNI';
      case DocType.passeport: return 'Passeport';
      case DocType.permis: return 'Permis de conduire';
      case DocType.diplome: return 'Diplôme';
      case DocType.autre: return 'Autre';
    }
  }

  String get typeLabel =>
      type == DeclarationType.found ? 'Trouvé' : 'Perdu';
}

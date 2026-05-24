// F-11 — Résultat d'extraction OCR on-device
// F-12 — Les champs sensibles sont masqués avant affichage

class OcrResult {
  final String rawText;          // Texte brut complet du ML Kit
  final String? documentNumber;  // Numéro de document extrait
  final String? lastName;        // Nom de famille
  final String? firstName;       // Prénom
  final String? birthDate;       // Date de naissance (masquée F-12)
  final String? expiryDate;      // Date d'expiration
  final String? mrz;             // Zone MRZ si présente (passeport/CNI)
  final DocumentKind kind;       // Type de document détecté

  const OcrResult({
    required this.rawText,
    this.documentNumber,
    this.lastName,
    this.firstName,
    this.birthDate,
    this.expiryDate,
    this.mrz,
    required this.kind,
  });

  /// Champs "safe" pour affichage public (F-12 — masquage données sensibles)
  /// Seul le numéro de document est visible ; les données biométriques sont cachées.
  String get maskedDocumentNumber {
    if (documentNumber == null || documentNumber!.length < 4) return '****';
    final visible = documentNumber!.substring(documentNumber!.length - 4);
    return '${'*' * (documentNumber!.length - 4)}$visible';
  }

  String get maskedBirthDate {
    if (birthDate == null) return '**/**/****';
    // Masque le jour et le mois, garde l'année
    final parts = birthDate!.split(RegExp(r'[/\-.]'));
    if (parts.length == 3) return '**/**/${parts[2]}';
    return '**/**/****';
  }

  /// Données envoyées à l'API (sans données biométriques brutes)
  Map<String, dynamic> toSafeApiPayload() => {
    'document_number': documentNumber,
    'last_name': lastName,
    'first_name': firstName,
    'expiry_date': expiryDate,
    'document_kind': kind.name,
    // birthDate et MRZ intentionnellement exclus (F-12)
  };

  bool get isEmpty => rawText.trim().isEmpty;
}

enum DocumentKind {
  cni,        // Carte Nationale d'Identité camerounaise
  passport,   // Passeport
  driverLicense, // Permis de conduire
  unknown,
}

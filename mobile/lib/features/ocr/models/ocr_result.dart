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

  OcrResult copyWithRawText(String rawText) => OcrResult(
        rawText: rawText,
        documentNumber: documentNumber,
        lastName: lastName,
        firstName: firstName,
        birthDate: birthDate,
        expiryDate: expiryDate,
        mrz: mrz,
        kind: kind,
      );
}

enum DocumentKind {
  cni,                 // Carte Nationale d'Identité camerounaise
  passport,            // Passeport
  driverLicense,       // Permis de conduire
  birthCertificate,    // Acte de naissance
  diploma,             // Diplôme
  vehicleRegistration, // Carte grise
  other,               // Autre document reconnu
  unknown,             // Type non détecté
}

/// Correspondance avec les types attendus par le backend (DOCUMENT_TYPES).
extension DocumentKindBackend on DocumentKind {
  String get backendType => switch (this) {
        DocumentKind.cni => 'cni',
        DocumentKind.passport => 'passport',
        DocumentKind.driverLicense => 'driving_license',
        DocumentKind.birthCertificate => 'birth_certificate',
        DocumentKind.diploma => 'diploma',
        DocumentKind.vehicleRegistration => 'vehicle_registration',
        DocumentKind.other => 'other',
        DocumentKind.unknown => 'other',
      };
}

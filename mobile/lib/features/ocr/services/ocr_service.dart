import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/ocr_result.dart';

/// Service OCR on-device utilisant Google ML Kit Text Recognition (F-11).
/// Tout le traitement se fait localement — aucune image n'est envoyée à un serveur tiers.
class OcrService {
  // Script latin pour CNI et permis camerounais
  // Script chinois/japonais non nécessaire → TextRecognitionScript.latin
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  /// Extrait le texte d'une image et parse les champs du document.
  Future<OcrResult> processImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await _recognizer.processImage(inputImage);
    final raw = recognizedText.text;

    return OcrResult(
      rawText: raw,
      documentNumber: _extractDocumentNumber(raw),
      lastName: _extractLastName(raw),
      firstName: _extractFirstName(raw),
      birthDate: _extractBirthDate(raw),
      expiryDate: _extractExpiryDate(raw),
      mrz: _extractMrz(raw),
      kind: _detectKind(raw),
    );
  }

  // ── Extracteurs regex ──────────────────────────────────────────

  /// Numéro CNI camerounaise : 8-12 chiffres ou alphanum (ex: 123456789, A12345678)
  String? _extractDocumentNumber(String text) {
    // Cherche après les mots-clés courants sur les CNI/passeports camerounais
    final patterns = [
      RegExp(r'(?:N[°o]?\s*|NUMERO\s*:?\s*)([A-Z0-9]{6,12})', caseSensitive: false),
      RegExp(r'(?:Document\s*No\.?\s*)([A-Z0-9]{6,12})', caseSensitive: false),
      // MRZ line 1 — positions 5-14 pour passeport
      RegExp(r'^[A-Z<]{5}([A-Z0-9]{9})', multiLine: true),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m != null) return m.group(1);
    }
    // Fallback : première séquence alphanum isolée de 8–12 caractères
    final fallback = RegExp(r'\b([A-Z0-9]{8,12})\b').firstMatch(text);
    return fallback?.group(1);
  }

  String? _extractLastName(String text) {
    final p = RegExp(
      r'(?:NOM\s*(?:DE\s*FAMILLE)?\s*:?\s*|Surname\s*:?\s*)([A-ZÀÂÉÈÊËÎÏÔÙÛÜÆŒ][A-ZÀÂÉÈÊËÎÏÔÙÛÜÆŒ\s\-]+)',
      caseSensitive: false,
    );
    return p.firstMatch(text)?.group(1)?.trim();
  }

  String? _extractFirstName(String text) {
    final p = RegExp(
      r'(?:PR[ÉE]NOM\s*(?:S)?\s*:?\s*|Given\s*name\s*:?\s*)([A-ZÀÂÉÈÊËÎÏÔÙÛÜÆŒ][A-Za-zÀ-ÿ\s\-]+)',
      caseSensitive: false,
    );
    return p.firstMatch(text)?.group(1)?.trim();
  }

  /// Dates au format JJ/MM/AAAA ou JJ-MM-AAAA
  String? _extractBirthDate(String text) {
    // On cherche la première date après "né" ou "date de naissance" ou "DOB"
    final labeled = RegExp(
      r'(?:N[ÉE][E]?\s*(?:LE)?\s*:?\s*|Date\s*(?:de\s*)?[Nn]aissance\s*:?\s*|DOB\s*:?\s*)'
      r'(\d{1,2}[/\-.](\d{1,2})[/\.\-](\d{4}))',
    );
    final m = labeled.firstMatch(text);
    if (m != null) return m.group(1);
    return null;
  }

  String? _extractExpiryDate(String text) {
    final p = RegExp(
      r'(?:Expir[ey]\s*:?\s*|Date\s*d.expir\w+\s*:?\s*|Valable\s*jusqu.au\s*:?\s*)'
      r'(\d{1,2}[/\-.](\d{1,2})[/\.\-](\d{4}))',
      caseSensitive: false,
    );
    return p.firstMatch(text)?.group(1);
  }

  /// Lignes MRZ (passeport : 2 lignes de 44 chars ; TD1 : 3 × 30)
  String? _extractMrz(String text) {
    final lines = text.split('\n');
    final mrzLines = lines
        .where((l) => RegExp(r'^[A-Z0-9<]{20,}$').hasMatch(l.trim()))
        .toList();
    if (mrzLines.length >= 2) return mrzLines.take(3).join('\n');
    return null;
  }

  DocumentKind _detectKind(String text) {
    final upper = text.toUpperCase();
    if (upper.contains('PASSEPORT') || upper.contains('PASSPORT')) return DocumentKind.passport;
    if (upper.contains('PERMIS DE CONDUIRE') || upper.contains("DRIVER'S LICENCE")) {
      return DocumentKind.driverLicense;
    }
    if (upper.contains('CARTE NATIONALE') || upper.contains('IDENTIT')) return DocumentKind.cni;
    return DocumentKind.unknown;
  }

  void dispose() => _recognizer.close();
}

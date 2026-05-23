import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrResult {
  final String rawText;
  final String? documentNumber;
  final String? ownerFullName;
  final String? ownerLastName;
  final String? ownerFirstName;
  final String? dateOfBirth;
  final String? placeOfBirth;
  final String? nationality;
  final String? expiryDate;
  final String? detectedDocumentType;
  final Set<String> autoFilledFields;

  const OcrResult({
    required this.rawText,
    this.documentNumber,
    this.ownerFullName,
    this.ownerLastName,
    this.ownerFirstName,
    this.dateOfBirth,
    this.placeOfBirth,
    this.nationality,
    this.expiryDate,
    this.detectedDocumentType,
    required this.autoFilledFields,
  });

  bool get hasAnyData =>
      documentNumber != null || ownerFullName != null || ownerLastName != null;

  String? get bestOwnerName => ownerFullName?.isNotEmpty == true
      ? ownerFullName
      : (ownerLastName != null && ownerFirstName != null)
          ? '$ownerFirstName $ownerLastName'
          : ownerLastName ?? ownerFirstName;
}

class _Builder {
  String? documentNumber;
  String? ownerFullName;
  String? ownerLastName;
  String? ownerFirstName;
  String? dateOfBirth;
  String? placeOfBirth;
  String? nationality;
  String? expiryDate;
  String? detectedDocumentType;
  Set<String> autoFilledFields = {};

  OcrResult build(String rawText) => OcrResult(
        rawText: rawText,
        documentNumber: documentNumber,
        ownerFullName: ownerFullName,
        ownerLastName: ownerLastName,
        ownerFirstName: ownerFirstName,
        dateOfBirth: dateOfBirth,
        placeOfBirth: placeOfBirth,
        nationality: nationality,
        expiryDate: expiryDate,
        detectedDocumentType: detectedDocumentType,
        autoFilledFields: autoFilledFields,
      );
}

class OcrService {
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<OcrResult> extractFromFile(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognized = await _recognizer.processImage(inputImage);
    final raw = recognized.text;
    final b = _Builder();

    // 1. Try MRZ parsing first (most reliable for passports + ID cards)
    _parseMrz(raw, b);

    // 2. If MRZ didn't find enough, try field-label parsing
    if (b.documentNumber == null || b.ownerFullName == null) {
      _parseLabels(raw, b);
    }

    // 3. Fallback: pattern matching
    if (b.documentNumber == null) _fallbackDocNumber(raw, b);
    if (b.ownerFullName == null && b.ownerLastName == null) _fallbackName(raw, b);

    // 4. Detect document type from keywords if not found via MRZ
    if (b.detectedDocumentType == null) _detectDocumentType(raw, b);

    // 5. Consolidate ownerFullName
    if (b.ownerFullName == null &&
        (b.ownerLastName != null || b.ownerFirstName != null)) {
      b.ownerFullName = '${b.ownerFirstName ?? ''} ${b.ownerLastName ?? ''}'.trim();
    }

    return b.build(raw);
  }

  Future<void> dispose() => _recognizer.close();

  // ── MRZ parser ─────────────────────────────────────────────────────────────
  void _parseMrz(String text, _Builder b) {
    final lines = text
        .split('\n')
        .map((l) => l.replaceAll(' ', '').trim())
        .where((l) => l.length >= 28)
        .toList();

    for (int i = 0; i < lines.length; i++) {
      final l1 = lines[i];

      // ── TD3 Passport: 2 lines × 44 chars ─────────────────────────────────
      if (l1.length >= 44 && i + 1 < lines.length) {
        final l2 = lines[i + 1];
        if (l2.length >= 44 &&
            (l1.startsWith('P<') || l1.startsWith('P '))) {
          // Line 1: P<CCCLastname<<Firstname<…
          final nameSection = l1.substring(5);
          final nameParts = nameSection.split('<<');
          if (nameParts.isNotEmpty) {
            b.ownerLastName =
                nameParts[0].replaceAll('<', ' ').trim();
            if (nameParts.length > 1) {
              b.ownerFirstName =
                  nameParts[1].replaceAll('<', ' ').trim();
            }
          }
          // Line 2 positions: 0-8 doc number, 10-12 nationality, 13-18 DOB, 19 sex, 20-25 expiry
          b.documentNumber = l2.substring(0, 9).replaceAll('<', '').trim();
          final nat = l2.substring(10, 13).replaceAll('<', '').trim();
          if (nat.isNotEmpty && nat != 'XXX') b.nationality = nat;
          _parseMrzDate(l2.substring(13, 19), isDob: true, b: b);
          _parseMrzDate(l2.substring(20, 26), isDob: false, b: b);
          b.detectedDocumentType = 'passport';
          b.autoFilledFields.addAll(
              ['documentNumber', 'ownerName', 'dateOfBirth', 'nationality']);
          return;
        }
      }

      // ── TD1 ID card: 3 lines × 30 chars ───────────────────────────────────
      if (l1.length >= 30 && i + 2 < lines.length) {
        final l2 = lines[i + 1];
        final l3 = lines[i + 2];
        final t1 = l1.substring(0, 2);
        if (l2.length >= 30 &&
            l3.length >= 30 &&
            (t1 == 'I<' || t1 == 'AC' || t1 == 'A<' || t1 == 'C<' ||
                t1 == 'IC' || t1 == 'IA')) {
          b.documentNumber = l1.substring(5, 14).replaceAll('<', '').trim();
          // DOB at position 0-5 of line 2
          _parseMrzDate(l2.substring(0, 6), isDob: true, b: b);
          final nat = l2.substring(15, 18).replaceAll('<', '').trim();
          if (nat.isNotEmpty && nat != 'XXX') b.nationality = nat;
          // Line 3: lastname<<firstname
          final nameParts = l3.split('<<');
          if (nameParts.isNotEmpty) {
            b.ownerLastName =
                nameParts[0].replaceAll('<', ' ').trim();
            if (nameParts.length > 1) {
              b.ownerFirstName =
                  nameParts[1].replaceAll('<', ' ').trim();
            }
          }
          b.detectedDocumentType = 'cni';
          b.autoFilledFields
              .addAll(['documentNumber', 'ownerName', 'dateOfBirth']);
          return;
        }
      }
    }
  }

  void _parseMrzDate(String yymmdd, {required bool isDob, required _Builder b}) {
    if (!RegExp(r'^\d{6}$').hasMatch(yymmdd)) return;
    final yy = int.parse(yymmdd.substring(0, 2));
    final mm = yymmdd.substring(2, 4);
    final dd = yymmdd.substring(4, 6);
    final yyyy = isDob
        ? (yy > 30 ? '19$yy' : '20${yy.toString().padLeft(2, '0')}')
        : (yy < 30 ? '20${yy.toString().padLeft(2, '0')}' : '19$yy');
    if (isDob) {
      b.dateOfBirth = '$yyyy-$mm-$dd';
    } else {
      b.expiryDate = '$yyyy-$mm-$dd';
    }
  }

  // ── Label-based parsing ────────────────────────────────────────────────────
  void _parseLabels(String text, _Builder b) {
    final lines = text.split('\n');
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase().trim();

      // Document number
      if (b.documentNumber == null) {
        for (final label in const [
          'n°', 'no.', 'numéro', 'number', 'num', 'cin', 'passport no',
          'permis n°', 'id no', 'card no', 'document no'
        ]) {
          if (lower.contains(label)) {
            final val = _valueAfterLabel(line, label);
            if (val != null && val.length >= 4) {
              b.documentNumber = val;
              b.autoFilledFields.add('documentNumber');
              break;
            }
          }
        }
      }

      // Last name
      if (b.ownerLastName == null) {
        for (final label in const ['nom', 'surname', 'last name', 'lastname', 'name']) {
          if (lower.startsWith(label)) {
            final val = _valueAfterColon(line);
            if (val != null && val.length >= 2) {
              b.ownerLastName = _toTitleCase(val);
              b.autoFilledFields.add('ownerName');
              break;
            }
          }
        }
      }

      // First name
      if (b.ownerFirstName == null) {
        for (final label in const ['prénom', 'prenom', 'given name', 'first name', 'firstname']) {
          if (lower.startsWith(label)) {
            final val = _valueAfterColon(line);
            if (val != null && val.length >= 2) {
              b.ownerFirstName = _toTitleCase(val);
              b.autoFilledFields.add('ownerName');
              break;
            }
          }
        }
      }

      // Full name (e.g. "Titulaire: DUPONT Jean")
      if (b.ownerFullName == null) {
        for (final label in const ['titulaire', 'holder', 'porteur']) {
          if (lower.contains(label)) {
            final val = _valueAfterColon(line);
            if (val != null && val.length >= 3) {
              b.ownerFullName = _toTitleCase(val);
              b.autoFilledFields.add('ownerName');
              break;
            }
          }
        }
      }

      // Date of birth
      if (b.dateOfBirth == null) {
        for (final label in const [
          'né le', 'nee le', 'date de naissance', 'date of birth', 'dob', 'né(e) le'
        ]) {
          if (lower.contains(label)) {
            final val = _valueAfterColon(line) ?? _valueAfterLabel(line, label);
            if (val != null) {
              final parsed = _parseTextDate(val);
              if (parsed != null) {
                b.dateOfBirth = parsed;
                b.autoFilledFields.add('dateOfBirth');
              }
              break;
            }
          }
        }
      }

      // Place of birth
      if (b.placeOfBirth == null) {
        for (final label in const [
          'lieu de naissance', 'place of birth', 'né à', 'nee a'
        ]) {
          if (lower.contains(label)) {
            final val = _valueAfterColon(line) ?? _valueAfterLabel(line, label);
            if (val != null && val.length >= 2) {
              b.placeOfBirth = _toTitleCase(val);
              break;
            }
          }
        }
      }
    }
  }

  // ── Fallbacks ──────────────────────────────────────────────────────────────
  void _fallbackDocNumber(String text, _Builder b) {
    // Cameroon CNI format: letters+numbers, 8-14 chars
    final patterns = [
      RegExp(r'\b\d{3}\s?\d{2}\s?\d{3}\s?\d{4}\b'), // 123 45 678 9012
      RegExp(r'\b[A-Z]{1,2}\d{7,10}\b'),              // CM1234567
      RegExp(r'\b[A-Z0-9]{8,14}\b'),                  // generic alphanumeric
    ];
    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m != null) {
        b.documentNumber = m.group(0)!.trim();
        b.autoFilledFields.add('documentNumber');
        return;
      }
    }
  }

  void _fallbackName(String text, _Builder b) {
    // Find consecutive ALL-CAPS word groups (likely a name on an ID card)
    final capsLine = RegExp(r'^[A-ZÀÂÄÉÈÊËÎÏÔÖÙÛÜÇ\s\-]{6,50}$', multiLine: true);
    final matches = capsLine.allMatches(text).toList();
    if (matches.isNotEmpty) {
      final candidate = matches.first.group(0)!.trim();
      if (candidate.split(' ').length >= 2) {
        b.ownerFullName = _toTitleCase(candidate);
        b.autoFilledFields.add('ownerName');
      }
    }
  }

  void _detectDocumentType(String text, _Builder b) {
    final lower = text.toLowerCase();
    if (lower.contains('passeport') || lower.contains('passport')) {
      b.detectedDocumentType = 'passport';
    } else if (lower.contains("carte nationale d'identité") ||
        lower.contains('cni') ||
        lower.contains('carte d\'identité') ||
        lower.contains('identity card')) {
      b.detectedDocumentType = 'cni';
    } else if (lower.contains('permis de conduire') ||
        lower.contains("permis de conduite") ||
        lower.contains('driving licence') ||
        lower.contains('driving license')) {
      b.detectedDocumentType = 'driving_license';
    } else if (lower.contains('carte grise') ||
        lower.contains('certificat d\'immatriculation') ||
        lower.contains('vehicle registration')) {
      b.detectedDocumentType = 'vehicle_registration';
    } else if (lower.contains('acte de naissance') ||
        lower.contains('birth certificate')) {
      b.detectedDocumentType = 'birth_certificate';
    } else if (lower.contains('diplôme') ||
        lower.contains('diplome') ||
        lower.contains('baccalauréat') ||
        lower.contains('bachelor')) {
      b.detectedDocumentType = 'diploma';
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String? _valueAfterColon(String line) {
    final idx = line.indexOf(':');
    if (idx == -1 || idx >= line.length - 2) return null;
    final val = line.substring(idx + 1).trim();
    return val.isEmpty ? null : val;
  }

  String? _valueAfterLabel(String line, String label) {
    final lower = line.toLowerCase();
    final idx = lower.indexOf(label);
    if (idx == -1) return null;
    final after = line.substring(idx + label.length).trim().replaceAll(RegExp(r'^[\s:]+'), '');
    return after.isEmpty ? null : after;
  }

  String? _parseTextDate(String s) {
    // Try ISO format first: YYYY-MM-DD or DD/MM/YYYY or DD.MM.YYYY
    final iso = RegExp(r'(\d{4})[-/.](\d{2})[-/.](\d{2})').firstMatch(s);
    if (iso != null) return '${iso.group(1)}-${iso.group(2)}-${iso.group(3)}';
    final dmy = RegExp(r'(\d{1,2})[-/.](\d{1,2})[-/.](\d{4})').firstMatch(s);
    if (dmy != null) {
      return '${dmy.group(3)}-${dmy.group(2)!.padLeft(2, '0')}-${dmy.group(1)!.padLeft(2, '0')}';
    }
    return null;
  }

  String _toTitleCase(String s) {
    return s.toLowerCase().split(RegExp(r'[\s\-]+')).map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');
  }
}

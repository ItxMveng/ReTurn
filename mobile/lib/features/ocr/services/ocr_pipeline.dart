import 'dart:io';

import 'package:dio/dio.dart';

import '../models/ocr_result.dart';
import 'backend_ocr_service.dart';
import 'ocr_service.dart';

/// Pipeline OCR performant, réutilisable (même moteur que le scan simple) :
///   1. IA backend (Mistral Vision via /ocr/extract) — lit imprimé ET manuscrit.
///   2. Repli ML Kit on-device si l'IA est indisponible (hors-ligne / erreur).
///   3. Fusion : l'IA prime, ML Kit comble les champs manquants.
///
/// Utilisé par la déclaration multi-documents pour analyser chaque fichier
/// avec la même qualité que le scan d'un document unique.
class OcrPipeline {
  final OcrService _mlKit = OcrService();
  final BackendOcrService _backend;

  OcrPipeline(Dio dio) : _backend = BackendOcrService(dio);

  Future<OcrResult> analyze(File image) async {
    OcrResult? aiResult;
    try {
      aiResult = await _backend.extract(image);
    } catch (_) {
      // Réseau / IA indisponible → on tentera ML Kit.
    }

    OcrResult? mlResult;
    try {
      mlResult = await _mlKit.processImage(image);
    } catch (_) {
      // ML Kit indisponible.
    }

    if (aiResult != null && _hasData(aiResult)) {
      return _merge(aiResult, mlResult);
    }
    if (mlResult != null && mlResult.rawText.trim().isNotEmpty) {
      return mlResult;
    }
    return mlResult ??
        const OcrResult(rawText: '', kind: DocumentKind.unknown);
  }

  bool _hasData(OcrResult r) =>
      (r.lastName ?? r.firstName ?? r.documentNumber ?? r.birthDate) != null;

  OcrResult _merge(OcrResult primary, OcrResult? secondary) {
    if (secondary == null) return primary;
    return OcrResult(
      rawText: primary.rawText.isNotEmpty ? primary.rawText : secondary.rawText,
      documentNumber: primary.documentNumber ?? secondary.documentNumber,
      lastName: primary.lastName ?? secondary.lastName,
      firstName: primary.firstName ?? secondary.firstName,
      birthDate: primary.birthDate ?? secondary.birthDate,
      expiryDate: primary.expiryDate ?? secondary.expiryDate,
      mrz: primary.mrz ?? secondary.mrz,
      kind: primary.kind != DocumentKind.unknown
          ? primary.kind
          : secondary.kind,
    );
  }

  void dispose() => _mlKit.dispose();
}

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/ocr_result.dart';
import '../services/backend_ocr_service.dart';
import '../services/ocr_service.dart';

// ─── États ────────────────────────────────────────────────────────────────────

sealed class OcrState {
  const OcrState();
}

class OcrIdle extends OcrState {
  const OcrIdle();
}

class OcrProcessing extends OcrState {
  final String message;
  const OcrProcessing([this.message = 'Analyse en cours…']);
}

class OcrSuccess extends OcrState {
  final OcrResult result;
  final File image;
  /// true = Mistral a amélioré ou remplacé le résultat ML Kit
  final bool usedAiFallback;
  const OcrSuccess(this.result, this.image, {this.usedAiFallback = false});
}

class OcrError extends OcrState {
  final String message;
  const OcrError(this.message);
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class OcrNotifier extends StateNotifier<OcrState> {
  final OcrService _mlKit = OcrService();
  final BackendOcrService _backend;

  OcrNotifier(Dio dio)
      : _backend = BackendOcrService(dio),
        super(const OcrIdle());

  /// Pipeline de traitement.
  ///
  ///  Étape 1 — IA backend (Mistral Vision via /ocr/extract).
  ///            Moteur principal : lit l'imprimé ET le manuscrit, clé serveur.
  ///  Étape 2 — Repli ML Kit on-device (hors-ligne ou IA indisponible).
  ///            On le combine à l'IA si celle-ci n'a rempli que partiellement.
  ///  Étape 3 — Rien → champs vides (saisie manuelle), jamais d'écran d'erreur.
  Future<void> processImage(File imageFile) async {
    // ── Étape 1 : IA backend ──────────────────────────────────────────────
    state = const OcrProcessing('Analyse IA en cours…');
    OcrResult? aiResult;
    try {
      aiResult = await _backend.extract(imageFile);
    } catch (_) {
      // Réseau / serveur indisponible → on bascule sur ML Kit local.
    }

    // ── Étape 2 : ML Kit on-device ────────────────────────────────────────
    OcrResult? mlResult;
    try {
      state = const OcrProcessing('Lecture du document…');
      mlResult = await _mlKit.processImage(imageFile);
    } catch (_) {
      // ML Kit indisponible
    }

    // ── Décision ──────────────────────────────────────────────────────────
    if (aiResult != null && _hasData(aiResult)) {
      // IA prioritaire ; ML Kit comble d'éventuels champs nuls.
      final merged = _merge(aiResult, mlResult);
      state = OcrSuccess(merged, imageFile, usedAiFallback: true);
      return;
    }

    if (mlResult != null && mlResult.rawText.trim().isNotEmpty) {
      state = OcrSuccess(mlResult, imageFile, usedAiFallback: false);
      return;
    }

    // ── Étape 3 : rien d'exploitable → saisie manuelle ────────────────────
    state = OcrSuccess(
      mlResult ?? const OcrResult(rawText: '', kind: DocumentKind.unknown),
      imageFile,
    );
  }

  void reset() => state = const OcrIdle();

  bool _hasData(OcrResult r) =>
      (r.lastName ?? r.firstName ?? r.documentNumber ?? r.birthDate) != null;

  /// Fusionne deux résultats : [primary] prioritaire, [secondary] comble les null.
  OcrResult _merge(OcrResult primary, OcrResult? secondary) {
    if (secondary == null) return primary;
    return OcrResult(
      rawText:        primary.rawText.isNotEmpty ? primary.rawText : secondary.rawText,
      documentNumber: primary.documentNumber ?? secondary.documentNumber,
      lastName:       primary.lastName  ?? secondary.lastName,
      firstName:      primary.firstName ?? secondary.firstName,
      birthDate:      primary.birthDate ?? secondary.birthDate,
      expiryDate:     primary.expiryDate ?? secondary.expiryDate,
      mrz:            primary.mrz ?? secondary.mrz,
      kind: primary.kind != DocumentKind.unknown
          ? primary.kind
          : secondary.kind,
    );
  }

  @override
  void dispose() {
    _mlKit.dispose();
    super.dispose();
  }
}

final ocrProvider =
    StateNotifierProvider.autoDispose<OcrNotifier, OcrState>(
  (ref) => OcrNotifier(ref.read(dioProvider)),
);

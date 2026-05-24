import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ocr_result.dart';
import '../services/ocr_service.dart';

// États possibles du flux OCR
sealed class OcrState {
  const OcrState();
}

class OcrIdle extends OcrState { const OcrIdle(); }
class OcrProcessing extends OcrState { const OcrProcessing(); }
class OcrSuccess extends OcrState {
  final OcrResult result;
  final File image;
  const OcrSuccess(this.result, this.image);
}
class OcrError extends OcrState {
  final String message;
  const OcrError(this.message);
}

class OcrNotifier extends StateNotifier<OcrState> {
  final OcrService _service = OcrService();

  OcrNotifier() : super(const OcrIdle());

  /// Traite une image capturée (depuis caméra ou galerie)
  Future<void> processImage(File imageFile) async {
    state = const OcrProcessing();
    try {
      final result = await _service.processImage(imageFile);
      if (result.isEmpty) {
        state = const OcrError(
          'Aucun texte détecté. Assurez-vous que le document est bien éclairé et net.',
        );
        return;
      }
      state = OcrSuccess(result, imageFile);
    } catch (e) {
      state = OcrError('Erreur OCR : ${e.toString()}');
    }
  }

  void reset() => state = const OcrIdle();

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}

final ocrProvider = StateNotifierProvider.autoDispose<OcrNotifier, OcrState>(
  (ref) => OcrNotifier(),
);

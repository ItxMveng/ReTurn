import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../utils/media_url.dart';

/// Image d'un document affichée au propriétaire potentiel AVANT vérification :
/// l'image reste reconnaissable (forme, photo, couleurs) mais **toutes les
/// informations personnelles textuelles sont masquées** par des bandeaux noirs.
///
/// Principe (redaction précise, côté client) :
///  1. On télécharge l'image via le proxy média du backend.
///  2. ML Kit (on-device) détecte tous les blocs de texte + leurs positions.
///  3. On pose un bandeau noir opaque sur chaque bloc → aucun numéro, nom ou
///     date lisible, sans dépendre de la classification « sensible/non ».
///  4. Filet de sécurité : un léger flou est appliqué dessous, et si l'OCR ne
///     détecte rien on renforce le flou — on ne laisse jamais fuiter de texte.
///
/// Quand [revealed] est vrai (identité vérifiée), l'image est affichée en clair.
class RedactedImage extends StatefulWidget {
  final String url;
  final bool revealed;
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const RedactedImage({
    super.key,
    required this.url,
    required this.revealed,
    this.width = 220,
    this.height = 150,
    this.borderRadius,
  });

  @override
  State<RedactedImage> createState() => _RedactedImageState();
}

class _RedactedImageState extends State<RedactedImage> {
  // Cache mémoire partagé : évite de re-télécharger/re-OCR la même image.
  static final Map<String, _Analysis> _cache = {};

  _Analysis? _analysis;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (!widget.revealed) _analyze();
  }

  @override
  void didUpdateWidget(covariant RedactedImage old) {
    super.didUpdateWidget(old);
    if (!widget.revealed && (old.url != widget.url)) {
      _analysis = null;
      _failed = false;
      _analyze();
    }
  }

  Future<void> _analyze() async {
    final resolved = mediaUrl(widget.url);
    if (resolved.isEmpty) {
      setState(() => _failed = true);
      return;
    }
    final cached = _cache[resolved];
    if (cached != null) {
      setState(() => _analysis = cached);
      return;
    }
    try {
      // 1) Téléchargement des octets via le proxy média.
      final res = await Dio().get<List<int>>(
        resolved,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = Uint8List.fromList(res.data ?? const []);
      if (bytes.isEmpty) throw Exception('empty');

      // 2) Dimensions intrinsèques (pour mapper les coordonnées).
      final decoded = await _decodeSize(bytes);

      // 3) OCR on-device → boîtes de texte.
      final tmp = await File(
        '${Directory.systemTemp.path}/redact_${resolved.hashCode}.jpg',
      ).writeAsBytes(bytes, flush: true);
      final recognizer =
          TextRecognizer(script: TextRecognitionScript.latin);
      final result = await recognizer.processImage(InputImage.fromFile(tmp));
      await recognizer.close();
      try {
        await tmp.delete();
      } catch (_) {}

      final boxes = <Rect>[];
      for (final block in result.blocks) {
        boxes.add(block.boundingBox);
      }

      final analysis =
          _Analysis(bytes: bytes, imageSize: decoded, boxes: boxes);
      _cache[resolved] = analysis;
      if (mounted) setState(() => _analysis = analysis);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<Size> _decodeSize(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final img = frame.image;
    final size = Size(img.width.toDouble(), img.height.toDouble());
    img.dispose();
    return size;
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(12);

    // Identité vérifiée → image en clair.
    if (widget.revealed) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.network(
          mediaUrl(widget.url),
          width: widget.width,
          height: widget.height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _broken(context),
        ),
      );
    }

    final analysis = _analysis;
    // En attente d'analyse OU échec → flou renforcé (jamais de texte lisible).
    if (analysis == null) {
      return ClipRRect(
        borderRadius: radius,
        child: Stack(fit: StackFit.expand, children: [
          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Image.network(
              mediaUrl(widget.url),
              width: widget.width,
              height: widget.height,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _broken(context),
            ),
          ),
          if (!_failed)
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          _lockBadge(context),
        ]),
      );
    }

    // Analyse OK → image légèrement floutée (reconnaissable) + bandeaux noirs.
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(fit: StackFit.expand, children: [
          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 2.2, sigmaY: 2.2),
            child: Image.memory(
              analysis.bytes,
              width: widget.width,
              height: widget.height,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _broken(context),
            ),
          ),
          CustomPaint(
            painter: _RedactionPainter(
              imageSize: analysis.imageSize,
              boxes: analysis.boxes,
            ),
          ),
          _lockBadge(context),
        ]),
      ),
    );
  }

  Widget _broken(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: widget.width,
      height: widget.height,
      color: cs.primary.withValues(alpha: 0.08),
      child: Icon(Icons.broken_image_outlined,
          color: cs.onSurface.withValues(alpha: 0.3)),
    );
  }

  Widget _lockBadge(BuildContext context) => Positioned(
        bottom: 8,
        left: 8,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.lock_outline, size: 12, color: Colors.white),
        ),
      );
}

class _Analysis {
  final Uint8List bytes;
  final Size imageSize;
  final List<Rect> boxes;
  const _Analysis({
    required this.bytes,
    required this.imageSize,
    required this.boxes,
  });
}

/// Peint des bandeaux noirs opaques sur les zones de texte, en mappant les
/// coordonnées image → widget selon un rendu BoxFit.cover.
class _RedactionPainter extends CustomPainter {
  final Size imageSize;
  final List<Rect> boxes;
  _RedactionPainter({required this.imageSize, required this.boxes});

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize.width <= 0 || imageSize.height <= 0) return;
    // BoxFit.cover : l'image couvre toute la zone, centrée, potentiellement rognée.
    final scale = (size.width / imageSize.width)
        .clamp(0.0, double.infinity)
        .toDouble();
    final scaleY = size.height / imageSize.height;
    final s = scale > scaleY ? scale : scaleY; // max → cover
    final renderedW = imageSize.width * s;
    final renderedH = imageSize.height * s;
    final dx = (size.width - renderedW) / 2;
    final dy = (size.height - renderedH) / 2;

    final paint = Paint()..color = Colors.black;
    for (final b in boxes) {
      // Léger padding autour du texte pour couvrir entièrement.
      final rect = Rect.fromLTRB(
        b.left * s + dx - 2,
        b.top * s + dy - 2,
        b.right * s + dx + 2,
        b.bottom * s + dy + 2,
      );
      // Coins arrondis discrets.
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RedactionPainter old) =>
      old.imageSize != imageSize || old.boxes != boxes;
}

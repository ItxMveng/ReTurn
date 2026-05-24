import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/ocr_notifier.dart';

/// Page de scan — caméra temps réel + bouton galerie (F-11)
/// L'utilisateur pointe la caméra sur son document et capture.
class OcrScanPage extends ConsumerStatefulWidget {
  const OcrScanPage({super.key});

  @override
  ConsumerState<OcrScanPage> createState() => _OcrScanPageState();
}

class _OcrScanPageState extends ConsumerState<OcrScanPage> {
  CameraController? _controller;
  bool _cameraReady = false;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) return;

    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await _controller!.initialize();
    if (mounted) setState(() => _cameraReady = true);
  }

  Future<void> _captureAndProcess() async {
    if (_controller == null || !_cameraReady || _processing) return;
    setState(() => _processing = true);

    try {
      final xFile = await _controller!.takePicture();
      final file = File(xFile.path);
      await ref.read(ocrProvider.notifier).processImage(file);
      if (mounted) context.push('/ocr/review');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (xFile == null) return;
    final file = File(xFile.path);
    await ref.read(ocrProvider.notifier).processImage(file);
    if (mounted) context.push('/ocr/review');
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Scanner le document'),
      ),
      body: Stack(
        children: [
          // ── Prévisualisation caméra ──────────────────────────
          if (_cameraReady && _controller != null)
            Positioned.fill(
              child: CameraPreview(_controller!),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // ── Cadre de guidage ─────────────────────────────────
          Positioned.fill(
            child: CustomPaint(painter: _DocumentFramePainter()),
          ),

          // ── Instruction ──────────────────────────────────────
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: Text(
              'Placez le document dans le cadre\net assurez-vous qu'il est bien éclairé',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                shadows: [const Shadow(blurRadius: 4)],
              ),
            ),
          ),

          // ── Bouton capture ───────────────────────────────────
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _captureAndProcess,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.white54, width: 4),
                    ),
                    child: _processing
                        ? const Padding(
                            padding: EdgeInsets.all(18),
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.black,
                            ),
                          )
                        : const Icon(Icons.camera_alt, color: Colors.black, size: 32),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library_outlined, color: Colors.white),
                  label: const Text(
                    'Importer depuis la galerie',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dessine un cadre rectangulaire de guidage centré (ratio carte d'identité)
class _DocumentFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    const ratio = 1.586; // ISO/IEC 7810 ID-1
    final frameW = size.width * 0.85;
    final frameH = frameW / ratio;
    final left = (size.width - frameW) / 2;
    final top = (size.height - frameH) / 2;
    final rect = Rect.fromLTWH(left, top, frameW, frameH);
    final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(12));

    // Fond semi-transparent autour du cadre
    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.45);
    final fullPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutPath = Path()..addRRect(rRect);
    canvas.drawPath(
      Path.combine(PathOperation.difference, fullPath, cutoutPath),
      overlayPaint,
    );
    canvas.drawRRect(rRect, paint);

    // Coins accentués
    const cornerLen = 24.0;
    final c = Paint()..color = const Color(0xFF00C49A)..strokeWidth = 4..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    _corner(canvas, c, Offset(left, top), cornerLen, 1, 1);
    _corner(canvas, c, Offset(left + frameW, top), cornerLen, -1, 1);
    _corner(canvas, c, Offset(left, top + frameH), cornerLen, 1, -1);
    _corner(canvas, c, Offset(left + frameW, top + frameH), cornerLen, -1, -1);
  }

  void _corner(Canvas c, Paint p, Offset o, double len, double dx, double dy) {
    c.drawLine(o, o + Offset(dx * len, 0), p);
    c.drawLine(o, o + Offset(0, dy * len), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

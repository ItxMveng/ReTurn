import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_loader.dart';

final _pickedImageProvider = StateProvider<File?>((ref) => null);
final _scanningProvider = StateProvider<bool>((ref) => false);

class OcrScanPage extends ConsumerWidget {
  const OcrScanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final image = ref.watch(_pickedImageProvider);
    final scanning = ref.watch(_scanningProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scanner un document',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: image == null
                ? _PlaceholderView()
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(image, fit: BoxFit.contain),
                      if (scanning)
                        Container(
                          color: Colors.black45,
                          child: const AppLoader(
                              message: 'Analyse en cours…'),
                        ),
                    ],
                  ),
          ),
          _BottomBar(
            hasImage: image != null,
            onPickGallery: () async {
              final f = await _pickImage(ImageSource.gallery);
              if (f != null) ref.read(_pickedImageProvider.notifier).state = f;
            },
            onPickCamera: () async {
              final f = await _pickImage(ImageSource.camera);
              if (f != null) ref.read(_pickedImageProvider.notifier).state = f;
            },
            onAnalyze: scanning
                ? null
                : () async {
                    if (image == null) return;
                    ref.read(_scanningProvider.notifier).state = true;
                    await Future.delayed(const Duration(seconds: 2)); // TODO: MLKit
                    ref.read(_scanningProvider.notifier).state = false;
                    if (context.mounted) {
                      context.push('/ocr/review',
                          extra: {'imagePath': image.path, 'fields': <String, String>{}});
                    }
                  },
          ),
        ],
      ),
    );
  }

  Future<File?> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: source, imageQuality: 90, maxWidth: 1920);
    return picked == null ? null : File(picked.path);
  }
}

class _PlaceholderView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.document_scanner_outlined,
              size: 80, color: Colors.white38),
          SizedBox(height: 16),
          Text(
            'Prenez une photo ou choisissez\nune image de votre galerie',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final bool hasImage;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;
  final VoidCallback? onAnalyze;

  const _BottomBar({
    required this.hasImage,
    required this.onPickGallery,
    required this.onPickCamera,
    required this.onAnalyze,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
      child: Row(
        children: [
          _IconBtn(
            icon: Icons.photo_library_outlined,
            label: 'Galerie',
            onPressed: onPickGallery,
          ),
          const SizedBox(width: 8),
          _IconBtn(
            icon: Icons.camera_alt_outlined,
            label: 'Caméra',
            onPressed: onPickCamera,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AppButton(
              label: 'Analyser',
              onPressed: hasImage ? onAnalyze : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _IconBtn({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white30),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

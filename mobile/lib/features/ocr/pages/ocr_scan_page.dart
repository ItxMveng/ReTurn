import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/media_service.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_loader.dart';
import '../providers/ocr_notifier.dart';

final _pickedImageProvider = StateProvider.autoDispose<File?>((ref) => null);

class OcrScanPage extends ConsumerStatefulWidget {
  const OcrScanPage({super.key});

  @override
  ConsumerState<OcrScanPage> createState() => _OcrScanPageState();
}

class _OcrScanPageState extends ConsumerState<OcrScanPage> {
  @override
  void initState() {
    super.initState();
    // Propose immédiatement caméra ou galerie : l'utilisateur ne doit pas
    // rester devant un écran noir sans comprendre quoi faire.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(_pickedImageProvider) == null) {
        _chooseSource();
      }
    });
  }

  Future<void> _chooseSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Text('Scanner le document',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Prendre une photo'),
            subtitle: const Text('Utilisez la caméra arrière'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choisir dans la galerie'),
            subtitle: const Text('Une photo déjà prise du document'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (source != null) await _pick(source);
  }

  Future<void> _pick(ImageSource source) async {
    final result = await MediaService.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 1920,
    );
    if (!mounted) return;
    if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.error!),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 5),
      ));
      return;
    }
    if (result.file != null) {
      ref.read(_pickedImageProvider.notifier).state = File(result.file!.path);
      ref.read(ocrProvider.notifier).reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = ref.watch(_pickedImageProvider);
    final ocrState = ref.watch(ocrProvider);

    final isProcessing = ocrState is OcrProcessing;
    final processingMsg =
        ocrState is OcrProcessing ? ocrState.message : 'Analyse en cours…';

    // Navigation automatique dès que l'analyse réussit.
    // On attend le résultat de la page de vérification puis on le renvoie
    // AU FORMULAIRE (qui a fait `await push('/ocr/scan')`). Sans ça,
    // l'utilisateur restait bloqué sur l'écran image après "Utiliser".
    ref.listen<OcrState>(ocrProvider, (_, next) async {
      if (next is OcrSuccess) {
        final result =
            await context.push<Map<String, dynamic>>('/ocr/review');
        if (result != null && context.mounted) {
          context.pop(result); // remonte les infos au formulaire
        }
      } else if (next is OcrError) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });

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
                ? GestureDetector(
                    onTap: _chooseSource,
                    behavior: HitTestBehavior.opaque,
                    child: const _PlaceholderView(),
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(image, fit: BoxFit.contain),
                      if (isProcessing)
                        Container(
                          color: Colors.black54,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AppLoader(message: processingMsg),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
          _BottomBar(
            hasImage: image != null,
            isProcessing: isProcessing,
            onPickGallery:
                isProcessing ? null : () => _pick(ImageSource.gallery),
            onPickCamera:
                isProcessing ? null : () => _pick(ImageSource.camera),
            onAnalyze: (image == null || isProcessing)
                ? null
                : () => ref.read(ocrProvider.notifier).processImage(image),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderView extends StatelessWidget {
  const _PlaceholderView();

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
          SizedBox(height: 8),
          Text(
            'IA Mistral (imprimé + manuscrit) · repli local',
            style: TextStyle(color: Colors.white30, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final bool hasImage;
  final bool isProcessing;
  final VoidCallback? onPickGallery;
  final VoidCallback? onPickCamera;
  final VoidCallback? onAnalyze;

  const _BottomBar({
    required this.hasImage,
    required this.isProcessing,
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
              label: isProcessing ? 'Analyse…' : 'Analyser',
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
  final VoidCallback? onPressed;

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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(height: 2),
            Text(label,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:docretour/core/theme/app_theme.dart';
import 'package:docretour/features/messaging/providers/messaging_provider.dart';
import 'package:docretour/l10n/app_localizations.dart';

class IdentityVerificationScreen extends ConsumerStatefulWidget {
  final String matchId;
  const IdentityVerificationScreen({super.key, required this.matchId});

  @override
  ConsumerState<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends ConsumerState<IdentityVerificationScreen> {
  File? _selfie;
  Map<String, dynamic>? _status;
  bool _loading = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final repo = ref.read(messagingRepositoryProvider);
    final s = await repo.getVerificationStatus(widget.matchId);
    if (mounted) setState(() => _status = s);
  }

  Future<void> _pickSelfie() async {
    final xFile = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front);
    if (xFile != null && mounted) {
      setState(() => _selfie = File(xFile.path));
    }
  }

  Future<void> _request() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(messagingRepositoryProvider);
      final result = await repo.requestVerification(widget.matchId);
      setState(() => _status = result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_selfie == null) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(messagingRepositoryProvider);
      final result = await repo.submitSelfie(widget.matchId, _selfie!.path);
      if (mounted) setState(() => _status = result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final isApproved = _status?['status'] == 'approved';
    final isPending = _status?['status'] == 'pending';

    return Scaffold(
      appBar: AppBar(
        title: Text(l.verifyTitle),
        backgroundColor: cs.secondary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cs.outline),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: kGreen.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_user_outlined,
                        size: 40, color: kGreen),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l.verifyTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.verifyDesc,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.55),
                        fontSize: 13,
                        height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (isApproved) ...[
              _SuccessBanner(message: l.verifyApproved),
            ] else if (_status == null) ...[
              ElevatedButton.icon(
                onPressed: _loading ? null : _request,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.fingerprint),
                label: Text(l.verifyStart),
              ),
            ] else if (isPending) ...[
              Text(l.selfieRequired,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: cs.onSurface)),
              const SizedBox(height: 12),
              if (_selfie != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(_selfie!,
                      height: 220, fit: BoxFit.cover),
                ),
                const SizedBox(height: 12),
              ],
              OutlinedButton.icon(
                onPressed: _loading ? null : _pickSelfie,
                icon: const Icon(Icons.camera_front_outlined),
                label: Text(l.verifyTakeSelfie),
              ),
              if (_selfie != null) ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.upload_outlined),
                  label: Text(l.verifySubmit),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  final String message;
  const _SuccessBanner({required this.message});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kGreen),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: kGreen),
            const SizedBox(width: 12),
            Expanded(
                child: Text(message,
                    style: const TextStyle(
                        color: kGreen, fontWeight: FontWeight.w600))),
          ],
        ),
      );
}

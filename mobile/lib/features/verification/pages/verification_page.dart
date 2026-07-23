import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/media_service.dart';
import '../../../core/widgets/appear.dart';
import '../../../l10n/app_localizations.dart';
import '../repositories/verification_repository.dart';

/// Étapes possibles — seules celles du niveau calculé sont affichées :
///   Niveau 1 (score ≥ 0.75)   : questions (nom + date de naissance)
///   Niveau 2 (0.50 – 0.74)    : questions + selfie
///   Niveau 3 (0.45 – 0.49)    : questions (+ numéro doc) + selfie + photo
///                               du document + revue admin
enum _Step { loading, intro, questions, selfie, docPhoto, review, rejected, done }

class VerificationPage extends ConsumerStatefulWidget {
  final String matchId;
  const VerificationPage({super.key, required this.matchId});

  @override
  ConsumerState<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends ConsumerState<VerificationPage> {
  _Step _step = _Step.loading;
  final _docCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  DateTime? _dob;
  int _level = 1;
  double? _matchScore;
  String? _rejectionReason;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _docCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  VerificationRepository get _repo =>
      ref.read(verificationRepositoryProvider);

  /// Nombre total d'étapes actives selon le niveau (hors intro/done).
  int get _totalSteps => switch (_level) { 1 => 1, 2 => 2, _ => 3 };

  Future<void> _loadStatus() async {
    try {
      // Récupère le score du match (affichage + niveau côté client).
      _matchScore = await _repo.matchScore(widget.matchId);
    } catch (_) {/* le niveau backend fait foi de toute façon */}
    try {
      // Démarre/récupère la demande — le backend fixe verification_level.
      final s = await _repo.start(widget.matchId);
      if (!mounted) return;
      _level = (s['verification_level'] as num?)?.toInt() ??
          _levelFromScore(_matchScore);
      final status = s['status'] as String?;
      final questionsPassed = s['questions_passed'] == true;
      final hasSelfie = (s['selfie_url'] as String?)?.isNotEmpty == true;
      final hasDocPhoto = (s['doc_photo_url'] as String?)?.isNotEmpty == true;
      _rejectionReason = s['rejection_reason'] as String?;

      setState(() {
        if (status == 'approved') {
          _step = _Step.done;
        } else if (status == 'rejected') {
          _step = _Step.rejected;
        } else if (!questionsPassed) {
          _step = _Step.intro;
        } else if (_level >= 2 && !hasSelfie) {
          _step = _Step.selfie;
        } else if (_level >= 3 && !hasDocPhoto) {
          _step = _Step.docPhoto;
        } else if (_level >= 3) {
          _step = _Step.review;
        } else {
          _step = _Step.intro;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _step = _Step.intro);
    }
  }

  static int _levelFromScore(double? score) {
    if (score == null) return 2;
    if (score >= 0.75) return 1;
    if (score >= 0.50) return 2;
    return 3;
  }

  String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDob() async {
    final l = AppLocalizations.of(context);
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 25),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 16, now.month, now.day),
      helpText: l.verifDobHelp,
      cancelText: l.cancel,
      confirmText: l.verifValidate,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _submitAnswers() async {
    final l = AppLocalizations.of(context);
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = l.verifErrName);
      return;
    }
    if (_dob == null) {
      setState(() => _error = l.verifErrDob);
      return;
    }
    if (_level >= 3 && _docCtrl.text.trim().isEmpty) {
      setState(() => _error = l.verifErrDocNum);
      return;
    }
    HapticFeedback.lightImpact();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final s = await _repo.submitAnswers(
        widget.matchId,
        fullName: _nameCtrl.text.trim(),
        dateOfBirth: _isoDate(_dob!),
        documentNumber: _docCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        // Niveau 1 : approbation immédiate côté backend.
        if (s['status'] == 'approved' || _level == 1) {
          _step = _Step.done;
        } else {
          _step = _Step.selfie;
        }
      });
    } on DioException catch (e) {
      final detail = e.response?.data is Map
          ? (e.response?.data as Map)['detail']
          : null;
      setState(() => _error = detail is String ? detail : l.verifErrMismatch);
    } catch (_) {
      setState(() => _error = l.verifErrGeneric);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _takeSelfie() async {
    final picked = await MediaService.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 70,
      maxWidth: 800,
    );
    if (!mounted) return;
    if (picked.error != null) {
      setState(() => _error = picked.error);
      return;
    }
    final shot = picked.file;
    if (shot == null) return;
    HapticFeedback.lightImpact();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final s = await _repo.submitSelfie(widget.matchId, File(shot.path));
      if (!mounted) return;
      setState(() {
        if (_level >= 3) {
          _step = _Step.docPhoto;
        } else if (s['status'] == 'approved') {
          _step = _Step.done;
        } else {
          _step = _Step.review;
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context).verifErrSelfie);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _takeDocPhoto() async {
    final picked = await MediaService.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (!mounted) return;
    if (picked.error != null) {
      setState(() => _error = picked.error);
      return;
    }
    final shot = picked.file;
    if (shot == null) return;
    HapticFeedback.lightImpact();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _repo.submitDocPhoto(widget.matchId, File(shot.path));
      if (mounted) setState(() => _step = _Step.review);
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context).verifErrDocPhoto);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Progression selon les étapes réellement actives pour ce niveau.
    final progress = switch (_step) {
      _Step.loading || _Step.intro => 0,
      _Step.questions => 1,
      _Step.selfie => 2,
      _Step.docPhoto => 3,
      _Step.review || _Step.rejected || _Step.done => _totalSteps,
    };
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).verifTitle)),
      body: SafeArea(
        child: Column(children: [
          if (_step != _Step.loading && _step != _Step.done)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Row(
                children: List.generate(_totalSteps, (i) {
                  final active = i < progress;
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin:
                          EdgeInsets.only(right: i < _totalSteps - 1 ? 6 : 0),
                      decoration: BoxDecoration(
                        color: active
                            ? cs.primary
                            : cs.onSurface.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  );
                }),
              ),
            ),
          Expanded(child: switch (_step) {
            _Step.loading =>
              const Center(child: CircularProgressIndicator()),
            _Step.intro => _IntroStep(
                level: _level,
                onStart: () => setState(() => _step = _Step.questions),
              ),
            _Step.questions => _QuestionsStep(
                level: _level,
                docCtrl: _docCtrl,
                nameCtrl: _nameCtrl,
                dob: _dob,
                onPickDob: _pickDob,
                busy: _busy,
                error: _error,
                onSubmit: _submitAnswers,
              ),
            _Step.selfie => _SelfieStep(
                busy: _busy,
                error: _error,
                onTake: _takeSelfie,
              ),
            _Step.docPhoto => _DocPhotoStep(
                busy: _busy,
                error: _error,
                onTake: _takeDocPhoto,
              ),
            _Step.review => _ReviewStep(onClose: () => context.pop()),
            _Step.rejected => _RejectedStep(
                reason: _rejectionReason,
                onRetry: () => setState(() {
                  _error = null;
                  _step = _Step.questions;
                }),
                onClose: () => context.pop(),
              ),
            _Step.done => _DoneStep(
                onClose: () => context.pop(),
                onRestitution: () => context
                    .pushReplacement('/restitution/${widget.matchId}'),
              ),
          }),
        ]),
      ),
    );
  }
}

// ── Étape 0 : intro rassurante, adaptée au niveau ───────────────────────────────
class _IntroStep extends StatelessWidget {
  final int level;
  final VoidCallback onStart;
  const _IntroStep({required this.level, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    final bullets = switch (level) {
      1 => [
          _Bullet(icon: Icons.bolt_outlined, text: l.verifL1B1),
          _Bullet(
              icon: Icons.lock_outline, text: l.verifBulletConfidential),
          _Bullet(
              icon: Icons.shield_moon_outlined, text: l.verifBulletProtect),
        ],
      2 => [
          _Bullet(icon: Icons.fact_check_outlined, text: l.verifL2B1),
          _Bullet(icon: Icons.lock_outline, text: l.verifL2B2),
          _Bullet(
              icon: Icons.shield_moon_outlined, text: l.verifBulletProtect),
        ],
      _ => [
          _Bullet(icon: Icons.fact_check_outlined, text: l.verifL3B1),
          _Bullet(
              icon: Icons.admin_panel_settings_outlined, text: l.verifL3B2),
          _Bullet(icon: Icons.lock_outline, text: l.verifL3B3),
        ],
    };
    return Appear(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.verified_user_outlined,
                  size: 42, color: cs.primary),
            ),
          ),
          const SizedBox(height: 20),
          Text(l.verifIntroTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface)),
          const SizedBox(height: 12),
          Text(
            l.verifIntroBody,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: cs.onSurface.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 24),
          ...bullets,
          const SizedBox(height: 28),
          FilledButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              onStart();
            },
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52)),
            child: Text(l.verifStart),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Bullet({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: cs.primary),
        const SizedBox(width: 12),
        Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: cs.onSurface.withValues(alpha: 0.75)))),
      ]),
    );
  }
}

// ── Étape 1 : questions de contrôle (nom + date de naissance [+ numéro]) ────────
class _QuestionsStep extends StatelessWidget {
  final int level;
  final TextEditingController docCtrl;
  final TextEditingController nameCtrl;
  final DateTime? dob;
  final VoidCallback onPickDob;
  final bool busy;
  final String? error;
  final VoidCallback onSubmit;
  const _QuestionsStep({
    required this.level,
    required this.docCtrl,
    required this.nameCtrl,
    required this.dob,
    required this.onPickDob,
    required this.busy,
    required this.error,
    required this.onSubmit,
  });

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    return Appear(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(l.verifQTitle,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface)),
          const SizedBox(height: 6),
          Text(
            level >= 3 ? l.verifQSubtitle3 : l.verifQSubtitle,
            style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: cs.onSurface.withValues(alpha: 0.65)),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l.verifFieldName,
              prefixIcon: const Icon(Icons.person_outline),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: onPickDob,
            borderRadius: BorderRadius.circular(8),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: l.verifFieldDob,
                prefixIcon: const Icon(Icons.cake_outlined),
                suffixIcon:
                    const Icon(Icons.calendar_today_outlined, size: 18),
                border: const OutlineInputBorder(),
              ),
              child: Text(
                dob != null ? _formatDate(dob!) : l.verifDobSelect,
                style: TextStyle(
                  fontSize: 16,
                  color: dob != null
                      ? cs.onSurface
                      : cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          if (level >= 3) ...[
            const SizedBox(height: 16),
            TextField(
              controller: docCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: l.verifFieldDocNum,
                helperText: l.verifFieldDocNumHelper,
                prefixIcon: const Icon(Icons.numbers),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 16),
            _ErrorBanner(error!),
          ],
          const SizedBox(height: 28),
          FilledButton(
            onPressed: busy ? null : onSubmit,
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52)),
            child: busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(l.verifSubmit),
          ),
        ],
      ),
    );
  }
}

// ── Étape 2 : selfie (niveaux 2 et 3) ───────────────────────────────────────────
class _SelfieStep extends StatelessWidget {
  final bool busy;
  final String? error;
  final VoidCallback onTake;
  const _SelfieStep(
      {required this.busy, required this.error, required this.onTake});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    return Appear(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(Icons.camera_front_outlined, size: 42, color: cs.primary),
            ),
          ),
          const SizedBox(height: 20),
          Text(l.verifSelfieTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface)),
          const SizedBox(height: 12),
          Text(
            l.verifSelfieBody,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: cs.onSurface.withValues(alpha: 0.7)),
          ),
          if (error != null) ...[
            const SizedBox(height: 16),
            _ErrorBanner(error!),
          ],
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: busy ? null : onTake,
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52)),
            icon: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.camera_alt_outlined),
            label: Text(l.verifSelfieBtn),
          ),
        ],
      ),
    );
  }
}

// ── Étape 3 : photo du document (niveau 3 uniquement) ───────────────────────────
class _DocPhotoStep extends StatelessWidget {
  final bool busy;
  final String? error;
  final VoidCallback onTake;
  const _DocPhotoStep(
      {required this.busy, required this.error, required this.onTake});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    return Appear(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.document_scanner_outlined,
                  size: 42, color: cs.primary),
            ),
          ),
          const SizedBox(height: 20),
          Text(l.verifDocTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface)),
          const SizedBox(height: 12),
          Text(
            l.verifDocBody,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: cs.onSurface.withValues(alpha: 0.7)),
          ),
          if (error != null) ...[
            const SizedBox(height: 16),
            _ErrorBanner(error!),
          ],
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: busy ? null : onTake,
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52)),
            icon: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.photo_camera_back_outlined),
            label: Text(l.verifDocBtn),
          ),
        ],
      ),
    );
  }
}

// ── Revue admin en attente (niveau 3) ───────────────────────────────────────────
class _ReviewStep extends StatelessWidget {
  final VoidCallback onClose;
  const _ReviewStep({required this.onClose});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    return Center(
      child: Appear(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle),
                child: Icon(Icons.hourglass_top_rounded,
                    size: 52, color: cs.primary),
              ),
              const SizedBox(height: 20),
              Text(l.verifReviewTitle,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface)),
              const SizedBox(height: 10),
              Text(
                l.verifReviewBody,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: cs.onSurface.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: onClose,
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52)),
                child: Text(l.verifUnderstood),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Vérification rejetée par l'admin ────────────────────────────────────────────
class _RejectedStep extends StatelessWidget {
  final String? reason;
  final VoidCallback onRetry;
  final VoidCallback onClose;
  const _RejectedStep(
      {required this.reason, required this.onRetry, required this.onClose});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    return Center(
      child: Appear(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                    color: cs.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle),
                child:
                    Icon(Icons.gpp_bad_outlined, size: 52, color: cs.error),
              ),
              const SizedBox(height: 20),
              Text(l.verifRejectedTitle,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface)),
              const SizedBox(height: 10),
              Text(
                reason?.isNotEmpty == true
                    ? l.verifRejectedReason(reason!)
                    : l.verifRejectedBody,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: cs.onSurface.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52)),
                child: Text(l.retry),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: onClose,
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50)),
                child: Text(l.verifClose),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Succès ──────────────────────────────────────────────────────────────────────
class _DoneStep extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onRestitution;
  const _DoneStep({required this.onClose, required this.onRestitution});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    return Center(
      child: Appear(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle),
                child: Icon(Icons.verified_rounded, size: 52, color: cs.primary),
              ),
              const SizedBox(height: 20),
              Text(l.verifDoneTitle,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface)),
              const SizedBox(height: 10),
              Text(
                l.verifDoneBody,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: cs.onSurface.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: onRestitution,
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52)),
                icon: const Icon(Icons.handshake_outlined),
                label: Text(l.verifDoneRestitution),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: onClose,
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50)),
                child: Text(l.verifDoneLater),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String text;
  const _ErrorBanner(this.text);
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.error.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        Icon(Icons.info_outline, size: 18, color: cs.error),
        const SizedBox(width: 10),
        Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 13, color: cs.onSurface))),
      ]),
    );
  }
}

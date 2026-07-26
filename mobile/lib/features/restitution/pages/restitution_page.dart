import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/location_service.dart';
import '../../../core/utils/media_url.dart';
import '../../../l10n/app_localizations.dart';
import '../../matches/providers/matches_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../zones/pages/zones_page.dart';
import '../../zones/repositories/zone_repository.dart';
import '../models/restitution.dart';
import '../repositories/restitution_repository.dart';

/// Écran de restitution guidée (F-33 double validation + F-35 notation) :
/// 1. Planifier le RDV → 2. Confirmer la remise (photo de preuve) → 3. Évaluer.
class RestitutionPage extends ConsumerStatefulWidget {
  final String matchId;
  const RestitutionPage({super.key, required this.matchId});

  @override
  ConsumerState<RestitutionPage> createState() => _RestitutionPageState();
}

class _RestitutionPageState extends ConsumerState<RestitutionPage> {
  bool _busy = false;
  bool _wasCompleted = false;
  bool _showConfetti = false;

  /// Confirme la remise (double validation — sans photo de preuve).
  Future<void> _confirm(Restitution r) async {
    final l = AppLocalizations.of(context);
    HapticFeedback.lightImpact();
    setState(() => _busy = true);

    try {
      final updated =
          await ref.read(restitutionRepositoryProvider).confirm(r.id);
      ref.invalidate(restitutionByMatchProvider(widget.matchId));
      ref.invalidate(restitutionsProvider);
      // Restitution tout juste complétée → confettis !
      if (updated.isCompleted && !_wasCompleted && mounted) {
        HapticFeedback.mediumImpact();
        ref.read(profileProvider.notifier).refresh();
        setState(() => _showConfetti = true);
      }
    } catch (_) {
      _toast(l.restActionFail);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editMeeting(Restitution r) async {
    final l = AppLocalizations.of(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.near_me_outlined),
            title: Text(l.restMeetNearby),
            subtitle: Text(l.restMeetNearbySub),
            onTap: () => Navigator.pop(ctx, 'nearby'),
          ),
          ListTile(
            leading: const Icon(Icons.verified_outlined),
            title: Text(l.restMeetZone),
            subtitle: Text(l.restMeetZoneSub),
            onTap: () => Navigator.pop(ctx, 'zone'),
          ),
          ListTile(
            leading: const Icon(Icons.edit_location_alt_outlined),
            title: Text(l.restMeetManual),
            onTap: () => Navigator.pop(ctx, 'manual'),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (!mounted || choice == null) return;

    String? value;
    if (choice == 'zone') {
      final zone = await pickCertifiedZone(context);
      if (zone == null) return;
      value = '${zone.name} — ${zone.address}';
    } else if (choice == 'nearby') {
      value = await _suggestNearby();
    } else {
      value = await _askText(r.meetingLocation ?? '');
    }
    if (value == null || value.isEmpty) return;
    try {
      await ref.read(restitutionRepositoryProvider).setMeeting(r.id, value);
      ref.invalidate(restitutionByMatchProvider(widget.matchId));
    } catch (_) {
      _toast(l.restMeetingSaveFail);
    }
  }

  /// Suggestions de lieux publics proches : zones certifiées triées par
  /// distance à la position GPS de l'utilisateur.
  Future<String?> _suggestNearby() async {
    final l = AppLocalizations.of(context);
    final pos = await LocationService.coarsePosition();
    if (!mounted) return null;
    if (pos == null) {
      _toast(l.restPosUnavailable);
      return null;
    }
    List<Zone> zones;
    try {
      zones = await ref.read(zoneRepositoryProvider).list();
    } catch (_) {
      _toast(l.restZonesLoadFail);
      return null;
    }
    if (!mounted) return null;
    if (zones.isEmpty) {
      _toast(l.restNoZones);
      return null;
    }

    double distKm(Zone z) {
      const rad = math.pi / 180;
      final dLat = (z.latitude - pos.latitude) * rad;
      final dLon = (z.longitude - pos.longitude) * rad;
      final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
          math.cos(pos.latitude * rad) *
              math.cos(z.latitude * rad) *
              math.sin(dLon / 2) *
              math.sin(dLon / 2);
      return 6371 * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    }

    final sorted = [...zones]..sort((a, b) => distKm(a).compareTo(distKm(b)));
    final top = sorted.take(5).toList();

    final picked = await showModalBottomSheet<Zone>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(l.restNearbyTitle,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
          ...top.map((z) => ListTile(
                leading: const Icon(Icons.place_outlined),
                title: Text(z.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                    '${z.typeLabel} · ${distKm(z).toStringAsFixed(1)} km'),
                onTap: () => Navigator.pop(ctx, z),
              )),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (picked == null) return null;
    return '${picked.name} — ${picked.address}';
  }

  Future<String?> _askText(String initial) {
    final l = AppLocalizations.of(context);
    final ctrl = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.restMeetDialogTitle),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: l.restMeetHint,
            helperText: l.restMeetHelper,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: Text(l.restSave)),
        ],
      ),
    );
  }

  Future<void> _rate(Restitution r, int stars, String comment) async {
    final l = AppLocalizations.of(context);
    try {
      await ref
          .read(restitutionRepositoryProvider)
          .rate(r.id, stars, comment: comment);
      ref.invalidate(restitutionByMatchProvider(widget.matchId));
      _toast(l.restRateThanks);
    } catch (_) {
      _toast(l.restRateFail);
    }
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(restitutionByMatchProvider(widget.matchId));
    // Rôle de l'utilisateur (propriétaire / retrouveur) pour les libellés.
    final match = ref.watch(matchDetailProvider(widget.matchId)).valueOrNull;
    final myId = ref.watch(profileProvider).valueOrNull?.id ?? '';
    final isOwner = match?.isOwner(myId) ?? true;
    final reputation =
        ref.watch(profileProvider).valueOrNull?.scoreReputation;

    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.restTitle)),
      body: Stack(children: [
        async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.wifi_off, size: 40),
                const SizedBox(height: 12),
                Text(l.restLoadError),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => ref
                      .invalidate(restitutionByMatchProvider(widget.matchId)),
                  child: Text(l.retry),
                ),
              ]),
            ),
          ),
          data: (r) {
            _wasCompleted = r?.isCompleted ?? false;
            return r == null
                ? const _NotReady()
                : _Content(
                    r: r,
                    isOwner: isOwner,
                    otherName: match?.otherUserName,
                    otherAvatar: match?.otherUserAvatar,
                    busy: _busy,
                    onConfirm: () => _confirm(r),
                    onEditMeeting: () => _editMeeting(r),
                    onRate: (s, c) => _rate(r, s, c),
                  );
          },
        ),
        if (_showConfetti)
          _ConfettiOverlay(
            reputation: reputation,
            onDone: () => setState(() => _showConfetti = false),
          ),
      ]),
    );
  }
}

class _NotReady extends StatelessWidget {
  const _NotReady();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.handshake_outlined,
                size: 56, color: cs.onSurface.withValues(alpha: 0.25)),
            const SizedBox(height: 16),
            Text(l.restNotReadyTitle,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              l.restNotReadyBody,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.55)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final Restitution r;
  final bool isOwner;
  final String? otherName;
  final String? otherAvatar;
  final bool busy;
  final VoidCallback onConfirm;
  final VoidCallback onEditMeeting;
  final void Function(int stars, String comment) onRate;
  const _Content({
    required this.r,
    required this.isOwner,
    required this.otherName,
    required this.otherAvatar,
    required this.busy,
    required this.onConfirm,
    required this.onEditMeeting,
    required this.onRate,
  });

  bool get _iConfirmed =>
      isOwner ? r.handoffConfirmedByOwner : r.handoffConfirmedByFinder;
  bool get _iRated =>
      isOwner ? r.ratingByOwner != null : r.ratingByFinder != null;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    final hasMeeting = r.meetingLocation?.isNotEmpty == true;
    // Étape courante : 0 = RDV, 1 = remise, 2 = évaluation.
    final currentStep = r.isCompleted ? 2 : (hasMeeting ? 1 : 0);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Progression : RDV → Remise → Évaluation ──
        _Stepper(current: r.isCompleted && _iRated ? 3 : currentStep),
        const SizedBox(height: 20),

        // ── Statut ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (r.isCompleted ? cs.primary : Colors.orange)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: (r.isCompleted ? cs.primary : Colors.orange)
                    .withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            Icon(r.isCompleted ? Icons.verified_rounded : Icons.schedule,
                color: r.isCompleted ? cs.primary : Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                r.isCompleted
                    ? l.restDoneStatus
                    : _iConfirmed
                        ? l.restIConfirmedWaiting
                        : currentStep == 0
                            ? l.restStep1Of3
                            : l.restStep2Of3,
                style: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w500),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 20),

        // ── Étape 1 : lieu de rendez-vous ──
        _Card(
          icon: Icons.location_on_outlined,
          title: l.restMeetDialogTitle,
          subtitle: hasMeeting ? r.meetingLocation! : l.restMeetingUnset,
          trailing: r.isCompleted
              ? null
              : TextButton(
                  onPressed: onEditMeeting,
                  child: Text(hasMeeting ? l.restEdit : l.restChoose)),
        ),
        const SizedBox(height: 12),

        // ── Étape 2 : double confirmation (visible une fois le lieu fixé) ──
        if (hasMeeting)
          _Card(
            icon: Icons.how_to_reg_outlined,
            title: l.restHandoffTitle,
            subtitle:
                '${l.restRoleOwner} : ${r.handoffConfirmedByOwner ? l.restConfirmed : l.restPending}\n'
                '${l.restRoleFinder} : ${r.handoffConfirmedByFinder ? l.restConfirmed : l.restPending}',
          ),
        const SizedBox(height: 20),

        // ── CTA guidé selon l'étape ──
        if (!r.isCompleted && !hasMeeting)
          // Étape 1 : tant qu'aucun lieu n'est fixé, on guide vers ce choix.
          Column(children: [
            FilledButton.icon(
              onPressed: onEditMeeting,
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52)),
              icon: const Icon(Icons.location_on_outlined),
              label: Text(l.restChooseMeetingBtn),
            ),
            const SizedBox(height: 8),
            Text(
              l.restNextStepHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.55)),
            ),
          ])
        else if (!r.isCompleted && !_iConfirmed)
          FilledButton.icon(
            onPressed: busy ? null : onConfirm,
            style:
                FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            icon: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_circle_outline),
            label: Text(isOwner ? l.restIGotDoc : l.restIGaveDoc),
          )
        else if (!r.isCompleted && _iConfirmed)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Row(children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: cs.primary.withValues(alpha: 0.7)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  l.restWaitingOther,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ]),
          )
        else if (!_iRated) ...[
          // ── Étape 3 : évaluation ──
          Row(children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: cs.primary.withValues(alpha: 0.15),
              foregroundImage: (otherAvatar?.isNotEmpty ?? false)
                  ? CachedNetworkImageProvider(mediaUrl(otherAvatar))
                  : null,
              child: Text(
                (otherName?.trim().isNotEmpty ?? false)
                    ? otherName!.trim()[0].toUpperCase()
                    : '?',
                style: TextStyle(
                    color: cs.primary, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l.restRateQuestion(
                    (otherName?.trim().isNotEmpty ?? false)
                        ? otherName!.trim()
                        : l.restOtherParty),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          _RatingForm(onSubmit: onRate),
        ] else
          _Card(
            icon: Icons.star_rounded,
            title: l.restRatedTitle,
            subtitle: l.restRatedSub,
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}

/// Stepper horizontal de la restitution guidée.
class _Stepper extends StatelessWidget {
  final int current; // étape en cours (0–2), 3 = tout est terminé
  const _Stepper({required this.current});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    final labels = [l.restStepRdv, l.restStepHandover, l.restStepRating];
    return Column(
      children: [
        Row(
          children: [
            for (int i = 0; i < labels.length; i++) ...[
              _dot(cs, i),
              if (i < labels.length - 1)
                Expanded(
                  child: Container(
                    height: 3,
                    color: i < current
                        ? cs.primary
                        : cs.onSurface.withValues(alpha: 0.12),
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (int i = 0; i < labels.length; i++)
              Text(labels[i],
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          i == current ? FontWeight.w700 : FontWeight.w500,
                      color: i < current
                          ? cs.primary
                          : i == current
                              ? cs.onSurface
                              : cs.onSurface.withValues(alpha: 0.45))),
          ],
        ),
      ],
    );
  }

  Widget _dot(ColorScheme cs, int i) {
    final done = i < current;
    final active = i == current;
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done
            ? cs.primary
            : active
                ? cs.surface
                : cs.onSurface.withValues(alpha: 0.08),
        border: active ? Border.all(color: cs.primary, width: 2) : null,
      ),
      child: done
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : Text('${i + 1}',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: active
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.45))),
    );
  }
}

class _Card extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  const _Card({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: cs.onSurface.withValues(alpha: 0.65))),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Formulaire d'évaluation : 1-5 étoiles + commentaire optionnel (140 max).
class _RatingForm extends StatefulWidget {
  final void Function(int stars, String comment) onSubmit;
  const _RatingForm({required this.onSubmit});
  @override
  State<_RatingForm> createState() => _RatingFormState();
}

class _RatingFormState extends State<_RatingForm> {
  int _value = 0;
  final _commentCtrl = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(5, (i) {
            final filled = i < _value;
            return IconButton(
              onPressed: _sent
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      setState(() => _value = i + 1);
                    },
              icon: Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: filled
                      ? Colors.amber
                      : cs.onSurface.withValues(alpha: 0.4),
                  size: 34),
            );
          }),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _commentCtrl,
          maxLength: 140,
          maxLines: 2,
          enabled: !_sent,
          decoration: InputDecoration(
            labelText: l.restCommentLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: (_value == 0 || _sent)
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    setState(() => _sent = true);
                    widget.onSubmit(_value, _commentCtrl.text.trim());
                  },
            child: Text(l.restSendRating),
          ),
        ),
      ],
    );
  }
}

/// Overlay confettis de succès — sans dépendance externe (CustomPainter).
class _ConfettiOverlay extends StatefulWidget {
  final double? reputation;
  final VoidCallback onDone;
  const _ConfettiOverlay({required this.reputation, required this.onDone});

  @override
  State<_ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<_ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..forward();
  late final List<_ConfettiParticle> _particles;

  @override
  void initState() {
    super.initState();
    final rng = math.Random();
    _particles = List.generate(80, (_) => _ConfettiParticle.random(rng));
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Stack(children: [
        // Voile léger + confettis
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _ConfettiPainter(_particles, _ctrl.value),
            ),
          ),
        ),
        // Message central de succès
        if (_ctrl.value < 0.85)
          Center(
            child: Opacity(
              opacity: (_ctrl.value < 0.7
                      ? 1.0
                      : 1.0 - (_ctrl.value - 0.7) / 0.15)
                  .clamp(0.0, 1.0),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('🎉', style: TextStyle(fontSize: 44)),
                  const SizedBox(height: 8),
                  Text(l.restConfettiTitle,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800)),
                  if (widget.reputation != null) ...[
                    const SizedBox(height: 8),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.star_rounded,
                          size: 18, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                          l.restReputation(
                              widget.reputation!.toStringAsFixed(1)),
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface.withValues(alpha: 0.7))),
                    ]),
                  ],
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}

class _ConfettiParticle {
  final double x; // position horizontale relative (0-1)
  final double speed; // vitesse de chute
  final double size;
  final double phase; // déphasage de l'oscillation
  final Color color;

  _ConfettiParticle(this.x, this.speed, this.size, this.phase, this.color);

  factory _ConfettiParticle.random(math.Random rng) {
    const palette = [
      Color(0xFF01696F),
      Color(0xFF4FCFD6),
      Colors.amber,
      Colors.orange,
      Color(0xFF01565B),
      Colors.pinkAccent,
    ];
    return _ConfettiParticle(
      rng.nextDouble(),
      0.5 + rng.nextDouble() * 0.8,
      4 + rng.nextDouble() * 6,
      rng.nextDouble() * math.pi * 2,
      palette[rng.nextInt(palette.length)],
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double t; // progression 0-1

  _ConfettiPainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in particles) {
      final y = (t * p.speed * 1.4 - 0.1) * size.height;
      if (y < 0 || y > size.height) continue;
      final x = p.x * size.width +
          math.sin(t * 10 + p.phase) * 18; // oscillation latérale
      paint.color = p.color.withValues(alpha: (1.0 - t * 0.6).clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * 6 + p.phase);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.6),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

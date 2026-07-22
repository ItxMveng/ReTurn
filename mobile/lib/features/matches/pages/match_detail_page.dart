import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/media_url.dart';
import '../../profile/providers/profile_provider.dart';
import '../../restitution/repositories/restitution_repository.dart';
import '../../verification/repositories/verification_repository.dart';
import '../providers/matches_provider.dart';
import '../repositories/matches_repository.dart';

const _docLabels = <String, String>{
  'cni': "Carte Nationale d'Identité",
  'passport': 'Passeport',
  'driving_license': 'Permis de conduire',
  'vehicle_registration': 'Carte grise',
  'birth_certificate': 'Acte de naissance',
  'student_card': 'Carte étudiante',
  'bank_card': 'Carte bancaire',
  'diploma': 'Diplôme',
  'other': 'Autre document',
};

/// Statut de la vérification d'identité du PROPRIÉTAIRE pour ce match —
/// le backend renvoie la même chose aux deux participants : le trouveur
/// s'en sert pour savoir quand la conversation se débloque.
final _verificationStatusProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, matchId) async {
  try {
    return await ref.read(verificationRepositoryProvider).status(matchId);
  } catch (_) {
    return null;
  }
});

/// Masque partiellement un nom tant que l'identité n'est pas vérifiée
/// (anti-scraping) : « Jean Mbarga » → « Jean M••••• ».
String _maskName(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  return parts.map((p) {
    if (p.length <= 1) return p;
    return parts.indexOf(p) == 0 ? p : '${p[0]}${'•' * (p.length - 1).clamp(1, 6)}';
  }).join(' ');
}

class MatchDetailPage extends ConsumerWidget {
  final String id;
  const MatchDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(matchDetailProvider(id));
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Correspondance')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.wifi_off,
                  size: 40, color: cs.onSurface.withValues(alpha: 0.3)),
              const SizedBox(height: 12),
              const Text('Impossible de charger la correspondance'),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.invalidate(matchDetailProvider(id)),
                child: const Text('Réessayer'),
              ),
            ]),
          ),
        ),
        data: (m) {
          final docLabel = _docLabels[m.documentType] ?? m.documentType;
          final myId = ref.watch(profileProvider).valueOrNull?.id ?? '';
          // Rôles : le PROPRIÉTAIRE (a perdu) vérifie son identité ; le
          // TROUVEUR attend simplement cette vérification.
          final isOwner = m.isOwner(myId);

          // ── Vérification d'identité du propriétaire (pivot du flux) ──
          final verifAsync = ref.watch(_verificationStatusProvider(m.id));
          final verif = verifAsync.valueOrNull;
          final verifStatus = verif?['status'] as String?;
          final verified = verifStatus == 'approved';
          final verifRejected = verifStatus == 'rejected';
          // Dossier complet soumis, en attente de revue admin (niveau 3).
          final verifInReview = verifStatus == 'pending' &&
              verif?['questions_passed'] == true &&
              ((verif?['selfie_url'] as String?)?.isNotEmpty ?? false);

          final restitAsync = ref.watch(restitutionByMatchProvider(m.id));
          final restituted = restitAsync.valueOrNull?.isCompleted ?? false;

          // Code couleur : vert ≥ 70 %, orange 55–69 %, rouge < 55 %.
          final score = m.score.clamp(0.0, 1.0);
          final scoreColor = score >= 0.70
              ? cs.primary
              : score >= 0.55
                  ? Colors.orange
                  : cs.error;
          final scoreLabel = score >= 0.70
              ? 'Correspondance forte'
              : score >= 0.55
                  ? 'Correspondance probable'
                  : 'Correspondance faible';

          // Identité de l'autre partie : cachée tant que le propriétaire
          // n'a pas vérifié son identité (anti-scraping). Le vrai nom n'est
          // révélé que dans les bandeaux « vérifié » ci-dessous.
          final rawOtherName = (m.otherUserName?.trim().isNotEmpty ?? false)
              ? m.otherUserName!.trim()
              : 'Utilisateur';

          Future<void> openVerification() async {
            HapticFeedback.lightImpact();
            await context.push('/verify/${m.id}');
            // De retour : rafraîchit l'état (vérif possiblement approuvée).
            ref.invalidate(_verificationStatusProvider(m.id));
            ref.invalidate(matchDetailProvider(id));
            ref.invalidate(matchesProvider);
          }

          void openConversation() {
            HapticFeedback.lightImpact();
            context.go('/messages/${m.id}',
                extra: (rawOtherName, m.otherUserAvatar));
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // ── Stepper de progression ────────────────────────────────
              _ProgressStepper(
                currentStep: restituted
                    ? 2
                    : verified
                        ? 1
                        : 0,
                done: restituted,
              ),
              const SizedBox(height: 24),

              // ── Photos du document (informations sensibles masquées) ──
              if (m.foundPhotoUrls.isNotEmpty) ...[
                _MaskedPhotos(
                    urls: m.foundPhotoUrls, revealed: verified),
                const SizedBox(height: 20),
              ],

              // ── Anneau de score ───────────────────────────────────────
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: score,
                        strokeWidth: 10,
                        strokeCap: StrokeCap.round,
                        backgroundColor:
                            scoreColor.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation(scoreColor),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${m.scorePercent}%',
                            style: const TextStyle(
                                fontSize: 28, fontWeight: FontWeight.w900)),
                        Text('confiance',
                            style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurface.withValues(alpha: 0.5))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(scoreLabel,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: scoreColor)),
              ),
              const SizedBox(height: 12),

              // ── Explication du score ──────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.insights_outlined,
                        size: 18, color: cs.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Score basé sur : le nom sur le document (fort), '
                        'le numéro du document (fort), la localisation '
                        '(moyen) et la cohérence des dates.',
                        style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: cs.onSurface.withValues(alpha: 0.65)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Détails du document ───────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Column(children: [
                  _row(cs, Icons.badge_outlined, 'Document', docLabel),
                  if (m.ownerName != null && m.ownerName!.isNotEmpty) ...[
                    Divider(height: 1, color: cs.outlineVariant, indent: 52),
                    _row(cs, Icons.person_outline, 'Nom sur le document',
                        verified ? m.ownerName! : _maskName(m.ownerName!)),
                  ],
                  if (m.location != null && m.location!.isNotEmpty) ...[
                    Divider(height: 1, color: cs.outlineVariant, indent: 52),
                    _row(cs, Icons.location_on_outlined, 'Lieu', m.location!),
                  ],
                  Divider(height: 1, color: cs.outlineVariant, indent: 52),
                  _row(cs, Icons.flag_outlined, 'Statut',
                      _statusLabel(m.status, verified: verified)),
                  if (m.createdAt != null) ...[
                    Divider(height: 1, color: cs.outlineVariant, indent: 52),
                    _row(cs, Icons.event_outlined, 'Détecté le',
                        '${m.createdAt!.day}/${m.createdAt!.month}/${m.createdAt!.year}'),
                  ],
                ]),
              ),
              const SizedBox(height: 24),

              // ══ Actions selon le rôle ══════════════════════════════════
              if (isOwner) ...[
                // ── PROPRIÉTAIRE ──
                if (verified) ...[
                  _StatusBanner(
                    icon: Icons.verified_rounded,
                    color: cs.primary,
                    text:
                        'Identité vérifiée ✓ — vous pouvez discuter avec $rawOtherName '
                        'pour organiser la récupération.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: openConversation,
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Ouvrir la conversation'),
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52)),
                  ),
                ] else if (verifInReview) ...[
                  const _StatusBanner(
                    icon: Icons.hourglass_top_rounded,
                    color: Colors.orange,
                    text:
                        'Votre dossier de vérification est en cours de validation '
                        'par notre équipe (sous 24 h). Vous serez notifié.',
                  ),
                ] else if (verifRejected) ...[
                  _StatusBanner(
                    icon: Icons.gpp_bad_outlined,
                    color: cs.error,
                    text: (verif?['rejection_reason'] as String?)
                                ?.isNotEmpty ==
                            true
                        ? 'Vérification refusée : ${verif!['rejection_reason']}. Vous pouvez réessayer.'
                        : 'Vérification refusée. Vous pouvez réessayer.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: openVerification,
                    icon: const Icon(Icons.verified_user_outlined),
                    label: const Text('Réessayer la vérification'),
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52)),
                  ),
                ] else ...[
                  _StatusBanner(
                    icon: Icons.shield_outlined,
                    color: cs.primary,
                    text:
                        'Ce document semble être le vôtre. Vérifiez votre identité '
                        'pour débloquer la conversation avec la personne qui l\'a trouvé.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: openVerification,
                    icon: const Icon(Icons.verified_user_outlined),
                    label: const Text('Vérifier mon identité'),
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52)),
                  ),
                  const SizedBox(height: 8),
                  // Refus volontairement discret sous le CTA principal.
                  Center(
                    child: TextButton(
                      onPressed: () async {
                        await ref
                            .read(matchesRepositoryProvider)
                            .rejectMatch(m.id);
                        ref.invalidate(matchesProvider);
                        if (context.mounted) context.pop();
                      },
                      child: Text('Ce n\'est pas mon document',
                          style: TextStyle(
                              color:
                                  cs.onSurface.withValues(alpha: 0.55))),
                    ),
                  ),
                ],
              ] else ...[
                // ── TROUVEUR : aucune vérification demandée, ce n'est pas
                //    son document. Il attend celle du propriétaire. ──
                if (verified) ...[
                  _StatusBanner(
                    icon: Icons.verified_rounded,
                    color: cs.primary,
                    text:
                        '$rawOtherName a vérifié son identité ✓ — vous pouvez '
                        'discuter pour organiser la remise du document.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: openConversation,
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Ouvrir la conversation'),
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52)),
                  ),
                ] else ...[
                  const _StatusBanner(
                    icon: Icons.hourglass_top_rounded,
                    color: Colors.orange,
                    text:
                        'Un propriétaire potentiel a été trouvé. En attente de '
                        'la vérification de son identité — vous serez notifié '
                        'dès qu\'elle est faite.',
                  ),
                ],
              ],
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  String _statusLabel(String s, {required bool verified}) => switch (s) {
        'pending' => 'En attente de vérification',
        'confirmed' => verified ? 'Identité vérifiée' : 'Confirmé',
        'ignored' => 'Ignoré',
        'closed' => 'Clôturé',
        _ => s,
      };

  Widget _row(ColorScheme cs, IconData icon, String label, String value) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: cs.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.5))),
                  const SizedBox(height: 2),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      );
}

/// Bandeau d'état coloré (info / attente / succès / refus).
class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _StatusBanner(
      {required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ),
      ]),
    );
  }
}

/// Photos du document avec FLOU de protection : reconnaissables (forme,
/// couleurs) mais les informations sensibles (numéros, textes) illisibles.
/// Le flou est levé une fois l'identité du propriétaire vérifiée.
class _MaskedPhotos extends StatelessWidget {
  final List<String> urls;
  final bool revealed;
  const _MaskedPhotos({required this.urls, required this.revealed});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.photo_library_outlined, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          const Text('Photos du document',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 10),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: urls.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(children: [
                ImageFiltered(
                  imageFilter: revealed
                      ? ImageFilter.blur(sigmaX: 0, sigmaY: 0)
                      : ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                  child: Image.network(
                    mediaUrl(urls[i]),
                    height: 150,
                    width: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 150,
                      width: 220,
                      color: cs.primary.withValues(alpha: 0.08),
                      child: Icon(Icons.broken_image_outlined,
                          color: cs.onSurface.withValues(alpha: 0.3)),
                    ),
                  ),
                ),
                if (!revealed)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_outline,
                                size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Données protégées',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                          ]),
                    ),
                  ),
              ]),
            ),
          ),
        ),
      ],
    );
  }
}

/// Stepper horizontal de progression : Découvert → Vérifié → Restitué.
class _ProgressStepper extends StatelessWidget {
  final int currentStep; // index de l'étape EN COURS (0-2)
  final bool done; // true si tout le parcours est terminé
  const _ProgressStepper({required this.currentStep, required this.done});

  static const _labels = ['Découvert', 'Vérifié', 'Restitué'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: List.generate(_labels.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connecteur entre deux étapes.
          final leftStep = i ~/ 2;
          final active = done || leftStep < currentStep;
          return Expanded(
            child: Container(
              height: 2.5,
              margin: const EdgeInsets.only(bottom: 20),
              color: active
                  ? cs.primary
                  : cs.onSurface.withValues(alpha: 0.12),
            ),
          );
        }
        final step = i ~/ 2;
        final completed = done || step < currentStep;
        final current = !done && step == currentStep;
        final color = completed || current
            ? cs.primary
            : cs.onSurface.withValues(alpha: 0.3);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: completed
                    ? cs.primary
                    : current
                        ? cs.primary.withValues(alpha: 0.15)
                        : cs.onSurface.withValues(alpha: 0.06),
                border: Border.all(
                  color: completed || current
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
              child: completed
                  ? const Icon(Icons.check, size: 15, color: Colors.white)
                  : Center(
                      child: Text('${step + 1}',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: color)),
                    ),
            ),
            const SizedBox(height: 4),
            Text(_labels[step],
                style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        current ? FontWeight.w800 : FontWeight.w600,
                    color: color)),
          ],
        );
      }),
    );
  }
}

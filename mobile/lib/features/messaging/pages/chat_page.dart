import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/media_url.dart';
import '../../matches/providers/matches_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../models/message.dart';
import '../repositories/messaging_repository.dart';
import '../utils/chat_format.dart';

/// Détection d'un numéro de téléphone dans le texte saisi (anti-bypass) :
/// suite de 9 chiffres ou plus, avec espaces/points/tirets tolérés.
final _phoneLikeRe = RegExp(r'(?:\+?\d[\s\.\-]?){9,}');

// L'identité « moi » vient du profil → alignement correct des bulles.
final _historyProvider =
    FutureProvider.family<List<ChatMessage>, String>((ref, roomId) async {
  final myId = ref.watch(profileProvider).valueOrNull?.id ?? '';
  return ref.read(messagingRepositoryProvider).history(roomId, myId);
});

bool _sameDay(DateTime a, DateTime b) {
  final la = a.toLocal();
  final lb = b.toLocal();
  return la.year == lb.year && la.month == lb.month && la.day == lb.day;
}

const _months = [
  'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
  'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
];

const _reportReasons = <String, String>{
  'fraud': 'Tentative d\'escroquerie',
  'harassment': 'Harcèlement / insultes',
  'fake_document': 'Document falsifié',
  'identity_theft': 'Usurpation d\'identité',
  'inappropriate': 'Contenu inapproprié',
  'other': 'Autre',
};

class ChatPage extends ConsumerStatefulWidget {
  final String roomId;
  final String? otherName;
  final String? otherAvatar;
  const ChatPage({
    super.key,
    required this.roomId,
    this.otherName,
    this.otherAvatar,
  });

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _ctr = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;
  bool _phoneWarning = false;

  @override
  void initState() {
    super.initState();
    // Avertissement discret si l'utilisateur tape un numéro de téléphone.
    _ctr.addListener(() {
      final hasPhone = _phoneLikeRe.hasMatch(_ctr.text);
      if (hasPhone != _phoneWarning) {
        setState(() => _phoneWarning = hasPhone);
      }
    });
  }

  @override
  void dispose() {
    _ctr.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctr.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref.read(messagingRepositoryProvider).send(widget.roomId, text);
      _ctr.clear();
      ref.invalidate(_historyProvider(widget.roomId));
      await Future.delayed(const Duration(milliseconds: 300));
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec de l\'envoi, réessayez.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _report() async {
    String reason = 'fraud';
    final descCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Signaler cet utilisateur'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: reason,
                decoration: const InputDecoration(labelText: 'Motif'),
                items: _reportReasons.entries
                    .map((e) =>
                        DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setLocal(() => reason = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Détails (optionnel)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Envoyer')),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(messagingRepositoryProvider).report(
            widget.roomId,
            reason,
            description: descCtrl.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signalement envoyé. Merci.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec du signalement.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_historyProvider(widget.roomId));
    final cs = Theme.of(context).colorScheme;
    final title = (widget.otherName?.trim().isNotEmpty ?? false)
        ? widget.otherName!.trim()
        : 'Conversation';
    // Un match ignoré/clôturé ferme la conversation (saisie désactivée).
    final matchStatus =
        ref.watch(matchDetailProvider(widget.roomId)).valueOrNull?.status;
    final closed = matchStatus == 'ignored' || matchStatus == 'closed';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: cs.primary.withValues(alpha: 0.15),
              foregroundImage: (widget.otherAvatar?.isNotEmpty ?? false)
                  ? NetworkImage(mediaUrl(widget.otherAvatar))
                  : null,
              child: Text(
                title.isNotEmpty ? title[0].toUpperCase() : '?',
                style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis),
                  Text('Restitution sécurisée',
                      style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withValues(alpha: 0.5))),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Pas de « Vérifier l'identité » ici : arriver dans le chat
          // signifie que la vérification du propriétaire est déjà faite.
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'report') _report();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'report',
                child: Row(children: [
                  Icon(Icons.flag_outlined, size: 18, color: Colors.red),
                  SizedBox(width: 10),
                  Text('Signaler'),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: Column(children: [
        // Bandeau sécurité (F-31 : pas d'échange de numéro avant validation)
        Container(
          width: double.infinity,
          color: cs.primary.withValues(alpha: 0.08),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            Icon(Icons.shield_outlined, size: 15, color: cs.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ne partagez pas d\'informations sensibles. Convenez d\'un '
                'lieu public ou certifié pour la restitution.',
                style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withValues(alpha: 0.6)),
              ),
            ),
          ]),
        ),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_off,
                        color: cs.onSurface.withValues(alpha: 0.3), size: 40),
                    const SizedBox(height: 12),
                    const Text('Impossible de charger la conversation'),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () =>
                          ref.invalidate(_historyProvider(widget.roomId)),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            ),
            data: (msgs) => msgs.isEmpty
                ? Center(
                    child: Text('Démarrez la conversation',
                        style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.4))))
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: msgs.length,
                    itemBuilder: (_, i) {
                      final msg = msgs[i];
                      // Séparateur de date quand le jour change.
                      final showDate = i == 0 ||
                          !_sameDay(msgs[i - 1].createdAt, msg.createdAt);
                      // Regroupement : marge serrée entre messages consécutifs
                      // du même expéditeur ; heure sur le dernier du groupe.
                      final isLastOfGroup = i == msgs.length - 1 ||
                          msgs[i + 1].isMe != msg.isMe ||
                          msgs[i + 1]
                                  .createdAt
                                  .difference(msg.createdAt)
                                  .inMinutes >
                              3;
                      final grouped = !showDate &&
                          i > 0 &&
                          msgs[i - 1].isMe == msg.isMe &&
                          msg.createdAt
                                  .difference(msgs[i - 1].createdAt)
                                  .inMinutes <=
                              3;
                      return Column(children: [
                        if (showDate) _DateChip(date: msg.createdAt),
                        _Bubble(
                            msg: msg,
                            showTime: isLastOfGroup,
                            grouped: grouped),
                      ]);
                    },
                  ),
          ),
        ),
        if (closed)
          // Bandeau « conversation fermée » — remplace la zone de saisie.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.05),
              border: Border(
                  top: BorderSide(
                      color: cs.onSurface.withValues(alpha: 0.08))),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline,
                      size: 16, color: cs.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 8),
                  Text('La conversation est fermée',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withValues(alpha: 0.55))),
                ],
              ),
            ),
          )
        else ...[
          if (_phoneWarning)
            // Anti-bypass : rappel discret avant de partager un numéro.
            Container(
              width: double.infinity,
              color: Colors.orange.withValues(alpha: 0.1),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(children: [
                const Icon(Icons.info_outline,
                    size: 14, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Évitez de partager votre numéro : la remise se fait '
                    'en lieu public via l\'application.',
                    style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.65)),
                  ),
                ),
              ]),
            ),
          _InputBar(
            ctr: _ctr,
            sending: _sending,
            onSend: _send,
            onRestitution: () =>
                context.push('/restitution/${widget.roomId}'),
          ),
        ],
      ]),
    );
  }
}

/// Séparateur de date centré ("Aujourd'hui", "Hier" ou date complète).
class _DateChip extends StatelessWidget {
  final DateTime date;
  const _DateChip({required this.date});

  String _label() {
    final now = DateTime.now();
    final d = date.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    if (day == today) return 'Aujourd\'hui';
    if (day == today.subtract(const Duration(days: 1))) return 'Hier';
    return '${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(_label(),
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withValues(alpha: 0.55))),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage msg;
  final bool showTime;
  final bool grouped;
  const _Bubble(
      {required this.msg, this.showTime = true, this.grouped = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLoc = isLocationMessage(msg.content);
    final time = DateFormat('HH:mm').format(msg.createdAt.toLocal());

    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(top: grouped ? 2 : 8),
        padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.74),
        decoration: BoxDecoration(
          color: msg.isMe ? cs.primary : Theme.of(context).cardColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(grouped && !msg.isMe ? 6 : 18),
            topRight: Radius.circular(grouped && msg.isMe ? 6 : 18),
            bottomLeft: Radius.circular(msg.isMe ? 18 : 6),
            bottomRight: Radius.circular(msg.isMe ? 6 : 18),
          ),
          border: msg.isMe
              ? null
              : Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: isLoc
                  ? Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.location_on,
                          size: 16,
                          color: msg.isMe ? Colors.white : cs.primary),
                      const SizedBox(width: 6),
                      Text('Position partagée',
                          style: TextStyle(
                              color:
                                  msg.isMe ? Colors.white : cs.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                    ])
                  : Text(msg.content,
                      style: TextStyle(
                          color: msg.isMe ? Colors.white : cs.onSurface,
                          fontSize: 14.5,
                          height: 1.35)),
            ),
            if (showTime) ...[
              const SizedBox(height: 3),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Text(time,
                    style: TextStyle(
                        fontSize: 10,
                        color: (msg.isMe ? Colors.white : cs.onSurface)
                            .withValues(alpha: 0.55))),
                if (msg.isMe) ...[
                  const SizedBox(width: 3),
                  // Double-check : gris = envoyé, vert clair = lu.
                  Icon(Icons.done_all,
                      size: 13,
                      color: msg.isRead
                          ? const Color(0xFF7CF5A0)
                          : Colors.white.withValues(alpha: 0.55)),
                ],
              ]),
            ],
          ],
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController ctr;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onRestitution;
  const _InputBar({
    required this.ctr,
    required this.sending,
    required this.onSend,
    required this.onRestitution,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border:
            Border(top: BorderSide(color: cs.onSurface.withValues(alpha: 0.08))),
      ),
      child: SafeArea(
        top: false,
        child: Row(children: [
          // Organiser la restitution — à la place habituelle des emojis.
          IconButton(
            tooltip: 'Organiser la restitution',
            onPressed: onRestitution,
            icon: Icon(Icons.handshake_outlined, color: cs.primary),
          ),
          Expanded(
            child: TextField(
              controller: ctr,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Votre message…',
                hintStyle:
                    TextStyle(color: cs.onSurface.withValues(alpha: 0.4)),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none),
                filled: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          sending
              ? const SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                      child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2))))
              : IconButton.filled(
                  onPressed: onSend,
                  icon: const Icon(Icons.send_rounded),
                  style: IconButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: Colors.white),
                ),
        ]),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:docretour/core/services/notification_service.dart';
import 'package:docretour/core/theme/app_theme.dart';
import 'package:docretour/features/auth/presentation/providers/auth_provider.dart';
import 'package:docretour/features/messaging/providers/messaging_provider.dart';
import 'package:docretour/features/profile/providers/profile_provider.dart';
import 'package:docretour/l10n/app_localizations.dart';
import 'package:docretour/shared/models/message.dart';

final activeChatMatchIdProvider = StateProvider<String?>((ref) => null);

class ChatScreen extends ConsumerStatefulWidget {
  final String matchId;
  final String title;
  const ChatScreen(
      {super.key, required this.matchId, required this.title});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(activeChatMatchIdProvider.notifier).state =
          widget.matchId;
      NotificationService.setActiveChatMatchId(widget.matchId);
    });
  }

  @override
  void dispose() {
    ref.read(activeChatMatchIdProvider.notifier).state = null;
    NotificationService.setActiveChatMatchId(null);
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      ref
          .read(chatProvider(widget.matchId).notifier)
          .sendLocation(pos.latitude, pos.longitude);
    } catch (_) {}
  }

  /// Supprime la discussion après confirmation
  Future<void> _deleteConversation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer la discussion'),
        content: const Text(
            'Tous les messages seront supprimés. Cette action est irréversible.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await ref
        .read(chatProvider(widget.matchId).notifier)
        .deleteConversation();
    if (mounted) {
      if (ok) {
        Navigator.of(context).pop(); // retour à la liste
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Impossible de supprimer la discussion'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  /// Signale un utilisateur
  Future<void> _reportUser() async {
    final reasons = [
      'Comportement inapproprié',
      'Arnaque / tentative de fraude',
      'Fausses informations',
      'Harcèlement',
      'Autre',
    ];
    String? selectedReason;
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Signaler cet utilisateur'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Motif du signalement :',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ...reasons.map((r) => RadioListTile<String>(
                    title: Text(r, style: const TextStyle(fontSize: 14)),
                    value: r,
                    groupValue: selectedReason,
                    onChanged: (v) => setSt(() => selectedReason = v),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  )),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Précisions supplémentaires (optionnel)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(10),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler')),
            ElevatedButton(
              onPressed: selectedReason == null
                  ? null
                  : () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white),
              child: const Text('Signaler'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || selectedReason == null) return;

    final ok = await ref
        .read(chatProvider(widget.matchId).notifier)
        .reportUser(
          reason: selectedReason!,
          details: controller.text.trim(),
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? 'Signalement envoyé. Merci de nous avoir alertés.'
            : 'Erreur lors de l\'envoi du signalement'),
        backgroundColor: ok ? kGreen : Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final chatState = ref.watch(chatProvider(widget.matchId));

    final profile = ref.watch(profileProvider).valueOrNull;
    final myId = profile?.id.isNotEmpty == true
        ? profile!.id
        : ref.watch(authProvider).maybeWhen(
              authenticated: (_, __, userId) => userId,
              orElse: () => '',
            );

    final avatarUrl = profile?.avatarUrl;

    ref.listen(
        chatProvider(widget.matchId), (_, __) => _scrollToBottom());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.brightness == Brightness.light
            ? const Color(0xFF0D2B1F)
            : cs.surfaceContainerHighest,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            _Avatar(url: null, size: 36, isMe: false),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title,
                      style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis),
                  Row(children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: chatState.connected
                            ? kGreen
                            : cs.error,
                      ),
                    ),
                    Text(
                      chatState.connected
                          ? l.chatConnected
                          : l.chatDisconnected,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.white70),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (!chatState.connected)
            IconButton(
              icon:
                  const Icon(Icons.refresh, color: Colors.white),
              onPressed: () => ref
                  .read(chatProvider(widget.matchId).notifier)
                  .reconnect(),
            ),
          // Menu contextuel : supprimer + signaler
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (v) {
              if (v == 'delete') _deleteConversation();
              if (v == 'report') _reportUser();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined,
                        color: Colors.orange, size: 18),
                    SizedBox(width: 10),
                    Text('Signaler'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline,
                        color: Colors.red, size: 18),
                    SizedBox(width: 10),
                    Text('Supprimer la discussion',
                        style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (chatState.error != null)
            Container(
              color: cs.error.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      color: cs.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(chatState.error!,
                          style: TextStyle(
                              color: cs.error, fontSize: 13))),
                  TextButton(
                    onPressed: () => ref
                        .read(chatProvider(widget.matchId)
                            .notifier)
                        .reconnect(),
                    child: const Text('Reconnecter'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: chatState.messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 48,
                            color: cs.onSurface
                                .withValues(alpha: 0.2)),
                        const SizedBox(height: 12),
                        Text('Démarrez la conversation',
                            style: TextStyle(
                                color: cs.onSurface
                                    .withValues(alpha: 0.4),
                                fontSize: 14)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding:
                        const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    itemCount: chatState.messages.length,
                    itemBuilder: (_, i) {
                      final msg = chatState.messages[i];
                      final isMe = msg.senderId == myId;
                      final showDate = i == 0 ||
                          !_sameDay(
                              chatState.messages[i - 1].createdAt,
                              msg.createdAt);
                      return Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                        children: [
                          if (showDate)
                            _DateSeparator(msg.createdAt),
                          _MessageBubble(
                            message: msg,
                            isMe: isMe,
                            myAvatarUrl: avatarUrl,
                          ),
                        ],
                      );
                    },
                  ),
          ),
          _InputBar(
            controller: _inputCtrl,
            placeholder: l.chatPlaceholder,
            locationTooltip: l.chatSendLocation,
            onSend: () {
              final text = _inputCtrl.text.trim();
              if (text.isEmpty) return;
              ref
                  .read(chatProvider(widget.matchId).notifier)
                  .send(text);
              _inputCtrl.clear();
            },
            onLocation: _sendLocation,
          ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year &&
      a.month == b.month &&
      a.day == b.day;
}

// ── Avatar ────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String? url;
  final double size;
  final bool isMe;
  const _Avatar(
      {required this.url,
      required this.size,
      required this.isMe});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (url != null && url!.isNotEmpty) {
      return ClipOval(
        child: Image.network(url!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholder(cs)),
      );
    }
    return _placeholder(cs);
  }

  Widget _placeholder(ColorScheme cs) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isMe
              ? kGreen.withValues(alpha: 0.2)
              : cs.surfaceContainerHighest,
          shape: BoxShape.circle,
          border: Border.all(
              color: isMe ? kGreen : cs.outline, width: 1.5),
        ),
        child: Icon(Icons.person,
            size: size * 0.5,
            color: isMe
                ? kGreen
                : cs.onSurface.withValues(alpha: 0.5)),
      );
}

// ── Date separator ────────────────────────────────────────────────────────────

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator(this.date);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    String label;
    if (d == today) {
      label = "Aujourd'hui";
    } else if (d == today.subtract(const Duration(days: 1))) {
      label = 'Hier';
    } else {
      label = DateFormat('dd MMM yyyy', 'fr').format(date);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: cs.outline)),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color:
                        cs.onSurface.withValues(alpha: 0.4),
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Divider(color: cs.outline)),
        ],
      ),
    );
  }
}

// ── Message bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final String? myAvatarUrl;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    this.myAvatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // ── Message système (centré) ─────────────────────────────
    if (message.isSystem) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(message.content,
                style: TextStyle(
                    fontSize: 12,
                    color:
                        cs.onSurface.withValues(alpha: 0.6))),
          ),
        ),
      );
    }

    // ── Contenu de la bulle ──────────────────────────────────
    Widget content;
    if (message.isLocation) {
      final parts = message.content.split(',');
      final latStr = parts.isNotEmpty ? parts[0].trim() : '';
      final lngStr =
          parts.length > 1 ? parts[1].trim() : '';
      final lat = double.tryParse(latStr);
      final lng = double.tryParse(lngStr);
      content = GestureDetector(
        onTap: lat != null && lng != null
            ? () async {
                final uri = Uri.parse(
                    'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                if (await canLaunchUrl(uri)) launchUrl(uri);
              }
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isMe
                ? Colors.white.withValues(alpha: 0.15)
                : kGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: isMe
                    ? Colors.white.withValues(alpha: 0.3)
                    : kGreen.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on,
                  color: isMe ? Colors.white : kGreen,
                  size: 20),
              const SizedBox(width: 6),
              Flexible(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text('Zone de récupération',
                        style: TextStyle(
                            color: isMe
                                ? Colors.white
                                : kGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                    if (lat != null)
                      Text(
                        '${lat.toStringAsFixed(5)}, ${lng?.toStringAsFixed(5)}',
                        style: TextStyle(
                            color: isMe
                                ? Colors.white
                                    .withValues(alpha: 0.8)
                                : cs.onSurface
                                    .withValues(alpha: 0.6),
                            fontSize: 11),
                      ),
                    Text('Appuyer pour ouvrir Maps',
                        style: TextStyle(
                            color: isMe
                                ? Colors.white
                                    .withValues(alpha: 0.6)
                                : kGreen.withValues(
                                    alpha: 0.7),
                            fontSize: 10,
                            fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      content = Text(
        message.content,
        style: TextStyle(
          // Émetteur → texte blanc (bulle verte)
          // Receveur → texte normal (bulle claire)
          color: isMe ? Colors.white : cs.onSurface,
          fontSize: 14,
          height: 1.4,
        ),
      );
    }

    // ── Alignement : émetteur droite, receveur gauche ────────
    // Cette règle s'applique symétriquement :
    // • Chez l'émetteur : SES messages = droite, l'autre = gauche
    // • Chez le receveur : SES messages = droite, l'autre = gauche
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar gauche (interlocuteur)
          if (!isMe) ...[
            _Avatar(
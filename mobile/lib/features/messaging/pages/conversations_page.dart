import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/media_url.dart';
import '../../../core/widgets/appear.dart';
import '../../../core/widgets/state_views.dart';
import '../repositories/messaging_repository.dart';
import '../models/message.dart';
import '../utils/chat_format.dart';

final _conversationsProvider =
    FutureProvider<List<Conversation>>((ref) async {
  return ref.read(messagingRepositoryProvider).conversations();
});

class ConversationsPage extends ConsumerStatefulWidget {
  const ConversationsPage({super.key});

  @override
  ConsumerState<ConversationsPage> createState() =>
      _ConversationsPageState();
}

class _ConversationsPageState extends ConsumerState<ConversationsPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_conversationsProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorView(
            error: e, onRetry: () => ref.invalidate(_conversationsProvider)),
        data: (convs) {
          final filtered = _query.trim().isEmpty
              ? convs
              : convs
                  .where((c) => c.otherUserName
                      .toLowerCase()
                      .contains(_query.trim().toLowerCase()))
                  .toList();
          return Column(
            children: [
              if (convs.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Rechercher une conversation',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat_bubble_outline,
                                  size: 64,
                                  color: cs.onSurface
                                      .withValues(alpha: 0.2)),
                              const SizedBox(height: 16),
                              Text(
                                  convs.isEmpty
                                      ? 'Aucune conversation'
                                      : 'Aucun résultat',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              if (convs.isEmpty) ...[
                                Text(
                                    'Les conversations s\'ouvrent\naprès confirmation d\'un match',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: cs.onSurface
                                            .withValues(alpha: 0.5))),
                                const SizedBox(height: 20),
                                FilledButton.icon(
                                  onPressed: () => context.go('/matches'),
                                  icon: const Icon(Icons.compare_arrows),
                                  label: const Text('Voir mes matchs'),
                                ),
                              ],
                            ]),
                      )
                    : RefreshIndicator(
                        onRefresh: () async =>
                            ref.invalidate(_conversationsProvider),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) => Appear(
                              delay: Duration(
                                  milliseconds: (i * 40).clamp(0, 360)),
                              child: _ConvTile(
                                conv: filtered[i],
                                onTap: () => context.go(
                                  '/messages/${filtered[i].roomId}',
                                  extra: (
                                    filtered[i].otherUserName,
                                    filtered[i].otherUserAvatar
                                  ),
                                ),
                              )),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ConvTile extends StatelessWidget {
  final Conversation conv;
  final VoidCallback onTap;
  const _ConvTile({required this.conv, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
        ),
        child: Row(children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: cs.primary.withValues(alpha: 0.12),
            foregroundImage: (conv.otherUserAvatar?.isNotEmpty ?? false)
                ? NetworkImage(mediaUrl(conv.otherUserAvatar))
                : null,
            child: Text(
                conv.otherUserName.isNotEmpty
                    ? conv.otherUserName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                    color: cs.primary, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(conv.otherUserName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                if (conv.lastMessage != null) ...[
                  const SizedBox(height: 2),
                  Text(displayMessage(conv.lastMessage!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.55),
                          fontSize: 13)),
                ],
              ],
            ),
          ),
          if (conv.unread > 0) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 10,
              backgroundColor: cs.primary,
              child: Text('${conv.unread}',
                  style:
                      const TextStyle(fontSize: 10, color: Colors.white)),
            ),
          ],
        ]),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../repositories/messaging_repository.dart';
import '../models/message.dart';

final _conversationsProvider =
    FutureProvider<List<Conversation>>((ref) async {
  return ref.read(messagingRepositoryProvider).conversations();
});

class ConversationsPage extends ConsumerWidget {
  const ConversationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_conversationsProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (convs) => convs.isEmpty
            ? Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 64,
                      color: cs.onSurface.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  const Text('Aucune conversation',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(
                      'Les conversations s\'ouvrent\naprès confirmation d\'un match',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withOpacity(0.5))),
                ]),
              )
            : ListView.separated(
                itemCount: convs.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 72),
                itemBuilder: (_, i) => _ConvTile(
                    conv: convs[i],
                    onTap: () =>
                        context.go('/messages/${convs[i].roomId}')),
              ),
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
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: cs.primary.withOpacity(0.12),
        child: Text(
            conv.otherUserName.isNotEmpty
                ? conv.otherUserName[0].toUpperCase()
                : '?',
            style: TextStyle(
                color: cs.primary, fontWeight: FontWeight.w700)),
      ),
      title: Text(conv.otherUserName,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: conv.lastMessage != null
          ? Text(conv.lastMessage!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: cs.onSurface.withOpacity(0.55), fontSize: 13))
          : null,
      trailing: conv.unread > 0
          ? CircleAvatar(
              radius: 10,
              backgroundColor: cs.primary,
              child: Text('${conv.unread}',
                  style: const TextStyle(
                      fontSize: 10, color: Colors.white)),
            )
          : null,
    );
  }
}

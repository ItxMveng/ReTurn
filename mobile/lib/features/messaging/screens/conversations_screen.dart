import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/models/message_model.dart';
import '../data/repositories/messaging_repository.dart';

part 'conversations_screen.g.dart';

@riverpod
Future<List<ConversationModel>> conversations(Ref ref) {
  return ref.read(messagingRepositoryProvider).listConversations();
}

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(conversationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (convs) => convs.isEmpty
            ? const Center(
                child: Text('Aucune conversation',
                    style: TextStyle(color: Colors.grey)))
            : ListView.builder(
                itemCount: convs.length,
                itemBuilder: (ctx, i) {
                  final conv = convs[i];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        conv.otherUserName?.substring(0, 1).toUpperCase() ??
                            '?',
                      ),
                    ),
                    title: Text(conv.otherUserName ?? 'Inconnu'),
                    subtitle: Text(conv.lastMessage ?? ''),
                    trailing: conv.unreadCount > 0
                        ? Badge(
                            label: Text(conv.unreadCount.toString()),
                          )
                        : null,
                    onTap: () => context.push('/chat/${conv.id}'),
                  );
                },
              ),
      ),
    );
  }
}

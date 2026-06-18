import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:return_mobile/features/messaging/data/repositories/messaging_repository.dart';
import 'package:return_mobile/features/messaging/data/models/message_model.dart';

export 'package:return_mobile/features/messaging/data/repositories/messaging_repository.dart'
    show messagingRepositoryProvider;

// Per-conversation chat state
class ChatState {
  final List<MessageModel> messages;
  final bool isLoading;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    String? error,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

final chatProvider =
    StateNotifierProvider.family<ChatNotifier, ChatState, String>(
  (ref, conversationId) => ChatNotifier(
    conversationId: conversationId,
    repo: ref.read(messagingRepositoryProvider),
  ),
);

class ChatNotifier extends StateNotifier<ChatState> {
  final String conversationId;
  final MessagingRepository repo;

  ChatNotifier({required this.conversationId, required this.repo})
      : super(const ChatState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    try {
      final messages = await repo.getMessages(conversationId);
      state = state.copyWith(messages: messages, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> send(String content) async {
    try {
      final msg = await repo.sendMessage(conversationId, content);
      state = state.copyWith(messages: [...state.messages, msg]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> refresh() => _init();
}

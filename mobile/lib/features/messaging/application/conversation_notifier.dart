import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/errors/error_handler.dart';
import '../data/models/message_model.dart';
import '../data/repositories/messaging_repository.dart';

part 'conversation_notifier.g.dart';

class ConversationState {
  const ConversationState({
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
    this.hasMore = true,
  });
  final List<MessageModel> messages;
  final bool isLoading;
  final bool isSending;
  final String? error;
  final bool hasMore;

  ConversationState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    bool? isSending,
    String? error,
    bool? hasMore,
  }) => ConversationState(
    messages: messages ?? this.messages,
    isLoading: isLoading ?? this.isLoading,
    isSending: isSending ?? this.isSending,
    error: error,
    hasMore: hasMore ?? this.hasMore,
  );
}

@riverpod
class ConversationNotifier extends _$ConversationNotifier {
  late final String _matchId;

  @override
  ConversationState build(String matchId) {
    _matchId = matchId;
    _init();
    return const ConversationState(isLoading: true);
  }

  MessagingRepository get _repo => ref.read(messagingRepositoryProvider);

  Future<void> _init() async {
    // 1. Charger l’historique
    await _loadHistory();
  }

  Future<void> _loadHistory({String? before}) async {
    state = state.copyWith(isLoading: true);
    try {
      final msgs = await _repo.getMessages(_matchId, cursor: before);
      final merged = before != null
          ? [...msgs, ...state.messages]
          : msgs;
      state = state.copyWith(
        messages: merged,
        isLoading: false,
        hasMore: msgs.length == 50,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: friendlyError(e));
    }
  }

  /// Charger les messages plus anciens (pagination infinie vers le haut)
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading || state.messages.isEmpty) return;
    await _loadHistory(before: state.messages.first.createdAt?.toIso8601String());
  }

  Future<void> send(String content) async {
    if (content.trim().isEmpty) return;
    state = state.copyWith(isSending: true);
    try {
      // Optimistic update
      final tempMsg = MessageModel(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: _matchId,
        senderId: 'me',
        content: content.trim(),
        createdAt: DateTime.now(),
        isRead: false,
      );
      state = state.copyWith(
        messages: [...state.messages, tempMsg],
        isSending: false,
      );
      await _repo.sendMessage(_matchId, content.trim());
    } catch (e) {
      state = state.copyWith(isSending: false, error: friendlyError(e));
    }
  }
}


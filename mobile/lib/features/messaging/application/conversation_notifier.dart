import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/errors/error_handler.dart';
import '../../auth/application/auth_notifier.dart';
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
  StreamSubscription<MessageModel>? _wsSub;

  @override
  ConversationState build(String matchId) {
    _matchId = matchId;
    ref.onDispose(() {
      _wsSub?.cancel();
      _repo.disconnectWs();
    });
    _init();
    return const ConversationState(isLoading: true);
  }

  MessagingRepository get _repo => ref.read(messagingRepositoryProvider);

  Future<void> _init() async {
    // 1. Charger l’historique
    await _loadHistory();
    // 2. Connecter le WebSocket
    final token = ref.read(authNotifierProvider).maybeWhen(
      authenticated: (u) => u.accessToken,
      orElse: () => null,
    );
    if (token != null) {
      _repo.connectWs(_matchId, token);
      _wsSub = _repo.messageStream.listen((msg) {
        state = state.copyWith(
          messages: [...state.messages, msg],
        );
      });
    }
  }

  Future<void> _loadHistory({String? before}) async {
    state = state.copyWith(isLoading: true);
    try {
      final msgs = await _repo.getHistory(_matchId, before: before);
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
    await _loadHistory(before: state.messages.first.createdAt);
  }

  Future<void> send(String content) async {
    if (content.trim().isEmpty) return;
    state = state.copyWith(isSending: true);
    try {
      // Optimistic update
      final tempMsg = MessageModel(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        matchId: _matchId,
        senderId: 'me',
        content: content.trim(),
        createdAt: DateTime.now().toIso8601String(),
        isRead: false,
      );
      state = state.copyWith(
        messages: [...state.messages, tempMsg],
        isSending: false,
      );
      // Envoi HTTP de secours (WebSocket est le canal principal)
      await _repo.sendMessage(_matchId, content.trim());
    } catch (e) {
      state = state.copyWith(isSending: false, error: friendlyError(e));
    }
  }
}

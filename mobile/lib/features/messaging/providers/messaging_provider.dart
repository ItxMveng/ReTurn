import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:docretour/features/messaging/repositories/messaging_repository.dart';
import 'package:docretour/shared/models/message.dart';

export 'package:docretour/features/messaging/repositories/messaging_repository.dart'
    show messagingRepositoryProvider;

// Per-match chat state
class ChatState {
  final List<ChatMessage> messages;
  final bool connected;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.connected = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? connected,
    String? error,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        connected: connected ?? this.connected,
        error: error,
      );
}

final chatProvider = StateNotifierProvider.family<ChatNotifier, ChatState, String>(
  (ref, matchId) => ChatNotifier(
    matchId: matchId,
    repo: ref.read(messagingRepositoryProvider),
    ref: ref,
  ),
);

class ChatNotifier extends StateNotifier<ChatState> {
  final String matchId;
  final MessagingRepository repo;
  final Ref ref;

  WebSocketChannel? _channel;
  StreamSubscription? _sub;

  ChatNotifier({required this.matchId, required this.repo, required this.ref})
      : super(const ChatState()) {
    _init();
  }

  Future<void> _init() async {
    // Load REST history first
    try {
      final history = await repo.getHistory(matchId);
      state = state.copyWith(messages: history);
    } catch (_) {}

    // Open WebSocket
    await _connect();
  }

  Future<void> _connect() async {
    try {
      _channel = await repo.connectWs(matchId);
      state = state.copyWith(connected: true, error: null);

      _sub = _channel!.stream.listen(
        (raw) {
          try {
            final data = jsonDecode(raw as String) as Map<String, dynamic>;
            // system messages (no 'id') are shown but not stored as ChatMessage
            if (data['type'] == 'system') {
              final sys = ChatMessage(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                matchId: matchId,
                senderId: 'system',
                content: data['content'] as String,
                messageType: 'system',
                isRead: true,
                createdAt: DateTime.now(),
              );
              state = state.copyWith(messages: [...state.messages, sys]);
              return;
            }
            if (data['id'] == null) return;
            final msg = ChatMessage.fromJson(data);
            // Deduplicate by id
            final exists = state.messages.any((m) => m.id == msg.id);
            if (!exists) {
              state = state.copyWith(messages: [...state.messages, msg]);
            }
          } catch (_) {}
        },
        onError: (_) => state = state.copyWith(connected: false),
        onDone: () => state = state.copyWith(connected: false),
      );
    } catch (e) {
      state = state.copyWith(connected: false, error: e.toString());
    }
  }

  void send(String content, {String type = 'text'}) {
    if (_channel == null) return;
    _channel!.sink.add(jsonEncode({'content': content, 'message_type': type}));
  }

  void sendLocation(double lat, double lng) {
    send('$lat,$lng', type: 'location');
  }

  Future<void> reconnect() async {
    await _sub?.cancel();
    _channel?.sink.close();
    await _connect();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
}

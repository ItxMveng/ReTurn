import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/messaging_repository.dart';
import '../models/message.dart';

final _historyProvider =
    FutureProvider.family<List<ChatMessage>, String>((ref, roomId) async {
  return ref.read(messagingRepositoryProvider).history(roomId, 'me');
});

class ChatPage extends ConsumerStatefulWidget {
  final String roomId;
  const ChatPage({super.key, required this.roomId});
  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _ctr = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;

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
      await ref
          .read(messagingRepositoryProvider)
          .send(widget.roomId, text);
      _ctr.clear();
      ref.invalidate(_historyProvider(widget.roomId));
      await Future.delayed(const Duration(milliseconds: 300));
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_historyProvider(widget.roomId));
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('Conversation #${widget.roomId.substring(0, 8)}')),
      body: Column(children: [
        Expanded(
          child: async.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(e.toString())),
            data: (msgs) => msgs.isEmpty
                ? Center(
                    child: Text('Commencez la conversation',
                        style: TextStyle(
                            color: cs.onSurface.withOpacity(0.4))))
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: msgs.length,
                    itemBuilder: (_, i) => _Bubble(msg: msgs[i]),
                  ),
          ),
        ),
        _InputBar(
            ctr: _ctr, sending: _sending, onSend: _send),
      ]),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage msg;
  const _Bubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Align(
      alignment:
          msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: msg.isMe
              ? cs.primary
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft:
                Radius.circular(msg.isMe ? 16 : 4),
            bottomRight:
                Radius.circular(msg.isMe ? 4 : 16),
          ),
        ),
        child: Text(msg.content,
            style: TextStyle(
                color: msg.isMe
                    ? Colors.white
                    : cs.onSurface,
                fontSize: 14)),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController ctr;
  final bool sending;
  final VoidCallback onSend;
  const _InputBar(
      {required this.ctr,
      required this.sending,
      required this.onSend});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
            top: BorderSide(
                color: cs.onSurface.withOpacity(0.08))),
      ),
      child: SafeArea(
        top: false,
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: ctr,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Votre message...',
                hintStyle: TextStyle(
                    color: cs.onSurface.withOpacity(0.4)),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: sending
                ? const SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : IconButton.filled(
                    onPressed: onSend,
                    icon: const Icon(Icons.send_rounded),
                    style: IconButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: Colors.white),
                  ),
          ),
        ]),
      ),
    );
  }
}

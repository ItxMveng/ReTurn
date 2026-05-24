import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/application/auth_notifier.dart';
import '../../application/conversation_notifier.dart';
import '../../data/models/message_model.dart';

class ConversationPage extends ConsumerStatefulWidget {
  const ConversationPage({super.key, required this.matchId});
  final String matchId;

  @override
  ConsumerState<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends ConsumerState<ConversationPage> {
  final _scrollCtrl = ScrollController();
  final _inputCtrl  = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _inputCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels == 0) {
      ref.read(conversationNotifierProvider(widget.matchId).notifier).loadMore();
    }
  }

  void _scrollToBottom() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state   = ref.watch(conversationNotifierProvider(widget.matchId));
    final myId    = ref.watch(authNotifierProvider).maybeWhen(
      authenticated: (u) => u.id, orElse: () => '',
    );

    // Auto-scroll à chaque nouveau message
    ref.listen(conversationNotifierProvider(widget.matchId), (prev, next) {
      if ((prev?.messages.length ?? 0) < next.messages.length) _scrollToBottom();
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Conversation'),
        backgroundColor: AppColors.background,
      ),
      body: Column(
        children: [
          // ─ Messages ─
          Expanded(
            child: state.isLoading && state.messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: state.messages.length,
                    itemBuilder: (context, i) => _MessageBubble(
                      message: state.messages[i],
                      isMe: state.messages[i].senderId == myId,
                    ),
                  ),
          ),

          // ─ Champ de saisie ─
          Container(
            padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).viewInsets.bottom + 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.outline.withOpacity(0.3))),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _send,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Écrivez un message…',
                        hintStyle: TextStyle(color: AppColors.onSurfaceVariant.withOpacity(0.6), fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: AppColors.outline.withOpacity(0.4)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: AppColors.outline.withOpacity(0.4)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        filled: true,
                        fillColor: AppColors.background,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  state.isSending
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                        )
                      : IconButton(
                          onPressed: () => _send(_inputCtrl.text),
                          icon: const Icon(Icons.send_rounded),
                          color: AppColors.primary,
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primary.withOpacity(0.12),
                            shape: const CircleBorder(),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _send(String text) {
    if (text.trim().isEmpty) return;
    ref.read(conversationNotifierProvider(widget.matchId).notifier).send(text);
    _inputCtrl.clear();
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMe});
  final MessageModel message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(18),
            topRight:    const Radius.circular(18),
            bottomLeft:  Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4, offset: const Offset(0, 1),
            )
          ],
        ),
        child: Text(
          message.content,
          style: TextStyle(
            fontSize: 14,
            color: isMe ? Colors.white : AppColors.onSurface,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/buyer/mock_data.dart';
import 'package:flutter_application_1/ui/app_tokens.dart';

/// Chat uno a uno entre el comprador y un productor simulado.
class BuyerChat extends StatefulWidget {
  const BuyerChat({super.key, required this.conversation});

  /// Conversación que se muestra en la pantalla.
  final MockConversation conversation;

  @override
  State<BuyerChat> createState() => _BuyerChatState();
}

class _BuyerChatState extends State<BuyerChat> {
  late final List<MockMessage> _messages = [...widget.conversation.messages];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(MockMessage(text: text, fromBuyer: true, time: 'Ahora'));
    });
    _controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  Widget build(BuildContext context) {
    final conversation = widget.conversation;
    return Scaffold(
      backgroundColor: AppColors.whitemodeBackgrund,
      appBar: AppBar(
        backgroundColor: AppColors.blackGreen,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF3E6),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  conversation.emoji,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  conversation.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(
                  '• En línea',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.more_horiz, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _messages.length,
              itemBuilder: (context, i) =>
                  _MessageBubble(message: _messages[i]),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.dark.withValues(alpha: 0.12),
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.add,
                        color: AppColors.blackGreen,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFEFEAE0),
                        hintText: 'Escribe un mensaje...',
                        hintStyle: TextStyle(
                          color: AppColors.dark.withValues(alpha: 0.4),
                          fontSize: 14,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.dark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _send,
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.blackGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
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
}

/// Burbuja de un mensaje, alineada según quién lo envió.
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final MockMessage message;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: message.fromBuyer
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: message.fromBuyer ? AppColors.blackGreen : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(message.fromBuyer ? 18 : 4),
              bottomRight: Radius.circular(message.fromBuyer ? 4 : 18),
            ),
            border: message.fromBuyer
                ? null
                : Border.all(color: AppColors.dark.withValues(alpha: 0.06)),
          ),
          child: Text(
            message.text,
            style: TextStyle(
              fontSize: 14,
              height: 1.3,
              color: message.fromBuyer ? Colors.white : AppColors.dark,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            message.time,
            style: TextStyle(fontSize: 11, color: AppTints.muted),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

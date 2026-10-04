import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/api_config.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/core/token_store.dart';
import 'package:flutter_application_1/features/buyer/chat_connection.dart';
import 'package:flutter_application_1/features/buyer/conversation_models.dart';
import 'package:flutter_application_1/features/buyer/conversation_repository.dart';
import 'package:flutter_application_1/ui/app_tokens.dart';

class BuyerChat extends StatefulWidget {
  const BuyerChat({
    super.key,
    required this.conversationId,
    required this.counterpartName,
    this.repository,
    this.connection,
    this.currentUserId,
  });

  final String conversationId;
  final String counterpartName;
  final ConversationRepository? repository;
  final ChatConnection? connection;
  final String? currentUserId;

  @override
  State<BuyerChat> createState() => _BuyerChatState();
}

class _BuyerChatState extends State<BuyerChat> {
  late final ConversationRepository _repository =
      widget.repository ??
      ConversationRepository(apiClient: ApiClient(), tokenStore: TokenStore());
  final TokenStore _tokenStore = TokenStore();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  List<ChatMessage> _messages = <ChatMessage>[];
  Set<String> _knownIds = <String>{};
  ChatConnection? _connection;
  StreamSubscription<ChatMessage>? _messageSubscription;
  StreamSubscription<bool>? _statusSubscription;
  Timer? _retryTimer;
  String? _currentUserId;
  String? _token;
  bool _connected = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _messageSubscription?.cancel();
    _statusSubscription?.cancel();
    _connection?.close();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final ChatConnection? injectedConnection = widget.connection;
      String? userId = widget.currentUserId;
      String? token;
      if (injectedConnection == null || userId == null) {
        token = await _tokenStore.readToken();
        userId ??= await _tokenStore.readUserId();
      }
      final List<ChatMessage> history = await _repository.fetchMessages(
        widget.conversationId,
      );
      final ChatConnection connection;
      if (injectedConnection != null) {
        connection = injectedConnection;
      } else {
        final String? authToken = token;
        if (authToken == null) {
          throw const ApiException(401, 'Sesión no disponible');
        }
        connection = WebSocketChatConnection(
          uri: ApiConfig.webSocketUri(widget.conversationId),
          token: authToken,
        );
      }
      final List<ChatMessage> prepared = _prepareMessages(history);
      _connection = connection;
      _currentUserId = userId;
      _token = token;
      _messages = prepared;
      _knownIds = prepared.map((ChatMessage message) => message.id).toSet();
      _connected = connection.isConnected;
      if (!mounted) {
        await connection.close();
        return;
      }
      _listenToConnection(connection);
      setState(() => _loading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudo cargar la conversación';
      });
    }
  }

  Future<void> _retry() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await _init();
  }

  void _listenToConnection(ChatConnection connection) {
    _messageSubscription = connection.messages.listen(_handleIncoming);
    _statusSubscription = connection.status.listen(_handleStatus);
  }

  void _stopListening() {
    _messageSubscription?.cancel();
    _messageSubscription = null;
    _statusSubscription?.cancel();
    _statusSubscription = null;
  }

  void _handleIncoming(ChatMessage message) {
    if (!mounted) return;
    if (!_knownIds.add(message.id)) return;
    setState(() => _messages = <ChatMessage>[..._messages, message]);
    _scrollToBottom();
  }

  void _handleStatus(bool connected) {
    if (!mounted) return;
    final bool reconnected = connected && !_connected;
    setState(() => _connected = connected);
    if (connected) {
      _stopRetryTimer();
      if (reconnected) {
        _refetchHistory();
      }
    } else {
      _startRetryTimer();
    }
  }

  void _startRetryTimer() {
    _retryTimer ??= Timer.periodic(
      const Duration(seconds: 5),
      (_) => _attemptReconnect(),
    );
  }

  void _stopRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  Future<void> _attemptReconnect() async {
    if (!mounted || _connected || widget.connection != null) return;
    final String? token = _token;
    if (token == null) return;
    try {
      final ChatConnection? previous = _connection;
      if (previous != null) {
        _stopListening();
        await previous.close();
      }
      if (!mounted) return;
      final WebSocketChatConnection next = WebSocketChatConnection(
        uri: ApiConfig.webSocketUri(widget.conversationId),
        token: token,
      );
      _connection = next;
      _listenToConnection(next);
    } catch (_) {
      return;
    }
  }

  Future<void> _refetchHistory() async {
    try {
      final List<ChatMessage> history = await _repository.fetchMessages(
        widget.conversationId,
      );
      if (!mounted) return;
      final List<ChatMessage> prepared = _prepareMessages(history);
      setState(() {
        _messages = prepared;
        _knownIds = prepared.map((ChatMessage message) => message.id).toSet();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (_) {
      return;
    }
  }

  Future<void> _send() async {
    final String text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    try {
      final ChatConnection? connection = _connection;
      if (connection != null && connection.isConnected) {
        connection.send(text);
      } else {
        await _repository.sendMessage(
          conversationId: widget.conversationId,
          content: text,
        );
        await _refetchHistory();
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('No se pudo enviar el mensaje')),
        );
    }
  }

  List<ChatMessage> _prepareMessages(List<ChatMessage> messages) {
    final Set<String> seen = <String>{};
    final List<ChatMessage> prepared = <ChatMessage>[];
    for (final ChatMessage message in messages) {
      if (!seen.add(message.id)) continue;
      prepared.add(message);
    }
    prepared.sort(_compareByCreatedAt);
    return prepared;
  }

  int _compareByCreatedAt(ChatMessage a, ChatMessage b) {
    final DateTime? left = DateTime.tryParse(a.createdAt ?? '');
    final DateTime? right = DateTime.tryParse(b.createdAt ?? '');
    if (left == null && right == null) return 0;
    if (left == null) return -1;
    if (right == null) return 1;
    return left.compareTo(right);
  }

  String _timeLabel(ChatMessage message) {
    final DateTime? parsed = DateTime.tryParse(message.createdAt ?? '');
    if (parsed == null) return '';
    final DateTime local = parsed.toLocal();
    final String hour = local.hour.toString().padLeft(2, '0');
    final String minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _initial(String name) => name.isEmpty ? '?' : name[0].toUpperCase();

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  _initial(widget.counterpartName),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blackGreen,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.counterpartName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _connected ? 'En línea' : 'Sin conexión',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorState(onRetry: _retry);
    }
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            itemCount: _messages.length,
            itemBuilder: (BuildContext context, int index) {
              final ChatMessage message = _messages[index];
              return _MessageBubble(
                message: message,
                mine:
                    message.senderId != null &&
                    message.senderId == _currentUserId,
                timeLabel: _timeLabel(message),
              );
            },
          ),
        ),
        SafeArea(top: false, child: _buildComposer()),
      ],
    );
  }

  Widget _buildComposer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.dark.withValues(alpha: 0.12)),
            ),
            child: const Center(
              child: Icon(Icons.add, color: AppColors.blackGreen, size: 22),
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
              style: const TextStyle(fontSize: 14, color: AppColors.dark),
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
                child: Icon(Icons.arrow_forward, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.mine,
    required this.timeLabel,
  });

  final ChatMessage message;
  final bool mine;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    if (message.isFromSponsor) {
      return _SponsorNotice(content: message.content, timeLabel: timeLabel);
    }
    return Column(
      crossAxisAlignment: mine
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: mine ? AppColors.blackGreen : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(mine ? 18 : 4),
              bottomRight: Radius.circular(mine ? 4 : 18),
            ),
            border: mine
                ? null
                : Border.all(color: AppColors.dark.withValues(alpha: 0.06)),
          ),
          child: Text(
            message.content,
            style: TextStyle(
              fontSize: 14,
              height: 1.3,
              color: mine ? Colors.white : AppColors.dark,
            ),
          ),
        ),
        if (timeLabel.isNotEmpty) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              timeLabel,
              style: TextStyle(fontSize: 11, color: AppTints.muted),
            ),
          ),
        ],
        const SizedBox(height: 10),
      ],
    );
  }
}

class _SponsorNotice extends StatelessWidget {
  const _SponsorNotice({required this.content, required this.timeLabel});

  final String content;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs + 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.yelow.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                content,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                ),
              ),
              if (timeLabel.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  timeLabel,
                  style: TextStyle(fontSize: 10, color: AppTints.muted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off, size: 40, color: AppTints.muted),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'No se pudo cargar la conversación',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: AppColors.blackGreen),
            child: const Text(
              'Reintentar',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

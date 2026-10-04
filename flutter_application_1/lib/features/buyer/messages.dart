import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/token_store.dart';
import 'package:flutter_application_1/features/buyer/chat.dart';
import 'package:flutter_application_1/features/buyer/conversation_models.dart';
import 'package:flutter_application_1/features/buyer/conversation_repository.dart';
import 'package:flutter_application_1/features/buyer/offering_models.dart';
import 'package:flutter_application_1/features/buyer/offering_repository.dart';
import 'package:flutter_application_1/ui/app_tokens.dart';

class BuyerMessages extends StatefulWidget {
  const BuyerMessages({super.key, this.repository, this.offeringRepository});

  final ConversationRepository? repository;
  final OfferingRepository? offeringRepository;

  @override
  State<BuyerMessages> createState() => _BuyerMessagesState();
}

class _BuyerMessagesState extends State<BuyerMessages> {
  late final ConversationRepository _repository =
      widget.repository ??
      ConversationRepository(apiClient: ApiClient(), tokenStore: TokenStore());
  late final OfferingRepository _offeringRepository =
      widget.offeringRepository ?? OfferingRepository(apiClient: ApiClient());
  final TokenStore _tokenStore = TokenStore();

  List<_InboxEntry> _entries = <_InboxEntry>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final List<Conversation> conversations = await _repository.fetchAll();
      final String? currentUserId = await _readCurrentUserId();
      final List<_InboxEntry> entries = await Future.wait(
        conversations.map(
          (Conversation conversation) =>
              _resolveEntry(conversation, currentUserId),
        ),
      );
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudo cargar los mensajes';
      });
    }
  }

  Future<void> _retry() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await _load();
  }

  Future<String?> _readCurrentUserId() async {
    try {
      return await _tokenStore.readUserId();
    } catch (_) {
      return null;
    }
  }

  Future<_InboxEntry> _resolveEntry(
    Conversation conversation,
    String? currentUserId,
  ) async {
    String name = 'Productor';
    String? preview;
    String? createdAt;
    try {
      final SellerProfile seller = await _offeringRepository.fetchSeller(
        _counterpartId(conversation, currentUserId),
      );
      if (seller.fullName.isNotEmpty) {
        name = seller.fullName;
      }
    } catch (_) {
      name = 'Productor';
    }
    try {
      final List<ChatMessage> messages = await _repository.fetchMessages(
        conversation.id,
      );
      final List<ChatMessage> sorted = _sortByCreatedAt(messages);
      if (sorted.isNotEmpty) {
        preview = sorted.last.content;
        createdAt = sorted.last.createdAt;
      }
    } catch (_) {
      preview = null;
      createdAt = null;
    }
    return _InboxEntry(
      conversation: conversation,
      name: name,
      preview: preview,
      createdAt: createdAt,
    );
  }

  String _counterpartId(Conversation conversation, String? currentUserId) {
    final bool isBuyer =
        currentUserId == null || currentUserId == conversation.buyerId;
    return isBuyer ? conversation.farmerId : conversation.buyerId;
  }

  List<ChatMessage> _sortByCreatedAt(List<ChatMessage> messages) {
    final List<ChatMessage> sorted = <ChatMessage>[...messages];
    sorted.sort((ChatMessage a, ChatMessage b) {
      final DateTime? left = DateTime.tryParse(a.createdAt ?? '');
      final DateTime? right = DateTime.tryParse(b.createdAt ?? '');
      if (left == null && right == null) return 0;
      if (left == null) return -1;
      if (right == null) return 1;
      return left.compareTo(right);
    });
    return sorted;
  }

  void _openChat(_InboxEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BuyerChat(
          conversationId: entry.conversation.id,
          counterpartName: entry.name,
        ),
      ),
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
        title: const Text('Mensajes', style: AppText.appBarText),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.phone_outlined,
                  color: Colors.white,
                  size: 20,
                ),
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
    if (_entries.isEmpty) {
      return const _EmptyState();
    }
    return ListView.separated(
      itemCount: _entries.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        thickness: 1,
        color: AppColors.dark.withValues(alpha: 0.06),
      ),
      itemBuilder: (BuildContext context, int index) => _InboxRow(
        entry: _entries[index],
        onTap: () => _openChat(_entries[index]),
      ),
    );
  }
}

class _InboxEntry {
  const _InboxEntry({
    required this.conversation,
    required this.name,
    this.preview,
    this.createdAt,
  });

  final Conversation conversation;
  final String name;
  final String? preview;
  final String? createdAt;
}

class _InboxRow extends StatelessWidget {
  const _InboxRow({required this.entry, required this.onTap});

  final _InboxEntry entry;
  final VoidCallback onTap;

  String _initial(String name) => name.isEmpty ? '?' : name[0].toUpperCase();

  String _timeLabel(String? createdAt) {
    final DateTime? parsed = DateTime.tryParse(createdAt ?? '');
    if (parsed == null) return '';
    final DateTime local = parsed.toLocal();
    final DateTime now = DateTime.now();
    final bool sameDay =
        local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    final String hour = local.hour.toString().padLeft(2, '0');
    final String minute = local.minute.toString().padLeft(2, '0');
    if (sameDay) return '$hour:$minute';
    final String day = local.day.toString().padLeft(2, '0');
    final String month = local.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  @override
  Widget build(BuildContext context) {
    final String time = _timeLabel(entry.createdAt);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md + AppSpacing.xs,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF3E6),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _initial(entry.name),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blackGreen,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    entry.preview ?? 'Sin mensajes aún',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: AppTints.secondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (time.isNotEmpty)
              Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppTints.muted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_outlined, size: 40, color: AppTints.muted),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Todavía no tenés conversaciones',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Cuando escribas a un productor, vas a ver el chat acá.',
              textAlign: TextAlign.center,
              style: AppText.caption,
            ),
          ],
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
            'No se pudo cargar los mensajes',
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

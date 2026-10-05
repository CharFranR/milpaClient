import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/token_store.dart';
import 'package:flutter_application_1/features/buyer/chat.dart';
import 'package:flutter_application_1/features/buyer/conversation_models.dart';
import 'package:flutter_application_1/features/buyer/conversation_repository.dart';
import 'package:flutter_application_1/features/buyer/offering_models.dart';
import 'package:flutter_application_1/features/buyer/offering_repository.dart';
import 'package:flutter_application_1/ui/app_tokens.dart';

class FarmerMessagesPage extends StatefulWidget {
  const FarmerMessagesPage({
    super.key,
    this.repository,
    this.offeringRepository,
  });

  final ConversationRepository? repository;
  final OfferingRepository? offeringRepository;

  @override
  State<FarmerMessagesPage> createState() => _FarmerMessagesPageState();
}

class _FarmerMessagesPageState extends State<FarmerMessagesPage> {
  late final ConversationRepository _repository =
      widget.repository ??
      ConversationRepository(apiClient: ApiClient(), tokenStore: TokenStore());
  late final OfferingRepository _offeringRepository =
      widget.offeringRepository ?? OfferingRepository(apiClient: ApiClient());
  final TokenStore _tokenStore = TokenStore();

  List<_InboxEntry> _entries = <_InboxEntry>[];
  bool _loading = true;
  bool _failed = false;

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
        _failed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<void> _retry() async {
    setState(() {
      _loading = true;
      _failed = false;
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
    String name = 'El comprador';
    String? preview;
    String? createdAt;
    try {
      final SellerProfile buyer = await _offeringRepository.fetchSeller(
        _counterpartId(conversation, currentUserId),
      );
      if (buyer.fullName.isNotEmpty) {
        name = buyer.fullName;
      }
    } catch (_) {
      name = 'El comprador';
    }
    try {
      final List<ChatMessage> messages = _sortByCreatedAt(
        await _repository.fetchMessages(conversation.id),
      );
      if (messages.isNotEmpty) {
        preview = messages.last.content;
        createdAt = messages.last.createdAt;
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
    final bool isFarmer =
        currentUserId == null || currentUserId == conversation.farmerId;
    return isFarmer ? conversation.buyerId : conversation.farmerId;
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_failed) {
      return _ErrorState(onRetry: _retry);
    }
    if (_entries.isEmpty) {
      return const _EmptyState();
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.blackGreen,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
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

  String _subtitle() {
    final String? preview = entry.preview;
    if (preview != null && preview.isNotEmpty) return preview;
    return 'Todavía no hay mensajes en esta charla';
  }

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
    final bool closedDeal = entry.conversation.offeringId.isEmpty;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md + AppSpacing.xs,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF3E6),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _initial(entry.name),
                  style: const TextStyle(
                    fontSize: 20,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  ),
                  if (closedDeal) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.blackGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.handshake_outlined,
                            size: 15,
                            color: AppColors.blackGreen,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Trato cerrado',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.blackGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 3),
                  Text(
                    _subtitle(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, color: AppTints.secondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (time.isNotEmpty)
              Text(
                time,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                color: AppColors.whiteGreen.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.chat_bubble_outline,
                  size: 56,
                  color: AppColors.blackGreen,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Mensajes',
              textAlign: TextAlign.center,
              style: AppText.screenTitle,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Todavía no tenés conversaciones.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Cuando un comprador te escriba por un producto, vas a ver '
              'la charla acá.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: AppColors.dark),
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                color: AppColors.whiteGreen.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.wifi_off_outlined,
                  size: 56,
                  color: AppColors.blackGreen,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'No pudimos cargar tus mensajes',
              textAlign: TextAlign.center,
              style: AppText.screenTitle,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Revisá que tengas internet y volvé a intentar.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.blackGreen,
                minimumSize: const Size(0, 62),
                side: const BorderSide(color: AppColors.blackGreen, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              icon: const Icon(Icons.refresh, size: 26),
              label: const Text('Volver a intentar'),
            ),
          ],
        ),
      ),
    );
  }
}

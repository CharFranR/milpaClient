import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/core/token_store.dart';
import 'package:flutter_application_1/features/auth/session_controller.dart';
import 'package:flutter_application_1/features/buyer/chat.dart';
import 'package:flutter_application_1/features/buyer/conversation_models.dart';
import 'package:flutter_application_1/features/buyer/conversation_repository.dart';
import 'package:flutter_application_1/features/buyer/match_models.dart';
import 'package:flutter_application_1/features/buyer/match_repository.dart';
import 'package:flutter_application_1/features/buyer/offering_models.dart';
import 'package:flutter_application_1/features/buyer/offering_repository.dart';
import 'package:flutter_application_1/features/buyer/supply_request_models.dart';
import 'package:flutter_application_1/features/buyer/transaction_repository.dart';
import 'package:flutter_application_1/ui/app_tokens.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({
    super.key,
    required this.matchId,
    this.repository,
    this.matchRepository,
    this.conversationRepository,
    this.offeringRepository,
  });

  final String matchId;
  final TransactionRepository? repository;
  final MatchRepository? matchRepository;
  final ConversationRepository? conversationRepository;
  final OfferingRepository? offeringRepository;

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  late final TransactionRepository _repository =
      widget.repository ??
      TransactionRepository(apiClient: ApiClient(), tokenStore: TokenStore());
  late final MatchRepository _matchRepository =
      widget.matchRepository ??
      MatchRepository(apiClient: ApiClient(), tokenStore: TokenStore());
  late final ConversationRepository _conversationRepository =
      widget.conversationRepository ??
      ConversationRepository(apiClient: ApiClient(), tokenStore: TokenStore());
  late final OfferingRepository _offeringRepository =
      widget.offeringRepository ?? OfferingRepository(apiClient: ApiClient());

  Transaction? _transaction;
  Match? _match;
  List<Conversation> _conversations = <Conversation>[];
  String _counterpartName = 'Productor';
  String _supplierId = '';
  bool _alreadyRated = false;
  bool _requestedLoad = false;
  bool _loading = true;
  Object? _error;
  SessionController? _session;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requestedLoad) return;
    _requestedLoad = true;
    _session = SessionScope.of(context);
    _load();
  }

  Future<void> _load({bool showSpinner = true}) async {
    if (showSpinner && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final Transaction transaction = await _repository.fetchByMatch(
        widget.matchId,
      );
      final Match match = await _matchRepository.fetchMatch(widget.matchId);
      final MatchOffer offer = await _matchRepository.fetchSupplyOffer(
        match.supplyOffer,
      );
      final List<Conversation> conversations = await _loadConversations();
      final SellerProfile? seller = await _loadSeller(offer.supplierId);
      final String? userId = await _currentUserId();
      final Set<String> rated = userId == null
          ? <String>{}
          : await _repository.fetchAuthoredReviewTransactionIds(userId);
      final String name = seller == null ? '' : seller.fullName;
      if (!mounted) return;
      setState(() {
        _transaction = transaction;
        _match = match;
        _supplierId = offer.supplierId;
        _counterpartName = name.isEmpty ? 'Productor' : name;
        _conversations = conversations;
        _alreadyRated = rated.contains(transaction.id);
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  Future<List<Conversation>> _loadConversations() async {
    try {
      return await _conversationRepository.fetchAll();
    } catch (_) {
      return <Conversation>[];
    }
  }

  Future<SellerProfile?> _loadSeller(String supplierId) async {
    if (supplierId.isEmpty) return null;
    try {
      return await _offeringRepository.fetchSeller(supplierId);
    } catch (_) {
      return null;
    }
  }

  Future<String?> _currentUserId() async {
    final SessionController? session = _session;
    if (session == null) return null;
    if (session.user == null) {
      await session.loadUser();
    }
    return session.user?.id;
  }

  Conversation? get _matchConversation {
    for (final Conversation conversation in _conversations) {
      if (conversation.matchId == widget.matchId) return conversation;
    }
    return null;
  }

  Future<void> _confirmStart() async {
    final Transaction? transaction = _transaction;
    if (transaction == null) return;
    try {
      await _repository.confirmStart(transaction.id);
      if (!mounted) return;
      _showMessage('Inicio confirmado');
      await _load(showSpinner: false);
    } on ApiException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
      await _load(showSpinner: false);
    } catch (_) {
      if (!mounted) return;
      _showMessage('No se pudo confirmar el inicio');
    }
  }

  Future<void> _confirmDelivery() async {
    final Transaction? transaction = _transaction;
    if (transaction == null) return;
    try {
      await _repository.confirmDelivery(transaction.id);
      if (!mounted) return;
      _showMessage('Entrega confirmada');
      await _load(showSpinner: false);
    } on ApiException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
      await _load(showSpinner: false);
    } catch (_) {
      if (!mounted) return;
      _showMessage('No se pudo confirmar la entrega');
    }
  }

  Future<void> _cancel() async {
    final Transaction? transaction = _transaction;
    if (transaction == null) return;
    final String? reason = await showDialog<String>(
      context: context,
      builder: (_) => const _CancelDialog(),
    );
    if (reason == null || !mounted) return;
    try {
      await _repository.cancel(transaction.id, reason);
      if (!mounted) return;
      _showMessage('Transacción cancelada');
      await _load(showSpinner: false);
    } on ApiException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
      await _load(showSpinner: false);
    } catch (_) {
      if (!mounted) return;
      _showMessage('No se pudo cancelar la transacción');
    }
  }

  Future<void> _rate() async {
    final Transaction? transaction = _transaction;
    final String targetId = _supplierId;
    if (transaction == null || targetId.isEmpty) return;
    final ({int rating, String comment})? result =
        await showDialog<({int rating, String comment})>(
          context: context,
          builder: (_) => _RatingDialog(counterpartName: _counterpartName),
        );
    if (result == null || !mounted) return;
    try {
      await _repository.rate(
        transactionId: transaction.id,
        targetId: targetId,
        rating: result.rating,
        comment: result.comment,
      );
      if (!mounted) return;
      _showMessage('Gracias por tu calificación');
      await _load(showSpinner: false);
    } on ApiException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('No se pudo enviar la calificación');
    }
  }

  Future<void> _openChat() async {
    final Conversation? conversation = _matchConversation;
    if (conversation == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BuyerChat(
          conversationId: conversation.id,
          counterpartName: _counterpartName,
        ),
      ),
    );
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whitemodeBackgrund,
      appBar: AppBar(
        backgroundColor: AppColors.blackGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Transacción', style: AppText.appBarText),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final Transaction? transaction = _transaction;
    final Match? match = _match;
    if (_error != null || transaction == null || match == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No se pudo cargar la transacción'),
            TextButton(
              onPressed: () => _load(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(showSpinner: false),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SummaryCard(
              counterpartName: _counterpartName,
              status: transaction.status,
              matchedAmount: match.matchedAmount,
              amountUnit: match.amountUnit,
            ),
            const SizedBox(height: AppSpacing.lg),
            _ChecklistCard(transaction: transaction),
            if (transaction.status == TransactionStatus.cancelled &&
                transaction.cancelReason.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              _ReasonCard(reason: transaction.cancelReason),
            ],
            const SizedBox(height: AppSpacing.lg),
            _ActionsCard(
              transaction: transaction,
              hasConversation: _matchConversation != null,
              alreadyRated: _alreadyRated,
              onConfirmStart: _confirmStart,
              onConfirmDelivery: _confirmDelivery,
              onCancel: _cancel,
              onOpenChat: _openChat,
              onRate: _rate,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.counterpartName,
    required this.status,
    required this.matchedAmount,
    required this.amountUnit,
  });

  final String counterpartName;
  final TransactionStatus status;
  final double matchedAmount;
  final MeasureUnit amountUnit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dark.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(counterpartName, style: AppText.label)),
              const SizedBox(width: AppSpacing.sm),
              _StatusChip(status: status),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Monto acordado: ${_quantity(matchedAmount)} ${amountUnit.label}',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.blackGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  const _ChecklistCard({required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dark.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Confirmaciones', style: AppText.sectionTitle),
          const SizedBox(height: AppSpacing.md),
          Text('Inicio', style: AppText.label),
          const SizedBox(height: AppSpacing.sm),
          _ChecklistRow(
            textKey: 'start-buyer',
            done: transaction.buyerStartConfirmedAt != null,
            text: transaction.buyerStartConfirmedAt == null
                ? 'Vos: falta confirmar el inicio'
                : 'Vos: confirmado el ${_formatDate(transaction.buyerStartConfirmedAt)}',
          ),
          _ChecklistRow(
            textKey: 'start-supplier',
            done: transaction.supplierStartConfirmedAt != null,
            text: transaction.supplierStartConfirmedAt == null
                ? 'Falta que el agricultor confirme'
                : 'El agricultor confirmó el ${_formatDate(transaction.supplierStartConfirmedAt)}',
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Entrega', style: AppText.label),
          const SizedBox(height: AppSpacing.sm),
          _ChecklistRow(
            textKey: 'delivery-buyer',
            done: transaction.buyerDeliveryConfirmedAt != null,
            text: transaction.buyerDeliveryConfirmedAt == null
                ? 'Vos: falta confirmar la entrega'
                : 'Vos: confirmado el ${_formatDate(transaction.buyerDeliveryConfirmedAt)}',
          ),
          _ChecklistRow(
            textKey: 'delivery-supplier',
            done: transaction.supplierDeliveryConfirmedAt != null,
            text: transaction.supplierDeliveryConfirmedAt == null
                ? 'Falta que el agricultor confirme la entrega'
                : 'El agricultor confirmó la entrega el ${_formatDate(transaction.supplierDeliveryConfirmedAt)}',
          ),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.textKey,
    required this.done,
    required this.text,
  });

  final String textKey;
  final bool done;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: done ? AppColors.blackGreen : AppTints.muted,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              key: ValueKey<String>(textKey),
              style: AppText.bodySecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonCard extends StatelessWidget {
  const _ReasonCard({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text('Motivo: $reason', style: AppText.body),
    );
  }
}

class _ActionsCard extends StatelessWidget {
  const _ActionsCard({
    required this.transaction,
    required this.hasConversation,
    required this.alreadyRated,
    required this.onConfirmStart,
    required this.onConfirmDelivery,
    required this.onCancel,
    required this.onOpenChat,
    required this.onRate,
  });

  final Transaction transaction;
  final bool hasConversation;
  final bool alreadyRated;
  final VoidCallback onConfirmStart;
  final VoidCallback onConfirmDelivery;
  final VoidCallback onCancel;
  final VoidCallback onOpenChat;
  final VoidCallback onRate;

  @override
  Widget build(BuildContext context) {
    final bool canStart =
        transaction.status == TransactionStatus.matched &&
        transaction.buyerStartConfirmedAt == null;
    final bool canDeliver =
        transaction.status == TransactionStatus.inProgress &&
        transaction.buyerDeliveryConfirmedAt == null;
    final bool canCancel = !transaction.status.isTerminal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          onPressed: canStart ? onConfirmStart : null,
          style: FilledButton.styleFrom(backgroundColor: AppColors.blackGreen),
          child: const Text('Confirmar inicio'),
        ),
        const SizedBox(height: AppSpacing.sm),
        FilledButton(
          onPressed: canDeliver ? onConfirmDelivery : null,
          style: FilledButton.styleFrom(backgroundColor: AppColors.blackGreen),
          child: const Text('Confirmar entrega'),
        ),
        if (canCancel) ...[
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancelar'),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: hasConversation ? onOpenChat : null,
          child: const Text('Abrir chat'),
        ),
        if (!hasConversation)
          Text(
            'El chat todavía no está disponible',
            textAlign: TextAlign.center,
            style: AppText.bodySecondary,
          ),
        if (transaction.status == TransactionStatus.completed) ...[
          const SizedBox(height: AppSpacing.sm),
          if (alreadyRated)
            Text(
              'Ya calificaste esta transacción',
              textAlign: TextAlign.center,
              style: AppText.bodySecondary,
            )
          else
            FilledButton(
              onPressed: onRate,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blackGreen,
              ),
              child: const Text('Calificar'),
            ),
        ],
      ],
    );
  }
}

class _CancelDialog extends StatefulWidget {
  const _CancelDialog();

  @override
  State<_CancelDialog> createState() => _CancelDialogState();
}

class _CancelDialogState extends State<_CancelDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _showError = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final String reason = _controller.text.trim();
    if (reason.isEmpty) {
      setState(() => _showError = true);
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('¿Cancelar la transacción?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: const ValueKey<String>('cancel-reason'),
            controller: _controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Motivo de la cancelación',
            ),
            onChanged: (_) {
              if (_showError) setState(() => _showError = false);
            },
          ),
          if (_showError) ...[
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Ingresá un motivo',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Volver'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(backgroundColor: AppColors.blackGreen),
          child: const Text('Cancelar transacción'),
        ),
      ],
    );
  }
}

class _RatingDialog extends StatefulWidget {
  const _RatingDialog({required this.counterpartName});

  final String counterpartName;

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  final TextEditingController _controller = TextEditingController();
  int _rating = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_rating == 0) return;
    Navigator.of(context).pop((
      rating: _rating,
      comment: _controller.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Calificar al agricultor'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.counterpartName, style: AppText.label),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List<Widget>.generate(5, (int index) {
              final int value = index + 1;
              return IconButton(
                key: ValueKey<String>('rate-star-$value'),
                onPressed: () => setState(() => _rating = value),
                icon: Icon(
                  value <= _rating ? Icons.star : Icons.star_border,
                  color: AppColors.yelow,
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            key: const ValueKey<String>('rate-comment'),
            controller: _controller,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Comentario (opcional)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Volver'),
        ),
        FilledButton(
          onPressed: _rating == 0 ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: AppColors.blackGreen),
          child: const Text('Enviar calificación'),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final TransactionStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color background, Color foreground) = switch (status) {
      TransactionStatus.matched || TransactionStatus.completed => (
        AppColors.whiteGreen.withValues(alpha: 0.2),
        AppColors.blackGreen,
      ),
      TransactionStatus.inProgress => (
        AppColors.dark.withValues(alpha: 0.08),
        AppColors.dark,
      ),
      TransactionStatus.cancelled => (
        Colors.red.withValues(alpha: 0.1),
        Colors.red,
      ),
      TransactionStatus.unknown => (
        AppColors.dark.withValues(alpha: 0.06),
        AppTints.secondary,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _formatDate(String? value) {
  final DateTime? date = DateTime.tryParse(value ?? '');
  if (date == null) return 'Sin definir';
  final String day = date.day.toString().padLeft(2, '0');
  final String month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String _quantity(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toString();
}

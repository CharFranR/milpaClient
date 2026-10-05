import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/core/token_store.dart';
import 'package:flutter_application_1/features/buyer/catalog_models.dart';
import 'package:flutter_application_1/features/buyer/chat.dart';
import 'package:flutter_application_1/features/buyer/conversation_models.dart';
import 'package:flutter_application_1/features/buyer/match_models.dart';
import 'package:flutter_application_1/features/buyer/report_dialog.dart';
import 'package:flutter_application_1/features/buyer/report_repository.dart';
import 'package:flutter_application_1/features/buyer/transaction_repository.dart';
import 'package:flutter_application_1/features/farmer/sale_models.dart';
import 'package:flutter_application_1/features/farmer/sale_repository.dart';
import 'package:flutter_application_1/ui/app_tokens.dart';

class FarmerSalesPage extends StatefulWidget {
  const FarmerSalesPage({
    super.key,
    this.repository,
    this.reviewRepository,
    this.reportRepository,
  });

  final SaleRepository? repository;
  final TransactionRepository? reviewRepository;
  final ReportRepository? reportRepository;

  @override
  State<FarmerSalesPage> createState() => _FarmerSalesPageState();
}

class _FarmerSalesPageState extends State<FarmerSalesPage> {
  late final SaleRepository _repository =
      widget.repository ??
      SaleRepository(apiClient: ApiClient(), tokenStore: TokenStore());
  late final TransactionRepository _reviewRepository =
      widget.reviewRepository ??
      TransactionRepository(apiClient: ApiClient(), tokenStore: TokenStore());
  late final ReportRepository _reportRepository =
      widget.reportRepository ??
      ReportRepository(apiClient: ApiClient(), tokenStore: TokenStore());
  final ApiClient _buyerApi = ApiClient();
  final TokenStore _tokenStore = TokenStore();

  List<Sale> _sales = <Sale>[];
  Map<String, Conversation> _conversations = <String, Conversation>{};
  Set<String> _ratedTransactionIds = <String>{};
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
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
      final List<Sale> sales = await _repository.fetchMySales();
      final Map<String, Conversation> conversations =
          await _loadConversations();
      final Set<String> rated = await _loadRatedTransactionIds();
      if (!mounted) return;
      setState(() {
        _sales = sales;
        _conversations = conversations;
        _ratedTransactionIds = rated;
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

  Future<Map<String, Conversation>> _loadConversations() async {
    try {
      return await _repository.fetchConversationsByMatch();
    } catch (_) {
      return <String, Conversation>{};
    }
  }

  Future<Set<String>> _loadRatedTransactionIds() async {
    try {
      final String? userId = await _tokenStore.readUserId();
      if (userId == null || userId.isEmpty) return <String>{};
      return await _reviewRepository.fetchAuthoredReviewTransactionIds(userId);
    } catch (_) {
      return <String>{};
    }
  }

  Future<String> _resolveBuyerId(Sale sale) async {
    final Conversation? conversation =
        _conversations[sale.transaction.matchId];
    final String fromConversation = conversation?.buyerId ?? '';
    if (fromConversation.isNotEmpty) return fromConversation;
    final String? token = await _tokenStore.readToken();
    if (token == null || token.isEmpty) return '';
    final dynamic json = await _buyerApi.get(
      '/supply-requests/${sale.requestId}',
      token: token,
    );
    if (json is Map<String, dynamic>) {
      return json['buyer_id'] as String? ?? '';
    }
    return '';
  }

  bool _canReport(Sale sale) {
    if (sale.buyerName.isNotEmpty) return true;
    final Conversation? conversation =
        _conversations[sale.transaction.matchId];
    return conversation != null && conversation.buyerId.isNotEmpty;
  }

  Future<void> _confirmStart(Sale sale) async {
    try {
      await _repository.confirmStart(sale.transaction.id);
      if (!mounted) return;
      _showMessage('Listo, ya confirmaste el inicio.');
      await _load(showSpinner: false);
    } on ApiException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
      await _load(showSpinner: false);
    } catch (_) {
      if (!mounted) return;
      _showMessage('No pudimos confirmar el inicio. Probá de nuevo.');
    }
  }

  Future<void> _confirmDelivery(Sale sale) async {
    try {
      await _repository.confirmDelivery(sale.transaction.id);
      if (!mounted) return;
      _showMessage('Listo, ya confirmaste la entrega.');
      await _load(showSpinner: false);
    } on ApiException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
      await _load(showSpinner: false);
    } catch (_) {
      if (!mounted) return;
      _showMessage('No pudimos confirmar la entrega. Probá de nuevo.');
    }
  }

  Future<void> _cancel(Sale sale) async {
    final String? reason = await showDialog<String>(
      context: context,
      builder: (_) => const _CancelDialog(),
    );
    if (reason == null || !mounted) return;
    try {
      await _repository.cancel(sale.transaction.id, reason);
      if (!mounted) return;
      _showMessage('Listo, cancelamos el trato.');
      await _load(showSpinner: false);
    } on ApiException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
      await _load(showSpinner: false);
    } catch (_) {
      if (!mounted) return;
      _showMessage('No pudimos cancelar el trato. Probá de nuevo.');
    }
  }

  Future<void> _rate(Sale sale) async {
    final ({int rating, String comment})? answer =
        await showModalBottomSheet<({int rating, String comment})>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.lg),
            ),
          ),
          builder: (_) => _RatingSheet(
            buyerName: sale.buyerName.isEmpty ? 'el comprador' : sale.buyerName,
          ),
        );
    if (answer == null || !mounted) return;
    try {
      final String buyerId = await _resolveBuyerId(sale);
      if (buyerId.isEmpty) {
        if (!mounted) return;
        _showMessage('No pudimos encontrar al comprador. Probá más tarde.');
        return;
      }
      await _reviewRepository.rate(
        transactionId: sale.transaction.id,
        targetId: buyerId,
        rating: answer.rating,
        comment: answer.comment,
      );
      if (!mounted) return;
      setState(() {
        _ratedTransactionIds = <String>{
          ..._ratedTransactionIds,
          sale.transaction.id,
        };
      });
      _showMessage('¡Gracias! Ya sabemos cómo te fue.');
    } on ApiException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('No pudimos enviar tu respuesta. Probá de nuevo.');
    }
  }

  Future<void> _report(Sale sale) async {
    try {
      final String buyerId = await _resolveBuyerId(sale);
      if (buyerId.isEmpty) {
        if (!mounted) return;
        _showMessage('No pudimos encontrar al comprador. Probá más tarde.');
        return;
      }
      if (!mounted) return;
      await showReportDialog(
        context: context,
        targetType: 'user',
        targetId: buyerId,
        repository: _reportRepository,
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage('No pudimos abrir el reporte. Probá de nuevo.');
    }
  }

  Future<void> _openChat(Sale sale) async {
    final Conversation? conversation = _conversations[sale.transaction.matchId];
    if (conversation == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BuyerChat(
          conversationId: conversation.id,
          counterpartName: sale.buyerName.isEmpty
              ? 'El comprador'
              : sale.buyerName,
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
        title: const Text('Mis ventas', style: AppText.appBarText),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _StateMessage(
        icon: Icons.wifi_off_outlined,
        title: 'No pudimos cargar tus ventas',
        message: 'Revisá que tengas internet y volvé a intentar.',
        onRetry: () => _load(),
      );
    }
    if (_sales.isEmpty) {
      return const _StateMessage(
        icon: Icons.handshake_outlined,
        title: 'Todavía no tenés tratos',
        message: 'Cuando un comprador elija una de tus ofertas, el trato '
            'va a aparecer acá.',
      );
    }
    return RefreshIndicator(
      onRefresh: () => _load(showSpinner: false),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: _sales
            .map(
              (Sale sale) => _SaleCard(
                sale: sale,
                conversation: _conversations[sale.transaction.matchId],
                canRate:
                    sale.transaction.status == TransactionStatus.completed &&
                    !_ratedTransactionIds.contains(sale.transaction.id),
                canReport: _canReport(sale),
                onConfirmStart: () => _confirmStart(sale),
                onConfirmDelivery: () => _confirmDelivery(sale),
                onCancel: () => _cancel(sale),
                onOpenChat: () => _openChat(sale),
                onRate: () => _rate(sale),
                onReport: () => _report(sale),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _SaleCard extends StatelessWidget {
  const _SaleCard({
    required this.sale,
    required this.conversation,
    required this.canRate,
    required this.canReport,
    required this.onConfirmStart,
    required this.onConfirmDelivery,
    required this.onCancel,
    required this.onOpenChat,
    required this.onRate,
    required this.onReport,
  });

  final Sale sale;
  final Conversation? conversation;
  final bool canRate;
  final bool canReport;
  final VoidCallback onConfirmStart;
  final VoidCallback onConfirmDelivery;
  final VoidCallback onCancel;
  final VoidCallback onOpenChat;
  final VoidCallback onRate;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final Transaction transaction = sale.transaction;
    final String unit = sale.amountUnit.label;
    final String buyer = sale.buyerName.isEmpty
        ? 'El comprador'
        : sale.buyerName;
    final String product = sale.productName.isEmpty
        ? 'Tu producto'
        : sale.productName;
    final bool canStart =
        transaction.status == TransactionStatus.matched &&
        transaction.supplierStartConfirmedAt == null;
    final bool canDeliver =
        transaction.status == TransactionStatus.inProgress &&
        transaction.supplierDeliveryConfirmedAt == null;
    final bool canCancel = !transaction.status.isTerminal;
    final bool hasConversation = conversation != null;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dark.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  product,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dark,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _StatusChip(status: transaction.status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _InfoLine(icon: Icons.person_outline, text: 'Comprador: $buyer'),
          if (sale.municipality.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _InfoLine(
              icon: Icons.location_on_outlined,
              text: sale.municipality,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Cantidad: ${_quantity(sale.quantity)} $unit',
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Mi precio: ${formatPrice(sale.pricePerUnit)} por $unit',
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.blackGreen,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _Checklist(transaction: transaction),
          if (transaction.status == TransactionStatus.cancelled &&
              transaction.cancelReason.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                'Motivo: ${transaction.cancelReason}',
                style: const TextStyle(fontSize: 16, color: AppColors.dark),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          _PrimaryActionButton(
            icon: Icons.play_circle_outline,
            label: '¿Ya empezó el trato?',
            onPressed: canStart ? onConfirmStart : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          _PrimaryActionButton(
            icon: Icons.local_shipping_outlined,
            label: '¿Ya entregaste el pedido?',
            onPressed: canDeliver ? onConfirmDelivery : null,
          ),
          if (canRate) ...[
            const SizedBox(height: AppSpacing.sm),
            _PrimaryActionButton(
              icon: Icons.star_outline,
              label: 'Decir cómo te fue',
              onPressed: onRate,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 64,
            child: OutlinedButton(
              onPressed: hasConversation ? onOpenChat : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.blackGreen,
                side: BorderSide(color: AppTints.border, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 26),
                  const SizedBox(width: AppSpacing.sm),
                  const Flexible(
                    child: Text(
                      'Hablar con el comprador',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!hasConversation) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Todavía no hay un chat con este comprador.',
              textAlign: TextAlign.center,
              style: AppText.bodySecondary,
            ),
          ],
          if (canCancel) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 58,
              child: TextButton.icon(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                icon: const Icon(Icons.cancel_outlined, size: 24),
                label: const Text('Cancelar el trato'),
              ),
            ),
          ],
          if (canReport) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 58,
              child: OutlinedButton.icon(
                onPressed: onReport,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.dark,
                  side: BorderSide(color: AppTints.border, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                icon: const Icon(Icons.flag_outlined, size: 24),
                label: const Text('Reportar al comprador'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 82,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.blackGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.dark.withValues(alpha: 0.12),
          disabledForegroundColor: AppTints.muted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: AppSpacing.xs),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _Checklist extends StatelessWidget {
  const _Checklist({required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.whitemodeBackgrund,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Empezar el trato', style: AppText.sectionTitle),
          const SizedBox(height: AppSpacing.sm),
          _ChecklistRow(
            done: transaction.supplierStartConfirmedAt != null,
            text: transaction.supplierStartConfirmedAt == null
                ? 'Vos: falta que confirmes'
                : 'Vos: ya confirmaste',
          ),
          _ChecklistRow(
            done: transaction.buyerStartConfirmedAt != null,
            text: transaction.buyerStartConfirmedAt == null
                ? 'El comprador: falta que confirme'
                : 'El comprador: ya confirmó',
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Entregar el pedido', style: AppText.sectionTitle),
          const SizedBox(height: AppSpacing.sm),
          _ChecklistRow(
            done: transaction.supplierDeliveryConfirmedAt != null,
            text: transaction.supplierDeliveryConfirmedAt == null
                ? 'Vos: falta que confirmes'
                : 'Vos: ya confirmaste',
          ),
          _ChecklistRow(
            done: transaction.buyerDeliveryConfirmedAt != null,
            text: transaction.buyerDeliveryConfirmedAt == null
                ? 'El comprador: falta que confirme'
                : 'El comprador: ya confirmó',
          ),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.done, required this.text});

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
            size: 22,
            color: done ? AppColors.blackGreen : AppTints.muted,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 17, color: AppColors.dark),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final TransactionStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color background, Color foreground) = switch (status) {
      TransactionStatus.matched => (
        AppColors.whiteGreen.withValues(alpha: 0.2),
        AppColors.blackGreen,
      ),
      TransactionStatus.inProgress => (
        AppColors.yelow.withValues(alpha: 0.35),
        AppColors.dark,
      ),
      TransactionStatus.completed => (
        AppColors.blackGreen.withValues(alpha: 0.12),
        AppColors.blackGreen,
      ),
      TransactionStatus.cancelled => (
        Colors.red.withValues(alpha: 0.1),
        Colors.red.shade700,
      ),
      TransactionStatus.unknown => (
        AppColors.dark.withValues(alpha: 0.06),
        AppTints.secondary,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        _statusText(status),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: AppTints.secondary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 18, color: AppColors.dark),
          ),
        ),
      ],
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

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
              child: Center(
                child: Icon(icon, size: 56, color: AppColors.blackGreen),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppText.screenTitle,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.dark,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.xl),
              OutlinedButton.icon(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.blackGreen,
                  minimumSize: const Size(0, 62),
                  side: const BorderSide(
                    color: AppColors.blackGreen,
                    width: 1.5,
                  ),
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
          ],
        ),
      ),
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
      title: const Text('¿Por qué no se pudo?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contale al comprador por qué cancelás el trato.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            maxLines: 3,
            autofocus: true,
            style: const TextStyle(fontSize: 17),
            decoration: const InputDecoration(hintText: 'Escribí el motivo'),
            onChanged: (_) {
              if (_showError) setState(() => _showError = false);
            },
          ),
          if (_showError) ...[
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Escribí un motivo para cancelar.',
              style: TextStyle(color: Colors.red, fontSize: 16),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Volver', style: TextStyle(fontSize: 17)),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.blackGreen,
            textStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: const Text('Cancelar el trato'),
        ),
      ],
    );
  }
}

class _RatingSheet extends StatefulWidget {
  const _RatingSheet({required this.buyerName});

  final String buyerName;

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  final TextEditingController _controller = TextEditingController();
  int _rating = 0;
  bool _sent = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_rating == 0 || _sent) return;
    _sent = true;
    Navigator.of(context).pop((rating: _rating, comment: _controller.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '¿Cómo te fue con este comprador?',
                textAlign: TextAlign.center,
                style: AppText.screenTitle,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Tu respuesta es sobre ${widget.buyerName}.',
                textAlign: TextAlign.center,
                style: AppText.body,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List<Widget>.generate(5, (int index) {
                  final int value = index + 1;
                  return IconButton(
                    key: ValueKey<String>('farmer-rate-star-$value'),
                    onPressed: () => setState(() => _rating = value),
                    iconSize: 44,
                    constraints: const BoxConstraints(
                      minWidth: 56,
                      minHeight: 56,
                    ),
                    icon: Icon(
                      value <= _rating ? Icons.star : Icons.star_border,
                      color: AppColors.yelow,
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _rating == 0
                    ? 'Tocá las estrellas para elegir'
                    : _ratingLabel(_rating),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                key: const ValueKey<String>('farmer-rate-comment'),
                controller: _controller,
                maxLines: 3,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(
                  hintText: 'Contanos qué pasó (si querés)',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 72,
                child: FilledButton.icon(
                  onPressed: _rating == 0 ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.blackGreen,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.dark.withValues(
                      alpha: 0.12,
                    ),
                    disabledForegroundColor: AppTints.muted,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  icon: const Icon(Icons.send_outlined, size: 28),
                  label: const Text('Enviar'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 56,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTints.secondary,
                    textStyle: const TextStyle(fontSize: 17),
                  ),
                  child: const Text('Volver'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _ratingLabel(int rating) => switch (rating) {
  1 => 'Muy mal',
  2 => 'Mal',
  3 => 'Más o menos',
  4 => 'Bien',
  _ => 'Muy bien',
};

String _statusText(TransactionStatus status) => switch (status) {
  TransactionStatus.matched => 'Acordado',
  TransactionStatus.inProgress => 'En camino',
  TransactionStatus.completed => 'Entregado',
  TransactionStatus.cancelled => 'Cancelado',
  TransactionStatus.unknown => 'Sin novedad',
};

String _quantity(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toString();
}

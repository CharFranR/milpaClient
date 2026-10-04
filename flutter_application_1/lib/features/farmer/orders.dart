import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/core/token_store.dart';
import 'package:flutter_application_1/features/buyer/catalog_models.dart';
import 'package:flutter_application_1/features/farmer/offer_form.dart';
import 'package:flutter_application_1/features/farmer/order_models.dart';
import 'package:flutter_application_1/features/farmer/order_repository.dart';
import 'package:flutter_application_1/ui/app_tokens.dart';

enum _OrdersView { requests, offers }

class FarmerOrdersPage extends StatefulWidget {
  const FarmerOrdersPage({super.key, this.repository});

  final OrderRepository? repository;

  @override
  State<FarmerOrdersPage> createState() => _FarmerOrdersPageState();
}

class _FarmerOrdersPageState extends State<FarmerOrdersPage> {
  late final OrderRepository _repository =
      widget.repository ??
      OrderRepository(apiClient: ApiClient(), tokenStore: TokenStore());

  _OrdersView _view = _OrdersView.requests;

  List<AvailableRequest> _requests = <AvailableRequest>[];
  bool _requestsLoading = true;
  Object? _requestsError;

  List<MyOffer> _offers = <MyOffer>[];
  bool _offersLoading = true;
  Object? _offersError;

  @override
  void initState() {
    super.initState();
    _loadRequests();
    _loadOffers();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _requestsLoading = true;
      _requestsError = null;
    });
    try {
      final List<AvailableRequest> requests = await _repository.fetchAvailable();
      if (!mounted) return;
      setState(() {
        _requests = requests;
        _requestsLoading = false;
        _requestsError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _requestsLoading = false;
        _requestsError = error;
      });
    }
  }

  Future<void> _loadOffers() async {
    setState(() {
      _offersLoading = true;
      _offersError = null;
    });
    try {
      final List<MyOffer> offers = await _repository.fetchMyOffers();
      if (!mounted) return;
      setState(() {
        _offers = offers;
        _offersLoading = false;
        _offersError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _offersLoading = false;
        _offersError = error;
      });
    }
  }

  Future<void> _openOfferForm(AvailableRequest request) async {
    final bool? sent = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => OfferFormPage(request: request, repository: _repository),
      ),
    );
    if (sent != true || !mounted) return;
    await _loadRequests();
    await _loadOffers();
    if (!mounted) return;
    _showMessage('Tu oferta ya está enviada. Te avisamos si te eligen.');
  }

  Future<void> _editOffer(MyOffer offer) async {
    final bool? sent = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => OfferFormPage(offer: offer, repository: _repository),
      ),
    );
    if (sent != true || !mounted) return;
    await _loadOffers();
    if (!mounted) return;
    _showMessage('Ya cambiamos tu oferta. Te avisamos si te eligen.');
  }

  Future<void> _withdraw(MyOffer offer) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('¿Querés retirar tu oferta?'),
        content: const Text('El comprador ya no la va a ver.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.blackGreen,
            ),
            child: const Text('Sí, retirar mi oferta'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _repository.withdrawOffer(offer.id);
      if (!mounted) return;
      await _loadOffers();
      await _loadRequests();
      if (!mounted) return;
      _showMessage('Listo. Retiramos tu oferta.');
    } catch (error) {
      if (!mounted) return;
      _showMessage(_withdrawErrorMessage(error));
    }
  }

  String _withdrawErrorMessage(Object error) {
    if (error is ApiException) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        return 'No pudimos retirarla. Volvé a entrar.';
      }
      return 'No pudimos retirar tu oferta. Probá de nuevo.';
    }
    if (error is NetworkException) return error.message;
    return 'No pudimos retirar tu oferta. Probá de nuevo.';
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Text('Pedidos', style: AppText.screenTitle),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: _ViewSwitch(
            view: _view,
            onChanged: (_OrdersView view) => setState(() => _view = view),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: _view == _OrdersView.requests
              ? _requestsContent()
              : _offersContent(),
        ),
      ],
    );
  }

  Widget _requestsContent() {
    if (_requestsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_requestsError != null) {
      return _MessageState(
        icon: Icons.wifi_off_outlined,
        title: 'No pudimos cargar los pedidos',
        message: 'Revisá que tengas internet y volvé a intentar.',
        onRetry: _loadRequests,
      );
    }
    if (_requests.isEmpty) {
      return const _MessageState(
        icon: Icons.receipt_long_outlined,
        title: 'Ahora no hay pedidos',
        message: 'Ningún comprador publicó un pedido en este momento. '
            'Volvé a mirar más tarde.',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        children: _requests.map(_requestCard).toList(),
      ),
    );
  }

  Widget _offersContent() {
    if (_offersLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_offersError != null) {
      return _MessageState(
        icon: Icons.wifi_off_outlined,
        title: 'No pudimos cargar tus ofertas',
        message: 'Revisá que tengas internet y volvé a intentar.',
        onRetry: _loadOffers,
      );
    }
    if (_offers.isEmpty) {
      return const _MessageState(
        icon: Icons.local_offer_outlined,
        title: 'Todavía no ofertaste',
        message: 'Mirá los pedidos de los compradores y ofertá al que te '
            'sirva.',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadOffers,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        children: _offers.map(_offerCard).toList(),
      ),
    );
  }

  Widget _requestCard(AvailableRequest request) {
    final String unit = request.amountUnit.label;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dark.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            request.productName.isEmpty
                ? 'Pedido de un comprador'
                : request.productName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Cantidad pedida: ${_quantity(request.totalAmount)} $unit',
            style: AppText.body,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Falta cubrir: ${_quantity(request.actualAmount)} $unit',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.blackGreen,
            ),
          ),
          if (request.minAmountPerProvider > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Pide al menos: ${_quantity(request.minAmountPerProvider)} '
              '$unit',
              style: AppText.body,
            ),
          ],
          if (request.location.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _DetailLine(
              icon: Icons.location_on_outlined,
              text: request.location,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          _DetailLine(
            icon: Icons.event_outlined,
            text: _deadlinePhrase(
              request.requestDeadline,
              request.deliveryDeadline,
            ),
          ),
          if (request.description.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(request.description.trim(), style: AppText.bodySecondary),
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 62,
            child: FilledButton.icon(
              onPressed: () => _openOfferForm(request),
              style: _primaryButtonStyle,
              icon: const Icon(Icons.local_offer_outlined, size: 26),
              label: const Text('Ofertar'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _offerCard(MyOffer offer) {
    final String unit = offer.measurement.label;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dark.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            offer.productName.isEmpty
                ? 'Pedido de un comprador'
                : offer.productName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _OfferStatusChip(status: offer.status),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Mi precio: ${formatPrice(offer.pricePerUnit)} por $unit',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.blackGreen,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Cantidad ofrecida: ${_quantity(offer.totalAmount)} $unit',
            style: AppText.body,
          ),
          if (offer.comments.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(offer.comments.trim(), style: AppText.bodySecondary),
          ],
          if (offer.status.isWaiting) ...[
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 62,
              child: FilledButton.icon(
                onPressed: () => _editOffer(offer),
                style: _primaryButtonStyle,
                icon: const Icon(Icons.edit_outlined, size: 26),
                label: const Text('Cambiar mi oferta'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 54,
              child: OutlinedButton.icon(
                onPressed: () => _withdraw(offer),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.blackGreen,
                  side: BorderSide(color: AppTints.border, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                icon: const Icon(Icons.undo, size: 24),
                label: const Text('Retirar mi oferta'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _deadlinePhrase(String? requestDeadline, String? deliveryDeadline) {
    final DateTime? raw =
        DateTime.tryParse(requestDeadline ?? '') ??
        DateTime.tryParse(deliveryDeadline ?? '');
    if (raw == null) return 'Sin fecha límite';
    final DateTime today = DateUtils.dateOnly(DateTime.now());
    final DateTime target = DateUtils.dateOnly(raw.toLocal());
    final int days = target.difference(today).inDays;
    if (days <= 0) return 'Lo necesitan para hoy';
    if (days == 1) return 'Lo necesitan para mañana';
    return 'Lo necesitan hasta el ${_date(target)}';
  }

  String _date(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _quantity(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }

  ButtonStyle get _primaryButtonStyle => FilledButton.styleFrom(
    backgroundColor: AppColors.blackGreen,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    textStyle: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
  );
}

class _ViewSwitch extends StatelessWidget {
  const _ViewSwitch({required this.view, required this.onChanged});

  final _OrdersView view;
  final ValueChanged<_OrdersView> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _option(
            _OrdersView.requests,
            Icons.receipt_long_outlined,
            'Pedidos de compradores',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _option(
            _OrdersView.offers,
            Icons.local_offer_outlined,
            'Mis ofertas',
          ),
        ),
      ],
    );
  }

  Widget _option(_OrdersView target, IconData icon, String label) {
    final bool selected = view == target;
    final Color background = selected ? AppColors.blackGreen : Colors.white;
    final Color foreground = selected ? Colors.white : AppColors.dark;
    final Color iconColor = selected ? Colors.white : AppColors.blackGreen;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: () => onChanged(target),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? AppColors.blackGreen : AppTints.border,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: iconColor),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfferStatusChip extends StatelessWidget {
  const _OfferStatusChip({required this.status});

  final OfferStatus status;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color background, Color foreground) = switch (status) {
      OfferStatus.active => (
        Icons.hourglass_empty,
        AppColors.yelow.withValues(alpha: 0.35),
        AppColors.dark,
      ),
      OfferStatus.matched => (
        Icons.check_circle_outline,
        AppColors.whiteGreen.withValues(alpha: 0.22),
        AppColors.blackGreen,
      ),
      OfferStatus.rejected => (
        Icons.cancel_outlined,
        Colors.red.withValues(alpha: 0.1),
        Colors.red.shade700,
      ),
      OfferStatus.withdrawn => (
        Icons.undo,
        AppColors.dark.withValues(alpha: 0.08),
        AppTints.secondary,
      ),
      OfferStatus.unknown => (
        Icons.help_outline,
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: foreground),
          const SizedBox(width: AppSpacing.sm),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTints.secondary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 16, color: AppColors.dark)),
        ),
      ],
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
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

import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/token_store.dart';
import 'package:flutter_application_1/features/auth/session_controller.dart';
import 'package:flutter_application_1/features/buyer/catalog_models.dart';
import 'package:flutter_application_1/features/buyer/liquidation_models.dart';
import 'package:flutter_application_1/features/farmer/lot_detail.dart';
import 'package:flutter_application_1/features/farmer/lot_form.dart';
import 'package:flutter_application_1/features/farmer/lot_repository.dart';
import 'package:flutter_application_1/ui/app_tokens.dart';

class FarmerLotsPage extends StatefulWidget {
  const FarmerLotsPage({super.key, this.repository});

  final LotRepository? repository;

  @override
  State<FarmerLotsPage> createState() => _FarmerLotsPageState();
}

class _FarmerLotsPageState extends State<FarmerLotsPage> {
  late final LotRepository _repository =
      widget.repository ??
      LotRepository(apiClient: ApiClient(), tokenStore: TokenStore());

  String _supplierId = '';
  List<Liquidation> _lots = <Liquidation>[];
  bool _loading = true;
  Object? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final String supplierId = SessionScope.of(context).user?.id ?? '';
    if (supplierId.isNotEmpty && supplierId != _supplierId) {
      _supplierId = supplierId;
      _load();
    }
  }

  Future<void> _load() async {
    if (_supplierId.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<Liquidation> lots = await _repository.fetchMine(_supplierId);
      if (!mounted) return;
      setState(() {
        _lots = lots;
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

  Future<void> _openForm() async {
    final bool? published = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => LotFormPage(repository: _repository),
      ),
    );
    if (published != true || !mounted) return;
    await _load();
    if (!mounted) return;
    _showMessage('Listo. Los compradores ya pueden ver tu lote.');
  }

  Future<void> _openDetail(Liquidation lot) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            FarmerLotDetailPage(liquidation: lot, repository: _repository),
      ),
    );
    if (!mounted) return;
    await _load();
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
        title: const Text('Mis lotes', style: AppText.appBarText),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _content()),
            _publishButton(),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _StateMessage(
        icon: Icons.wifi_off_outlined,
        title: 'No pudimos cargar tus lotes',
        message: 'Revisá que tengas internet y volvé a intentar.',
        onRetry: _load,
      );
    }
    if (_lots.isEmpty) {
      return const _StateMessage(
        icon: Icons.inventory_2_outlined,
        title: 'Todavía no tenés lotes',
        message:
            'Publicá un lote completo con descuento y los compradores lo '
            'van a poder ver.',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        children: _lots.map(_lotCard).toList(),
      ),
    );
  }

  Widget _lotCard(Liquidation lot) {
    final String unit = lot.unitOfMeasure;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dark.withValues(alpha: 0.06)),
      ),
      child: InkWell(
        onTap: () => _openDetail(lot),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(lot.productName, style: AppText.headline),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _StatusBadge(status: lot.status),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Cantidad: ${_quantity(lot.quantity)}${unit.isEmpty ? '' : ' $unit'}',
                style: const TextStyle(fontSize: 19, color: AppColors.dark),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'En total: ${formatPrice(lot.totalPrice)}',
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blackGreen,
                ),
              ),
              Text(
                'Precio por unidad: ${formatPrice(lot.unitPrice)}${unit.isEmpty ? '' : ' por $unit'}',
                style: AppText.body,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.groups_outlined,
                    size: 22,
                    color: AppTints.secondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Lo pueden ver: ${_audienceText(lot.visibility)}',
                      style: const TextStyle(
                        fontSize: 17,
                        color: AppColors.dark,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 26, color: AppTints.hint),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _publishButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: SizedBox(
        height: 62,
        child: FilledButton.icon(
          onPressed: _openForm,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.blackGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            textStyle: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          icon: const Icon(Icons.add_circle_outline, size: 28),
          label: const Text('Publicar un lote'),
        ),
      ),
    );
  }
}

String _quantity(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toString();
}

String _audienceText(LiquidationVisibility visibility) =>
    visibility == LiquidationVisibility.unknown
    ? 'No sabemos quién puede verlo'
    : visibility.label;

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final LiquidationStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color background, Color foreground) = switch (status) {
      LiquidationStatus.open => (
        AppColors.whiteGreen.withValues(alpha: 0.2),
        AppColors.blackGreen,
      ),
      LiquidationStatus.assigned => (
        AppColors.blackGreen.withValues(alpha: 0.12),
        AppColors.blackGreen,
      ),
      LiquidationStatus.expired => (
        Colors.orange.withValues(alpha: 0.15),
        Colors.orange.shade800,
      ),
      LiquidationStatus.closed => (
        AppColors.dark.withValues(alpha: 0.08),
        AppTints.secondary,
      ),
      LiquidationStatus.unknown => (
        AppColors.dark.withValues(alpha: 0.06),
        AppTints.secondary,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        _statusText(status),
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

String _statusText(LiquidationStatus status) => switch (status) {
  LiquidationStatus.open => 'Disponible',
  LiquidationStatus.assigned => 'Asignado',
  LiquidationStatus.closed => 'Cerrado',
  LiquidationStatus.expired => 'Vencido',
  LiquidationStatus.unknown => 'Sin estado',
};

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
            Text(message, textAlign: TextAlign.center, style: AppText.body),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.xl),
              OutlinedButton.icon(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.blackGreen,
                  minimumSize: const Size(0, 56),
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

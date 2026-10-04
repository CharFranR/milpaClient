import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/token_store.dart';
import 'package:flutter_application_1/features/buyer/catalog_models.dart';
import 'package:flutter_application_1/features/buyer/liquidation_detail.dart';
import 'package:flutter_application_1/features/buyer/liquidation_models.dart';
import 'package:flutter_application_1/features/buyer/liquidation_repository.dart';
import 'package:flutter_application_1/ui/app_tokens.dart';

class LiquidationsPage extends StatefulWidget {
  const LiquidationsPage({super.key, this.repository});

  final LiquidationRepository? repository;

  @override
  State<LiquidationsPage> createState() => _LiquidationsPageState();
}

class _LiquidationsPageState extends State<LiquidationsPage> {
  late final LiquidationRepository _repository =
      widget.repository ??
      LiquidationRepository(apiClient: ApiClient(), tokenStore: TokenStore());

  List<Liquidation> _liquidations = <Liquidation>[];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final List<Liquidation> liquidations = await _repository.fetchOpen();
      if (!mounted) return;
      setState(() {
        _liquidations = liquidations;
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

  Future<void> _openDetail(Liquidation liquidation) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LiquidationDetailPage(
          liquidation: liquidation,
          repository: _repository,
        ),
      ),
    );
  }

  String _quantity(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whitemodeBackgrund,
      appBar: AppBar(
        backgroundColor: AppColors.blackGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Lotes disponibles', style: AppText.appBarText),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No se pudieron cargar los lotes'),
            TextButton(onPressed: _load, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
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
            if (_liquidations.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                child: Column(
                  children: [
                    Text(
                      'Todavía no hay lotes disponibles',
                      textAlign: TextAlign.center,
                      style: AppText.label,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Cuando un agricultor publique su excedente, lo vas a ver acá para mostrar tu interés.',
                      textAlign: TextAlign.center,
                      style: AppText.bodySecondary,
                    ),
                  ],
                ),
              )
            else
              ..._liquidations.map(_liquidationCard),
          ],
        ),
      ),
    );
  }

  Widget _liquidationCard(Liquidation liquidation) {
    final String unit = liquidation.unitOfMeasure;
    final String? deliveryTime = liquidation.deliveryTime;
    final String? expiresAt = liquidation.expiresAt;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dark.withValues(alpha: 0.06)),
      ),
      child: InkWell(
        onTap: () => _openDetail(liquidation),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(liquidation.productName, style: AppText.label),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _VisibilityBadge(visibility: liquidation.visibility),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                formatPrice(liquidation.totalPrice),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blackGreen,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Cantidad: ${_quantity(liquidation.quantity)}${unit.isEmpty ? '' : ' $unit'}',
                style: AppText.body,
              ),
              Text(
                'Precio unitario: ${formatPrice(liquidation.unitPrice)}${unit.isEmpty ? '' : ' por $unit'}',
                style: AppText.body,
              ),
              if (deliveryTime != null && deliveryTime.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                _DetailLine(
                  icon: Icons.local_shipping_outlined,
                  text: 'Entrega: $deliveryTime',
                ),
              ],
              if (expiresAt != null) ...[
                const SizedBox(height: AppSpacing.xs),
                _DetailLine(
                  icon: Icons.event_outlined,
                  text: 'Vence: ${_formatDate(expiresAt)}',
                ),
              ],
            ],
          ),
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

class _VisibilityBadge extends StatelessWidget {
  const _VisibilityBadge({required this.visibility});

  final LiquidationVisibility visibility;

  @override
  Widget build(BuildContext context) {
    final (Color background, Color foreground) = switch (visibility) {
      LiquidationVisibility.public => (
        AppColors.whiteGreen.withValues(alpha: 0.2),
        AppColors.blackGreen,
      ),
      LiquidationVisibility.wholesale => (
        AppColors.yelow.withValues(alpha: 0.5),
        AppColors.dark,
      ),
      LiquidationVisibility.wholesaleRetail ||
      LiquidationVisibility.wholesaleCorporate => (
        AppColors.dark.withValues(alpha: 0.08),
        AppColors.dark,
      ),
      LiquidationVisibility.unknown => (
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
        visibility.label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
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
        Icon(icon, size: 17, color: AppTints.secondary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text, style: AppText.bodySecondary)),
      ],
    );
  }
}

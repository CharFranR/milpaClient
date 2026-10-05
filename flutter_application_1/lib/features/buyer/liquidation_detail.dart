import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/core/token_store.dart';
import 'package:flutter_application_1/features/buyer/catalog_models.dart';
import 'package:flutter_application_1/features/buyer/liquidation_models.dart';
import 'package:flutter_application_1/features/buyer/liquidation_repository.dart';
import 'package:flutter_application_1/ui/app_tokens.dart';

class LiquidationDetailPage extends StatefulWidget {
  const LiquidationDetailPage({
    super.key,
    required this.liquidation,
    this.repository,
  });

  final Liquidation liquidation;
  final LiquidationRepository? repository;

  @override
  State<LiquidationDetailPage> createState() => _LiquidationDetailPageState();
}

class _LiquidationDetailPageState extends State<LiquidationDetailPage> {
  late final LiquidationRepository _repository =
      widget.repository ??
      LiquidationRepository(apiClient: ApiClient(), tokenStore: TokenStore());

  late Liquidation _liquidation = widget.liquidation;
  bool _sending = false;
  bool _interested = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final Liquidation liquidation = await _repository.fetchById(
        widget.liquidation.id,
      );
      if (!mounted) return;
      setState(() => _liquidation = liquidation);
    } on ApiException {
      return;
    } catch (_) {
      return;
    }
  }

  Future<void> _expressInterest() async {
    if (_sending || _interested) return;
    setState(() => _sending = true);
    try {
      await _repository.expressInterest(_liquidation.id);
      if (!mounted) return;
      setState(() => _interested = true);
      _showMessage('Listo, ya marcaste tu interés');
      await _refresh();
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.statusCode == 409) {
        setState(() => _interested = true);
        _showMessage('Ya habías mostrado interés en este lote');
        await _refresh();
      } else {
        _showMessage('No se pudo completar la acción. Intenta de nuevo.');
      }
    } catch (error) {
      if (!mounted) return;
      _showMessage('No se pudo completar la acción. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  String _quantity(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final Liquidation liquidation = _liquidation;
    final String unit = liquidation.unitOfMeasure;
    final String? deliveryTime = liquidation.deliveryTime;
    final String? expiresAt = liquidation.expiresAt;
    return Scaffold(
      backgroundColor: AppColors.whitemodeBackgrund,
      appBar: AppBar(
        backgroundColor: AppColors.blackGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Lote disponible', style: AppText.appBarText),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.dark.withValues(alpha: 0.06),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          liquidation.productName,
                          style: AppText.headline,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _VisibilityBadge(visibility: liquidation.visibility),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    formatPrice(liquidation.totalPrice),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blackGreen,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Cantidad: ${_quantity(liquidation.quantity)}${unit.isEmpty ? '' : ' $unit'}',
                    style: AppText.body,
                  ),
                  Text(
                    'Precio unitario: ${formatPrice(liquidation.unitPrice)}${unit.isEmpty ? '' : ' por $unit'}',
                    style: AppText.body,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _DetailLine(
                    icon: Icons.verified_outlined,
                    text: 'Visibilidad: ${liquidation.visibility.label}',
                  ),
                  if (deliveryTime != null && deliveryTime.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
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
                  const SizedBox(height: AppSpacing.xs),
                  _DetailLine(
                    icon: Icons.groups_outlined,
                    text: 'Asignación: ${liquidation.allocationMethod.label}',
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _DetailLine(
                    icon: Icons.event_available_outlined,
                    text: 'Estado: ${liquidation.status.label}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (!liquidation.isOpen)
              Text(
                'Este lote ya no está disponible para mostrar interés.',
                textAlign: TextAlign.center,
                style: AppText.bodySecondary,
              )
            else if (_interested)
              Text(
                'Ya marcaste tu interés. El agricultor va a elegir a quién asignarle el lote.',
                textAlign: TextAlign.center,
                style: AppText.bodySecondary,
              )
            else
              SizedBox(
                height: 52,
                child: TextButton(
                  onPressed: _sending ? null : _expressInterest,
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.blackGreen,
                    disabledBackgroundColor: AppColors.dark.withValues(
                      alpha: 0.12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: _sending
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Me interesa', style: AppText.button),
                ),
              ),
          ],
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

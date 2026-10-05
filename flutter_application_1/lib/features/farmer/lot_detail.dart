import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/core/token_store.dart';
import 'package:flutter_application_1/features/buyer/catalog_models.dart';
import 'package:flutter_application_1/features/buyer/liquidation_models.dart';
import 'package:flutter_application_1/features/farmer/lot_models.dart';
import 'package:flutter_application_1/features/farmer/lot_repository.dart';
import 'package:flutter_application_1/ui/app_tokens.dart';

class FarmerLotDetailPage extends StatefulWidget {
  const FarmerLotDetailPage({
    super.key,
    required this.liquidation,
    this.repository,
  });

  final Liquidation liquidation;
  final LotRepository? repository;

  @override
  State<FarmerLotDetailPage> createState() => _FarmerLotDetailPageState();
}

class _FarmerLotDetailPageState extends State<FarmerLotDetailPage> {
  late final LotRepository _repository =
      widget.repository ??
      LotRepository(apiClient: ApiClient(), tokenStore: TokenStore());

  late Liquidation _liquidation = widget.liquidation;
  List<InterestedBuyer> _interests = <InterestedBuyer>[];
  bool _interestsLoading = true;
  Object? _interestsError;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _interestsLoading = true;
      _interestsError = null;
    });
    try {
      final Liquidation liquidation = await _repository.fetchById(
        _liquidation.id,
      );
      if (!mounted) return;
      setState(() => _liquidation = liquidation);
    } catch (_) {
      if (!mounted) return;
    }
    try {
      final List<InterestedBuyer> interests = await _repository.fetchInterests(
        _liquidation.id,
      );
      if (!mounted) return;
      setState(() {
        _interests = interests;
        _interestsLoading = false;
        _interestsError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _interestsLoading = false;
        _interestsError = error;
      });
    }
  }

  Future<void> _assign(InterestedBuyer buyer) async {
    final String name = _buyerName(buyer);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text('¿Le das el lote a $name?'),
        content: const Text(
          'El lote va a quedar para esta persona. Después no se puede cambiar.',
        ),
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
            child: const Text('Sí, darle el lote'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _runAssignment(
      () => _repository.assign(_liquidation.id, buyerId: buyer.buyerId),
    );
  }

  Future<void> _assignFirstCome() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('¿Le das el lote al primero que preguntó?'),
        content: const Text(
          'Le va a quedar al que preguntó primero. Después no se puede cambiar.',
        ),
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
            child: const Text('Sí, darle el lote'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _runAssignment(() => _repository.assign(_liquidation.id));
  }

  Future<void> _runAssignment(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      _showMessage('Listo. El lote ya está dado.');
      await _refresh();
    } on ApiException catch (error) {
      if (!mounted) return;
      _showMessage(
        error.statusCode == 409
            ? 'Ese lote ya no se puede dar.'
            : 'No pudimos darlo. Probá de nuevo.',
      );
      await _refresh();
    } catch (_) {
      if (!mounted) return;
      _showMessage('No pudimos darlo. Probá de nuevo.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changeVisibility() async {
    final LiquidationVisibility? selected =
        await showDialog<LiquidationVisibility>(
          context: context,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: const Text('¿Quién puede verlo?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _audiences
                  .map(
                    (LiquidationVisibility audience) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.of(dialogContext).pop(audience),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.blackGreen,
                          minimumSize: const Size(0, 56),
                          side: const BorderSide(color: AppColors.blackGreen),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: Text(audience.label),
                      ),
                    ),
                  )
                  .toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Volver'),
              ),
            ],
          ),
        );
    if (selected == null || !mounted) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('¿Seguro que lo dejamos así?'),
        content: Text('Lo van a poder ver: ${selected.label}.'),
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
            child: const Text('Sí, cambiarlo'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await _repository.updateVisibility(_liquidation.id, selected);
      if (!mounted) return;
      _showMessage('Listo. Cambiamos quién puede verlo.');
      await _refresh();
    } catch (_) {
      if (!mounted) return;
      _showMessage('No pudimos cambiarlo. Probá de nuevo.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('¿Borrás el lote?'),
        content: const Text('Se borra para siempre y no se puede recuperar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sí, borrar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await _repository.remove(_liquidation.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      _showMessage('No pudimos borrarlo. Probá de nuevo.');
      setState(() => _busy = false);
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final Liquidation lot = _liquidation;
    final String unit = lot.unitOfMeasure;
    return Scaffold(
      backgroundColor: AppColors.whitemodeBackgrund,
      appBar: AppBar(
        backgroundColor: AppColors.blackGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Tu lote', style: AppText.appBarText),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _lotCard(lot, unit),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Quiénes están interesados',
                style: AppText.screenTitle,
              ),
              const SizedBox(height: AppSpacing.sm),
              _interestsSection(lot),
              const SizedBox(height: AppSpacing.lg),
              if (lot.isOpen) ..._openActions(lot) else _closedMessage(lot),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lotCard(Liquidation lot, String unit) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
              Expanded(child: Text(lot.productName, style: AppText.headline)),
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
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.blackGreen,
            ),
          ),
          Text(
            'Precio por unidad: ${formatPrice(lot.unitPrice)}${unit.isEmpty ? '' : ' por $unit'}',
            style: AppText.body,
          ),
          const SizedBox(height: AppSpacing.sm),
          _DetailLine(
            icon: Icons.groups_outlined,
            text: 'Lo pueden ver: ${_audienceText(lot.visibility)}',
          ),
          _DetailLine(
            icon: Icons.handshake_outlined,
            text: _allocationText(lot.allocationMethod),
          ),
          if (lot.expiresAt != null)
            _DetailLine(
              icon: Icons.event_outlined,
              text: 'Vence: ${_formatDate(lot.expiresAt)}',
            ),
        ],
      ),
    );
  }

  Widget _interestsSection(Liquidation lot) {
    if (_interestsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_interestsError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'No pudimos ver quién está interesado.',
            style: AppText.bodySecondary,
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: _refresh,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.blackGreen,
              minimumSize: const Size(0, 54),
              side: const BorderSide(color: AppColors.blackGreen, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              textStyle: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            icon: const Icon(Icons.refresh, size: 24),
            label: const Text('Volver a intentar'),
          ),
        ],
      );
    }
    if (_interests.isEmpty) {
      return Text(
        lot.isOpen
            ? 'Todavía no hay nadie interesado.'
            : 'Nadie mostró interés en este lote.',
        style: AppText.body,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _interests
          .map((InterestedBuyer buyer) => _interestCard(lot, buyer))
          .toList(),
    );
  }

  Widget _interestCard(Liquidation lot, InterestedBuyer buyer) {
    final String name = _buyerName(buyer);
    final bool canAssign =
        lot.isOpen && lot.allocationMethod == AllocationMethod.manual;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
              Icon(Icons.person_outline, size: 26, color: AppTints.secondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppText.label),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Preguntó el ${_formatDate(buyer.createdAt)}',
                      style: AppText.bodySecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (canAssign) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 62,
              child: FilledButton.icon(
                onPressed: _busy ? null : () => _assign(buyer),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.blackGreen,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.dark.withValues(
                    alpha: 0.12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                icon: const Icon(Icons.check_circle_outline, size: 26),
                label: Text(
                  'Darle el lote a $name',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _openActions(Liquidation lot) {
    return <Widget>[
      if (lot.allocationMethod == AllocationMethod.firstCome)
        SizedBox(
          height: 68,
          child: FilledButton.icon(
            onPressed: (_busy || _interests.isEmpty) ? null : _assignFirstCome,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.blackGreen,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.dark.withValues(alpha: 0.12),
              disabledForegroundColor: AppTints.muted,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            icon: const Icon(Icons.emoji_people_outlined, size: 26),
            label: const Text(
              'Darle el lote al primero que preguntó',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      const SizedBox(height: AppSpacing.md),
      SizedBox(
        height: 58,
        child: OutlinedButton.icon(
          onPressed: _busy ? null : _changeVisibility,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.blackGreen,
            side: const BorderSide(color: AppColors.blackGreen, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            textStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          icon: const Icon(Icons.visibility_outlined, size: 24),
          label: const Text('Cambiar quién puede verlo'),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      SizedBox(
        height: 58,
        child: TextButton.icon(
          onPressed: _busy ? null : _delete,
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
            textStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          icon: const Icon(Icons.delete_outline, size: 24),
          label: const Text('Borrar el lote'),
        ),
      ),
    ];
  }

  Widget _closedMessage(Liquidation lot) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.dark.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        _closedSentence(lot),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.dark,
        ),
      ),
    );
  }

  String _closedSentence(Liquidation lot) => switch (lot.status) {
    LiquidationStatus.assigned => 'Este lote ya es de ${_assignedName(lot)}.',
    LiquidationStatus.expired => 'Este lote venció. Ya no se puede dar.',
    LiquidationStatus.closed =>
      'Este lote ya está cerrado. Ya no se puede dar.',
    _ => 'Este lote ya no está disponible.',
  };

  String _assignedName(Liquidation lot) {
    for (final InterestedBuyer buyer in _interests) {
      if (buyer.buyerId == lot.assignedBuyerId) return _buyerName(buyer);
    }
    return 'un comprador';
  }

  String _buyerName(InterestedBuyer buyer) =>
      buyer.buyerName.trim().isEmpty ? 'este comprador' : buyer.buyerName;
}

const List<LiquidationVisibility> _audiences = <LiquidationVisibility>[
  LiquidationVisibility.public,
  LiquidationVisibility.wholesale,
  LiquidationVisibility.wholesaleRetail,
  LiquidationVisibility.wholesaleCorporate,
];

String _quantity(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toString();
}

String _audienceText(LiquidationVisibility visibility) =>
    visibility == LiquidationVisibility.unknown
    ? 'No sabemos quién puede verlo'
    : visibility.label;

String _allocationText(AllocationMethod method) => switch (method) {
  AllocationMethod.manual => 'Vos elegís a quién dárselo',
  AllocationMethod.firstCome => 'Se lo das al primero que pregunta',
  AllocationMethod.unknown => 'No sabemos a quién dárselo',
};

String _statusText(LiquidationStatus status) => switch (status) {
  LiquidationStatus.open => 'Disponible',
  LiquidationStatus.assigned => 'Asignado',
  LiquidationStatus.closed => 'Cerrado',
  LiquidationStatus.expired => 'Vencido',
  LiquidationStatus.unknown => 'Sin estado',
};

String _formatDate(String? value) {
  final DateTime? date = DateTime.tryParse(value ?? '');
  if (date == null) return 'sin fecha';
  final String day = date.day.toString().padLeft(2, '0');
  final String month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: AppTints.secondary),
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

import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/token_store.dart';
import 'package:flutter_application_1/features/buyer/request_offers.dart';
import 'package:flutter_application_1/features/buyer/supply_request_form.dart';
import 'package:flutter_application_1/features/buyer/supply_request_models.dart';
import 'package:flutter_application_1/features/buyer/supply_request_repository.dart';
import 'package:flutter_application_1/ui/app_tokens.dart';

bool canPublishSupplyRequests(int? role) => role == 3 || role == 4;

class SupplyRequestsPage extends StatefulWidget {
  const SupplyRequestsPage({super.key, this.repository});

  final SupplyRequestRepository? repository;

  @override
  State<SupplyRequestsPage> createState() => _SupplyRequestsPageState();
}

class _SupplyRequestsPageState extends State<SupplyRequestsPage> {
  late final SupplyRequestRepository _repository =
      widget.repository ??
      SupplyRequestRepository(apiClient: ApiClient(), tokenStore: TokenStore());

  List<SupplyRequest> _requests = <SupplyRequest>[];
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
      final List<SupplyRequest> requests = await _repository.fetchAll();
      if (!mounted) return;
      setState(() {
        _requests = requests;
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

  Future<void> _openCreate() async {
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => SupplyRequestFormPage(repository: _repository),
      ),
    );
    if (changed == true) await _load();
  }

  Future<void> _openEdit(SupplyRequest request) async {
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            SupplyRequestFormPage(request: request, repository: _repository),
      ),
    );
    if (changed == true) await _load();
  }

  Future<void> _openOffers(SupplyRequest request) async {
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RequestOffersPage(request: request),
      ),
    );
    if (changed == true) await _load();
  }

  Future<void> _cancel(SupplyRequest request) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('¿Cancelar esta solicitud?'),
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
            child: const Text('Cancelar solicitud'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _repository.cancel(request.id);
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      _showMessage('Solicitud cancelada');
    } catch (error) {
      if (!mounted) return;
      _showMessage(supplyRequestErrorMessage(error));
    }
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
        title: const Text('Mis solicitudes', style: AppText.appBarText),
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
            const Text('No se pudieron cargar tus solicitudes'),
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
            SizedBox(
              height: 52,
              child: TextButton(
                onPressed: _openCreate,
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.blackGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: const Text('Nueva solicitud', style: AppText.button),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_requests.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                child: Column(
                  children: [
                    Text(
                      'Todavía no tenés solicitudes',
                      textAlign: TextAlign.center,
                      style: AppText.label,
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      'Creá tu primera solicitud para empezar a comprar al por mayor.',
                      textAlign: TextAlign.center,
                      style: AppText.bodySecondary,
                    ),
                  ],
                ),
              )
            else
              ..._requests.map(_requestCard),
          ],
        ),
      ),
    );
  }

  Widget _requestCard(SupplyRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
              Expanded(child: Text(request.productName, style: AppText.label)),
              const SizedBox(width: AppSpacing.sm),
              _StatusChip(status: request.status),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${_quantity(request.totalAmount)} ${request.amountUnit.label}',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.blackGreen,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (request.committedAmount > 0 || request.actualAmount > 0)
            Text(
              'Disponible: ${_quantity(request.actualAmount)} ${request.amountUnit.label} · '
              'Comprometido: ${_quantity(request.committedAmount)} ${request.amountUnit.label}',
              style: AppText.body,
            ),
          if (request.numberOfUnits > 0 || request.amountPerUnit > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${request.numberOfUnits > 0 ? 'Unidades: ${_quantity(request.numberOfUnits)}' : ''}'
              '${request.numberOfUnits > 0 && request.amountPerUnit > 0 ? ' · ' : ''}'
              '${request.amountPerUnit > 0 ? 'Cantidad por unidad: ${_quantity(request.amountPerUnit)} ${request.unitOfMeasure.label}' : ''}',
              style: AppText.body,
            ),
          ],
          if (request.location.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _DetailLine(
              icon: Icons.location_on_outlined,
              text: request.location,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          _DetailLine(
            icon: Icons.event_outlined,
            text: 'Límite: ${_deadline(request.requestDeadline)}',
          ),
          const SizedBox(height: AppSpacing.xs),
          _DetailLine(
            icon: Icons.local_shipping_outlined,
            text: 'Entrega: ${_deadline(request.deliveryDeadline)}',
          ),
          const SizedBox(height: AppSpacing.xs),
          _DetailLine(
            icon: request.multipleProviders
                ? Icons.groups_outlined
                : Icons.person_outline,
            text: request.multipleProviders
                ? 'Proveedores múltiples: Sí'
                : 'Proveedores múltiples: No',
          ),
          if (request.minAmountPerProvider > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            _DetailLine(
              icon: Icons.scale_outlined,
              text:
                  'Mínimo por proveedor: ${_quantity(request.minAmountPerProvider)} ${request.amountUnit.label}',
            ),
          ],
          if (request.isOpen) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                TextButton(
                  onPressed: () => _openOffers(request),
                  child: const Text('Ver ofertas'),
                ),
                TextButton(
                  onPressed: () => _openEdit(request),
                  child: const Text('Editar'),
                ),
                TextButton(
                  onPressed: () => _cancel(request),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _deadline(String? value) {
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
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final SupplyRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color background, Color foreground) = switch (status) {
      SupplyRequestStatus.open => (
        AppColors.whiteGreen.withValues(alpha: 0.2),
        AppColors.blackGreen,
      ),
      SupplyRequestStatus.completed => (
        AppColors.dark.withValues(alpha: 0.08),
        AppColors.dark,
      ),
      SupplyRequestStatus.cancelled || SupplyRequestStatus.expired => (
        Colors.red.withValues(alpha: 0.1),
        Colors.red,
      ),
      SupplyRequestStatus.unknown => (
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

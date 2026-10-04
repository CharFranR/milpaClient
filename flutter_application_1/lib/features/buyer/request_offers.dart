import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/core/token_store.dart';
import 'package:flutter_application_1/features/buyer/catalog_models.dart';
import 'package:flutter_application_1/features/buyer/match_models.dart';
import 'package:flutter_application_1/features/buyer/match_repository.dart';
import 'package:flutter_application_1/features/buyer/supply_request_models.dart';
import 'package:flutter_application_1/features/buyer/transaction_page.dart';
import 'package:flutter_application_1/ui/app_tokens.dart';

class RequestOffersPage extends StatefulWidget {
  const RequestOffersPage({super.key, required this.request, this.repository});

  final SupplyRequest request;
  final MatchRepository? repository;

  @override
  State<RequestOffersPage> createState() => _RequestOffersPageState();
}

class _RequestOffersPageState extends State<RequestOffersPage> {
  late final MatchRepository _repository =
      widget.repository ??
      MatchRepository(apiClient: ApiClient(), tokenStore: TokenStore());

  List<PrioritizedOffer> _offers = <PrioritizedOffer>[];
  final Set<String> _busy = <String>{};
  bool _loading = true;
  bool _changed = false;
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
      final List<PrioritizedOffer> offers = await _repository.fetchPrioritized(
        widget.request.id,
      );
      if (!mounted) return;
      setState(() {
        _offers = offers;
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

  Future<void> _like(PrioritizedOffer prioritized) async {
    final String id = prioritized.offer.id;
    if (_busy.contains(id)) return;
    setState(() => _busy.add(id));
    try {
      final MatchResult result = await _repository.like(id);
      if (!mounted) return;
      _changed = true;
      _showMessage('Oferta aceptada');
      await _load(showSpinner: false);
      if (!mounted) return;
      await _openTransaction(result.matchId);
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.statusCode == 409) {
        _showMessage(error.message);
        await _load(showSpinner: false);
      } else {
        _showMessage('No se pudo completar la acción. Intenta de nuevo.');
      }
    } catch (error) {
      if (!mounted) return;
      _showMessage('No se pudo completar la acción. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  Future<void> _openTransaction(String matchId) async {
    if (matchId.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TransactionPage(matchId: matchId),
      ),
    );
  }

  Future<void> _pass(PrioritizedOffer prioritized) async {
    final String id = prioritized.offer.id;
    if (_busy.contains(id)) return;
    setState(() => _busy.add(id));
    try {
      await _repository.pass(id);
      if (!mounted) return;
      _showMessage('Oferta descartada');
      await _load(showSpinner: false);
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.statusCode == 409) {
        _showMessage(error.message);
        await _load(showSpinner: false);
      } else {
        _showMessage('No se pudo completar la acción. Intenta de nuevo.');
      }
    } catch (error) {
      if (!mounted) return;
      _showMessage('No se pudo completar la acción. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        backgroundColor: AppColors.whitemodeBackgrund,
        appBar: AppBar(
          backgroundColor: AppColors.blackGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text('Ofertas recibidas', style: AppText.appBarText),
        ),
        body: _buildBody(),
      ),
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
            const Text('No se pudieron cargar las ofertas'),
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
            Text(widget.request.productName, style: AppText.sectionTitle),
            const SizedBox(height: AppSpacing.sm),
            if (_offers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                child: Column(
                  children: [
                    Text(
                      'Todavía no hay ofertas para esta solicitud',
                      textAlign: TextAlign.center,
                      style: AppText.label,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Cuando un agricultor ofrezca, la vas a ver acá para aceptarla o descartarla.',
                      textAlign: TextAlign.center,
                      style: AppText.bodySecondary,
                    ),
                  ],
                ),
              )
            else
              ..._offers.map(_offerSwipe),
          ],
        ),
      ),
    );
  }

  Widget _offerSwipe(PrioritizedOffer prioritized) {
    final bool busy = _busy.contains(prioritized.offer.id);
    return Dismissible(
      key: ValueKey<String>('offer-${prioritized.offer.id}'),
      direction: busy ? DismissDirection.none : DismissDirection.horizontal,
      background: const _SwipeHint(
        alignment: Alignment.centerLeft,
        icon: Icons.check_circle,
        color: AppColors.blackGreen,
      ),
      secondaryBackground: const _SwipeHint(
        alignment: Alignment.centerRight,
        icon: Icons.cancel,
        color: Colors.red,
      ),
      confirmDismiss: (DismissDirection direction) async {
        if (direction == DismissDirection.startToEnd) {
          await _like(prioritized);
        } else {
          await _pass(prioritized);
        }
        return false;
      },
      child: _offerCard(prioritized),
    );
  }

  Widget _offerCard(PrioritizedOffer prioritized) {
    final MatchOffer offer = prioritized.offer;
    final bool busy = _busy.contains(offer.id);
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
              Expanded(
                child: Text(
                  '${formatPrice(offer.pricePerUnit ?? 0)} / ${offer.amountUnit.label}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blackGreen,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _StatusChip(status: offer.status),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Text('Puntaje', style: AppText.body),
              const SizedBox(width: AppSpacing.sm),
              _Stars(value: prioritized.score, size: 16),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Cantidad ofrecida: ${_quantity(offer.totalAmount)} ${offer.amountUnit.label}',
            style: AppText.body,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Disponible: ${_quantity(prioritized.availableQuantity)} ${offer.amountUnit.label}',
            style: AppText.body,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Entrega: ${offer.deliveryAvailable ? 'Sí' : 'No'}',
            style: AppText.body,
          ),
          if (offer.proposedDeliveryDay != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Día propuesto: ${_formatDay(offer.proposedDeliveryDay!)}',
              style: AppText.body,
            ),
          ],
          if (prioritized.distanceKm != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Distancia: ${prioritized.distanceKm!.toStringAsFixed(1)} km',
              style: AppText.body,
            ),
          ],
          if (offer.comments.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(offer.comments, style: AppText.bodySecondary),
          ],
          if (prioritized.contributions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _Breakdown(
              contributions: prioritized.contributions,
              hasDistance: prioritized.distanceKm != null,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: busy ? null : () => _like(prioritized),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.blackGreen,
                  ),
                  child: const Text('Aceptar'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextButton(
                  onPressed: busy ? null : () => _pass(prioritized),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Descartar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDay(String value) {
    final DateTime? date = DateTime.tryParse(value);
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

class _SwipeHint extends StatelessWidget {
  const _SwipeHint({
    required this.alignment,
    required this.icon,
    required this.color,
  });

  final Alignment alignment;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color, size: 30),
    );
  }
}

class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.contributions, required this.hasDistance});

  final List<ScoreContribution> contributions;
  final bool hasDistance;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(left: AppSpacing.sm),
          title: const Text('Desglose del puntaje', style: AppText.label),
          children: contributions
              .map(
                (ScoreContribution contribution) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          contribution.label,
                          style: AppText.bodySecondary,
                        ),
                      ),
                      if (!hasDistance && contribution.factor == 'distance')
                        Text('Sin datos', style: AppText.bodySecondary)
                      else
                        _Stars(value: contribution.score),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.value, this.size = 14});

  final double value;
  final double size;

  @override
  Widget build(BuildContext context) {
    final double stars = (value.clamp(0, 1) * 5 * 2).round() / 2;
    return Semantics(
      label: '${stars.toStringAsFixed(1)} de 5',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List<Widget>.generate(5, (int index) {
          final int position = index + 1;
          final IconData icon = stars >= position
              ? Icons.star
              : stars >= position - 0.5
              ? Icons.star_half
              : Icons.star_border;
          return Icon(icon, size: size, color: AppColors.yelow);
        }),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final OfferStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color background, Color foreground) = switch (status) {
      OfferStatus.active => (
        AppColors.whiteGreen.withValues(alpha: 0.2),
        AppColors.blackGreen,
      ),
      OfferStatus.matched => (
        AppColors.dark.withValues(alpha: 0.08),
        AppColors.dark,
      ),
      OfferStatus.rejected ||
      OfferStatus.withdrawn => (Colors.red.withValues(alpha: 0.1), Colors.red),
      OfferStatus.unknown => (
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

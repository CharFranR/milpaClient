import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/core/location_reporter.dart';
import 'package:flutter_application_1/features/auth/session_controller.dart';
import 'package:flutter_application_1/features/buyer/catalog_models.dart';
import 'package:flutter_application_1/features/buyer/catalog_repository.dart';
import 'package:flutter_application_1/features/buyer/offering_detail.dart';
import 'package:flutter_application_1/features/buyer/widgets/product_card.dart';
import 'package:flutter_application_1/features/buyer/widgets/search_field.dart';
import 'package:flutter_application_1/ui/app_tokens.dart';

/// Inicio del comprador: saludo, buscador, productores cercanos, categorías
/// y destacados, todos contra el server real.
class BuyerHome extends StatefulWidget {
  const BuyerHome({
    super.key,
    this.repository,
    this.locationReporter = const DeviceLocationReporter(),
    this.onExplore,
  });

  final CatalogRepository? repository;
  final LocationReporter locationReporter;
  final VoidCallback? onExplore;

  @override
  State<BuyerHome> createState() => _BuyerHomeState();
}

class _BuyerHomeState extends State<BuyerHome> {
  static const int _featuredCount = 4;

  late final CatalogRepository _repository =
      widget.repository ?? CatalogRepository(apiClient: ApiClient());

  List<CatalogCategory> _categories = <CatalogCategory>[];
  List<CatalogItem> _featured = <CatalogItem>[];
  int? _nearbyCount;
  bool _nearbyPending = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final List<CatalogCategory> categories = await _repository
          .fetchCategories();
      final CatalogPage featured = await _repository.search(
        pageSize: _featuredCount,
      );
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _featured = featured.results;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is NetworkException
            ? error.message
            : 'No pudimos cargar el inicio';
        _loading = false;
      });
      return;
    }

    setState(() => _nearbyPending = true);
    final int? nearbyCount = await _loadNearbyCount();
    if (!mounted) return;

    setState(() {
      _nearbyCount = nearbyCount;
      _nearbyPending = false;
    });
  }

  Future<int?> _loadNearbyCount() async {
    try {
      final Coordinates? coordinates = await widget.locationReporter
          .captureGranted();
      if (coordinates == null) return null;

      final CatalogPage page = await _repository.search(
        sort: CatalogSort.proximity,
        latitude: coordinates.latitude,
        longitude: coordinates.longitude,
        pageSize: 1,
      );
      return page.totalHits;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String firstName = SessionScope.of(context).user?.firstName ?? '';

    return Scaffold(
      backgroundColor: AppColors.whitemodeBackgrund,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.blackGreen,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Buenos días',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                firstName.isEmpty
                                    ? 'Hola 👋'
                                    : '$firstName 👋',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const _NotificationBell(),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const SearchField(
                      hint: 'Buscar productos o productores...',
                    ),
                    const SizedBox(height: 14),
                    _nearbyProducersCard(),
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: _content()),
        ],
      ),
    );
  }

  Widget _content() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final String? error = _error;
    if (error != null) {
      return _message(error, retry: true);
    }

    if (_categories.isEmpty && _featured.isEmpty) {
      return _message('Todavía no hay ofertas publicadas');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        top: AppSpacing.lg,
        bottom: AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_categories.isNotEmpty) ...[
            _SectionBar(title: 'Categorías', onTap: _goToExplore),
            const SizedBox(height: 12),
            SizedBox(height: 92, child: _categoryList()),
            const SizedBox(height: 24),
          ],
          _SectionBar(title: 'Destacados esta semana', onTap: _goToExplore),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.8,
            children: _featured.map(_productCard).toList(),
          ),
        ],
      ),
    );
  }

  Widget _categoryList() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: _categories.length,
      separatorBuilder: (context, index) => const SizedBox(width: 14),
      itemBuilder: (context, index) {
        final CatalogCategory category = _categories[index];
        return InkWell(
          onTap: _goToExplore,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Column(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.dark.withValues(alpha: 0.06),
                  ),
                ),
                child: Center(
                  child: Text(
                    category.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                category.name,
                style: const TextStyle(fontSize: 12, color: AppColors.dark),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _productCard(CatalogItem item) {
    return ProductCard(
      name: item.name,
      seller: item.farmerName,
      priceText: formatPrice(item.price),
      imageSrc: item.imageSrc,
      badge: item.farmerVerified ? 'Verificado' : null,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => OfferingDetailPage(offeringId: item.id),
        ),
      ),
    );
  }

  Widget _nearbyProducersCard() {
    final int? count = _nearbyCount;
    final String subtitle;
    if (_nearbyPending) {
      subtitle = 'Buscando productores cerca de vos…';
    } else if (count == null) {
      subtitle = 'Compartí tu ubicación en tu perfil y te los ordenamos '
          'por cercanía';
    } else if (count == 0) {
      subtitle = 'Sin ofertas cerca de tu ubicación por ahora';
    } else {
      subtitle = '$count ofertas ordenadas por cercanía';
    }

    return _NearbyProducersCard(
      subtitle: subtitle,
      onExplore: _goToExplore,
    );
  }

  Widget _message(String text, {bool retry = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: AppText.bodySecondary,
            ),
            if (retry) ...[
              const SizedBox(height: AppSpacing.lg),
              TextButton(onPressed: _load, child: const Text('Reintentar')),
            ],
          ],
        ),
      ),
    );
  }

  void _goToExplore() => widget.onExplore?.call();
}

/// Campana de notificaciones sobre la cabecera verde.
class _NotificationBell extends StatelessWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(Icons.notifications_none, color: Colors.white, size: 22),
      ),
    );
  }
}

/// Tarjeta verde con el resumen de productores cercanos.
class _NearbyProducersCard extends StatelessWidget {
  const _NearbyProducersCard({required this.subtitle, this.onExplore});

  final String subtitle;
  final VoidCallback? onExplore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFF0A6A0C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Productores cercanos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.yelow,
                  ),
                ),
                const SizedBox(height: 12),
                Material(
                  color: AppColors.yelow,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: InkWell(
                    onTap: onExplore,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: AppSpacing.sm,
                      ),
                      child: Text(
                        'Explorar →',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.blackGreen,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🗺️', style: TextStyle(fontSize: 38)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila de título de sección con acción "Ver todo".
class _SectionBar extends StatelessWidget {
  const _SectionBar({required this.title, this.onTap});

  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Text(title, style: AppText.headline),
          const Spacer(),
          InkWell(
            onTap: onTap,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Text(
                'Ver todo',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blackGreen,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

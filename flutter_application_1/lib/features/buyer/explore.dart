import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/features/buyer/catalog_models.dart';
import 'package:flutter_application_1/features/buyer/catalog_repository.dart';
import 'package:flutter_application_1/features/buyer/widgets/product_card.dart';
import 'package:flutter_application_1/features/buyer/widgets/search_field.dart';
import 'package:flutter_application_1/ui/app_tokens.dart';

class BuyerExplore extends StatefulWidget {
  const BuyerExplore({super.key, this.repository});

  final CatalogRepository? repository;

  @override
  State<BuyerExplore> createState() => _BuyerExploreState();
}

class _BuyerExploreState extends State<BuyerExplore> {
  static const int _pageSize = 20;

  late final CatalogRepository _repository =
      widget.repository ?? CatalogRepository(apiClient: ApiClient());
  Timer? _debounce;

  List<CatalogCategory> _categories = <CatalogCategory>[];
  List<CatalogItem> _items = <CatalogItem>[];
  String? _selectedCategoryId;
  CatalogSort _sort = CatalogSort.relevance;
  String _term = '';
  int _page = 1;
  int _totalPages = 1;
  int _totalHits = 0;
  bool _categoriesLoaded = false;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    try {
      final (List<CatalogCategory> categories, CatalogPage page) = await (
        _repository.fetchCategories(),
        _repository.search(page: 1, pageSize: _pageSize),
      ).wait;
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _categoriesLoaded = true;
        _items = List<CatalogItem>.of(page.results);
        _page = page.page;
        _totalPages = page.totalPages;
        _totalHits = page.totalHits;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudo cargar el catálogo';
      });
    }
  }

  void _retry() {
    if (_categoriesLoaded) {
      _runSearch(page: 1);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    _loadInitial();
  }

  Future<void> _runSearch({required int page, bool append = false}) async {
    if (append) {
      setState(() => _loadingMore = true);
    } else {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final CatalogPage result = await _repository.search(
        term: _term,
        categoryId: _selectedCategoryId,
        sort: _sort,
        page: page,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        if (append) {
          _items.addAll(result.results);
        } else {
          _items = List<CatalogItem>.of(result.results);
        }
        _page = result.page;
        _totalPages = result.totalPages;
        _totalHits = result.totalHits;
        _loading = false;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (append) {
        setState(() => _loadingMore = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pudimos cargar más productos')),
        );
      } else {
        setState(() {
          _loading = false;
          _error = 'No se pudo cargar el catálogo';
        });
      }
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final String term = value.trim();
      if (term == _term) return;
      _term = term;
      _runSearch(page: 1);
    });
  }

  void _onSearchSubmitted(String value) {
    _debounce?.cancel();
    _term = value.trim();
    _runSearch(page: 1);
  }

  void _selectCategory(String? categoryId) {
    if (_selectedCategoryId == categoryId) return;
    _selectedCategoryId = categoryId;
    _runSearch(page: 1);
  }

  void _selectRelevance() {
    if (_sort == CatalogSort.relevance) return;
    _sort = CatalogSort.relevance;
    _runSearch(page: 1);
  }

  void _togglePriceSort() {
    _sort = _sort == CatalogSort.priceAsc
        ? CatalogSort.priceDesc
        : CatalogSort.priceAsc;
    _runSearch(page: 1);
  }

  void _loadMore() => _runSearch(page: _page + 1, append: true);

  @override
  Widget build(BuildContext context) {
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Explorar',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SearchField(
                      hint: 'Buscar productos...',
                      onChanged: _onSearchChanged,
                      onSubmitted: _onSearchSubmitted,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _CategoryChip(
                            label: 'Todos',
                            active: _selectedCategoryId == null,
                            onTap: () => _selectCategory(null),
                          ),
                          for (final CatalogCategory category
                              in _categories) ...[
                            const SizedBox(width: 8),
                            _CategoryChip(
                              label: category.name,
                              active: _selectedCategoryId == category.id,
                              onTap: () => _selectCategory(category.id),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: _buildContent(context)),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_error != null) {
      return _ErrorState(onRetry: _retry);
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 14),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: [
                _SortPill(
                  icon: Icons.sort,
                  label: 'Relevancia',
                  active: _sort == CatalogSort.relevance,
                  onTap: _selectRelevance,
                ),
                const SizedBox(width: 8),
                _SortPill(
                  icon: switch (_sort) {
                    CatalogSort.priceAsc => Icons.arrow_upward,
                    CatalogSort.priceDesc => Icons.arrow_downward,
                    CatalogSort.relevance => Icons.swap_vert,
                  },
                  label: 'Precio',
                  active: _sort != CatalogSort.relevance,
                  onTap: _togglePriceSort,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              _totalHits == 1
                  ? '1 producto encontrado'
                  : '$_totalHits productos encontrados',
              style: TextStyle(fontSize: 13, color: AppTints.muted),
            ),
          ),
          const SizedBox(height: 12),
          if (_items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xxl,
              ),
              child: Text(
                'No encontramos productos',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.dark),
              ),
            )
          else
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.8,
              children: _items
                  .map(
                    (CatalogItem item) => ProductCard(
                      name: item.name,
                      seller: item.farmerName,
                      priceText: formatPrice(item.price),
                      imageSrc: item.imageSrc,
                      badge: item.farmerVerified ? 'Verificado' : null,
                    ),
                  )
                  .toList(),
            ),
          if (_items.isNotEmpty && _page < _totalPages)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                0,
              ),
              child: Center(
                child: TextButton(
                  onPressed: _loadingMore ? null : _loadMore,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.blackGreen,
                    disabledForegroundColor: AppTints.muted,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.sm,
                    ),
                    shape: const StadiumBorder(
                      side: BorderSide(color: AppColors.blackGreen, width: 1.2),
                    ),
                  ),
                  child: _loadingMore
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.blackGreen,
                          ),
                        )
                      : const Text(
                          'Cargar más',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? const Color(0xFF064407) : Colors.transparent,
      shape: StadiumBorder(
        side: active
            ? BorderSide.none
            : const BorderSide(color: Colors.white, width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _SortPill extends StatelessWidget {
  const _SortPill({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color foreground = active ? Colors.white : AppColors.blackGreen;
    return Material(
      color: active ? AppColors.blackGreen : Colors.white,
      shape: StadiumBorder(
        side: active
            ? BorderSide.none
            : const BorderSide(color: AppColors.blackGreen, width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off, size: 40, color: AppTints.muted),
          const SizedBox(height: 12),
          const Text(
            'No se pudo cargar el catálogo',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: AppColors.blackGreen),
            child: const Text(
              'Reintentar',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

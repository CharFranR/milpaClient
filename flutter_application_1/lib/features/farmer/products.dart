import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/core/token_store.dart';
import 'package:flutter_application_1/features/auth/session_controller.dart';
import 'package:flutter_application_1/features/buyer/catalog_models.dart';
import 'package:flutter_application_1/features/buyer/widgets/product_image.dart';
import 'package:flutter_application_1/features/company/company_models.dart';
import 'package:flutter_application_1/features/company/company_repository.dart';
import 'package:flutter_application_1/features/farmer/business.dart';
import 'package:flutter_application_1/features/farmer/catalog_repository.dart';
import 'package:flutter_application_1/features/farmer/product_form.dart';
import 'package:flutter_application_1/features/farmer/product_models.dart';
import 'package:flutter_application_1/ui/app_tokens.dart';

class FarmerProductsPage extends StatefulWidget {
  const FarmerProductsPage({
    super.key,
    this.repository,
    this.companyRepository,
  });

  final CatalogRepository? repository;
  final CompanyRepository? companyRepository;

  @override
  State<FarmerProductsPage> createState() => _FarmerProductsPageState();
}

class _FarmerProductsPageState extends State<FarmerProductsPage> {
  late final CatalogRepository _repository =
      widget.repository ??
      CatalogRepository(apiClient: ApiClient(), tokenStore: TokenStore());

  late final CompanyRepository _companyRepository =
      widget.companyRepository ??
      CompanyRepository(apiClient: ApiClient(), tokenStore: TokenStore());

  String _userId = '';
  List<FarmerProduct> _products = <FarmerProduct>[];
  String? _companyId;
  bool _loading = true;
  Object? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final String userId = SessionScope.of(context).user?.id ?? '';
    if (userId.isNotEmpty && userId != _userId) {
      _userId = userId;
      _load();
    }
  }

  Future<void> _load() async {
    if (_userId.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<FarmerProduct> products = await _repository.fetchMine(_userId);
      final String? companyId = await _loadCompanyId();
      if (!mounted) return;
      setState(() {
        _products = products;
        _companyId = companyId;
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

  Future<String?> _loadCompanyId() async {
    try {
      final List<Company> companies = await _companyRepository.fetchByOwner(
        _userId,
      );
      if (companies.isEmpty) return null;
      final String id = companies.first.id;
      return id.isEmpty ? null : id;
    } catch (_) {
      return null;
    }
  }

  Future<void> _openForm() async {
    final bool? published = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ProductFormPage(
          userId: _userId,
          repository: _repository,
          companyId: _companyId,
        ),
      ),
    );
    if (published != true) return;
    await _load();
    if (!mounted) return;
    _showMessage('Ya está publicado. Los compradores lo pueden ver.');
  }

  Future<void> _openBusiness() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => FarmerBusinessPage(
          companyRepository: widget.companyRepository,
        ),
      ),
    );
    if (!mounted) return;
    await _load();
  }

  Future<void> _confirmDeactivate(FarmerProduct product) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('¿Ya no lo vas a vender?'),
        content: const Text(
          'Dejá de mostrarlo en el mercado. Después no se puede volver a mostrar.',
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
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _repository.deactivate(product.id);
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      _showMessage('Listo. Ya no se muestra en el mercado.');
    } catch (error) {
      if (!mounted) return;
      _showMessage(_errorMessage(error));
    }
  }

  Future<void> _renew(FarmerProduct product) async {
    final DateTime today = DateUtils.dateOnly(DateTime.now());
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: today.add(const Duration(days: 30)),
      firstDate: today,
      lastDate: DateTime(2100),
      helpText: '¿Hasta cuándo lo vas a vender?',
      cancelText: 'Volver',
      confirmText: 'Guardar',
    );
    if (selected == null || !mounted) return;

    try {
      await _repository.renew(product.id, selected);
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      _showMessage('Listo. Actualizamos la fecha.');
    } catch (error) {
      if (!mounted) return;
      _showMessage(_errorMessage(error));
    }
  }

  String _errorMessage(Object error) {
    if (error is ApiException) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        return 'No pudimos hacer el cambio. Volvé a entrar.';
      }
      return 'No pudimos hacer el cambio. Probá de nuevo.';
    }
    if (error is NetworkException) return error.message;
    return 'No pudimos hacer el cambio. Probá de nuevo.';
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
          child: Text('Mis productos', style: AppText.screenTitle),
        ),
        if (!_loading && _error == null && _companyId == null)
          _companyBanner(),
        Expanded(child: _content()),
        _publishButton(),
      ],
    );
  }

  Widget _content() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _messageState(
        icon: Icons.wifi_off_outlined,
        title: 'No pudimos cargar tus productos',
        message: 'Revisá que tengas internet y volvé a intentar.',
        retry: true,
      );
    }
    if (_products.isEmpty) {
      return _messageState(
        icon: Icons.inventory_2_outlined,
        title: 'Todavía no tenés productos',
        message: 'Publicá lo que tenés para vender y los compradores lo van a '
            'poder ver.',
      );
    }

    final List<FarmerProduct> visible = _products
        .where((FarmerProduct product) => !product.isHidden)
        .toList();
    final List<FarmerProduct> hidden = _products
        .where((FarmerProduct product) => product.isHidden)
        .toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        children: [
          ...visible.map(_productCard),
          if (hidden.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            const Text('Ocultos', style: AppText.sectionTitle),
            const SizedBox(height: AppSpacing.sm),
            ...hidden.map(_productCard),
          ],
        ],
      ),
    );
  }

  Widget _companyBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.whiteGreen.withValues(alpha: 0.45),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.whiteGreen.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.storefront_outlined,
                      size: 26,
                      color: AppColors.blackGreen,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                const Expanded(
                  child: Text('Sumá tu empresa', style: AppText.headline),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Creá el perfil de tu empresa para obtener la insignia de '
              'Proveedor Verificado y más visibilidad en el Marketplace.',
              style: AppText.body,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: _openBusiness,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blackGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              icon: const Icon(Icons.add_business_outlined, size: 24),
              label: const Text('Ir a Mi negocio'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _messageState({
    required IconData icon,
    required String title,
    required String message,
    bool retry = false,
  }) {
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
            Text(title, textAlign: TextAlign.center, style: AppText.screenTitle),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center, style: AppText.body),
            if (retry) ...[
              const SizedBox(height: AppSpacing.xl),
              OutlinedButton.icon(
                onPressed: _load,
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

  Widget _productCard(FarmerProduct product) {
    final String? imageSrc = product.imageSrc;
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
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: imageSrc == null || imageSrc.isEmpty
                      ? const DecoratedBox(
                          decoration: BoxDecoration(color: Color(0xFFEAF3E6)),
                          child: Center(
                            child: Icon(
                              Icons.eco_outlined,
                              size: 46,
                              color: AppColors.blackGreen,
                            ),
                          ),
                        )
                      : ProductImage(imageSrc: imageSrc, emoji: '🌿'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatusBadge(product: product),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      product.name,
                      style: AppText.headline,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      formatPrice(product.price),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.blackGreen,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Cantidad disponible: ${_quantity(product.quantityAvailable)}',
                      style: AppText.body,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (!product.isHidden)
                OutlinedButton.icon(
                  onPressed: () => _confirmDeactivate(product),
                  style: _cardActionStyle,
                  icon: const Icon(Icons.remove_circle_outline, size: 22),
                  label: const Text('Desactivar'),
                ),
              OutlinedButton.icon(
                onPressed: () => _renew(product),
                style: _cardActionStyle,
                icon: const Icon(Icons.event_available_outlined, size: 22),
                label: const Text('Renovar la fecha'),
              ),
            ],
          ),
        ],
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
          label: const Text('Publicar un producto'),
        ),
      ),
    );
  }

  String _quantity(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }

  ButtonStyle get _cardActionStyle => OutlinedButton.styleFrom(
    foregroundColor: AppColors.blackGreen,
    minimumSize: const Size(0, 50),
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    side: BorderSide(color: AppTints.border, width: 1.2),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.product});

  final FarmerProduct product;

  @override
  Widget build(BuildContext context) {
    final bool expired = product.isExpired;
    final bool active = product.isActive && !expired;
    final Color background = active
        ? AppColors.whiteGreen.withValues(alpha: 0.22)
        : AppColors.dark.withValues(alpha: 0.08);
    final Color foreground = active ? AppColors.blackGreen : AppTints.secondary;
    final String label = expired
        ? 'Vencido'
        : product.isActive
        ? 'Activo'
        : 'Inactivo';
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
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

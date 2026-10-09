import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/core/models/auth_models.dart';
import 'package:flutter_application_1/core/token_store.dart';
import 'package:flutter_application_1/features/auth/session_controller.dart';
import 'package:flutter_application_1/features/company/company_models.dart';
import 'package:flutter_application_1/features/company/company_repository.dart';
import 'package:flutter_application_1/features/farmer/catalog_repository.dart';
import 'package:flutter_application_1/features/farmer/product_models.dart';
import 'package:flutter_application_1/ui/app_tokens.dart';
import 'package:flutter_application_1/ui/labeled_field.dart';

class FarmerBusinessPage extends StatefulWidget {
  const FarmerBusinessPage({super.key, this.companyRepository});

  final CompanyRepository? companyRepository;

  @override
  State<FarmerBusinessPage> createState() => _FarmerBusinessPageState();
}

class _FarmerBusinessPageState extends State<FarmerBusinessPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final CompanyRepository _companyRepository =
      widget.companyRepository ??
      CompanyRepository(apiClient: ApiClient(), tokenStore: TokenStore());

  late final CatalogRepository _catalogRepository = CatalogRepository(
    apiClient: ApiClient(),
    tokenStore: TokenStore(),
  );

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();

  String _userId = '';
  Company? _company;
  bool _loading = true;
  Object? _error;
  bool _creating = false;
  bool _isSaving = false;

  List<FarmerCategory> _categories = <FarmerCategory>[];
  bool _categoriesLoading = true;
  Object? _categoriesError;
  String _categoryId = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

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
      final List<Company> companies = await _companyRepository.fetchByOwner(
        _userId,
      );
      if (!mounted) return;
      final Company? company = companies.isEmpty ? null : companies.first;
      _prefill(company);
      setState(() {
        _company = company;
        _creating = false;
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

  Future<void> _loadCategories() async {
    setState(() {
      _categoriesLoading = true;
      _categoriesError = null;
    });
    try {
      final List<FarmerCategory> categories = await _catalogRepository
          .fetchCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _categoriesLoading = false;
        _categoriesError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _categoriesLoading = false;
        _categoriesError = error;
      });
    }
  }

  void _prefill(Company? company) {
    if (company == null) {
      final User? user = SessionScope.of(context).user;
      _phoneController.text = user?.phoneNumber ?? '';
      _emailController.text = user?.email ?? '';
      return;
    }
    _nameController.text = company.name;
    _descriptionController.text = company.description;
    _phoneController.text = company.phoneNumber ?? '';
    _emailController.text = company.email ?? '';
    _websiteController.text = company.website;
    _categoryId = company.categoryId;
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    final bool valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    final CompanyDraft draft = CompanyDraft(
      name: _nameController.text.trim(),
      categoryId: _categoryId.isEmpty ? null : _categoryId,
      description: _descriptionController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      website: _websiteController.text.trim(),
    );

    try {
      final Company? company = _company;
      if (company == null) {
        final Company created = await _companyRepository.create(draft);
        if (!mounted) return;
        setState(() {
          _company = created;
          _creating = false;
        });
        _showMessage('Empresa creada correctamente.');
      } else {
        await _companyRepository.update(company.id, draft);
        if (!mounted) return;
        _showMessage('Empresa actualizada.');
      }
    } catch (error) {
      if (!mounted) return;
      _showMessage(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _errorMessage(Object error) {
    if (error is ApiException) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        return 'No pudimos guardar. Volvé a entrar.';
      }
      if (error.statusCode == 400) {
        return 'Revisá los datos y probá de nuevo.';
      }
      return 'No pudimos guardar. Probá de nuevo.';
    }
    if (error is NetworkException) return error.message;
    return 'No pudimos guardar. Probá de nuevo.';
  }

  String? _requiredName(String? value) {
    return (value ?? '').trim().isEmpty
        ? 'El nombre de la empresa es obligatorio.'
        : null;
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
        title: const Text(
          'Mi negocio',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _messageState(
        icon: Icons.wifi_off_outlined,
        title: 'No pudimos cargar tu empresa',
        message: 'Revisá que tengas internet y volvé a intentar.',
        actionLabel: 'Reintentar',
        actionIcon: Icons.refresh,
        onAction: _load,
      );
    }
    if (_company == null && !_creating) {
      return _messageState(
        icon: Icons.storefront_outlined,
        title: 'Aún no has creado tu empresa',
        message: 'Crea tu perfil de empresa para aparecer en el Marketplace.',
        actionLabel: 'Crear mi empresa',
        actionIcon: Icons.add_business_outlined,
        onAction: () => setState(() => _creating = true),
      );
    }
    return _form();
  }

  Widget _messageState({
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required IconData actionIcon,
    required VoidCallback onAction,
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
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppText.screenTitle,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center, style: AppText.body),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blackGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              icon: Icon(actionIcon, size: 26),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _form() {
    final bool editing = _company != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LabeledField(
                    label: 'Nombre',
                    hint: 'Ej. Finca El Roble',
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    validator: _requiredName,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text('Categoría', style: AppText.fieldLabel),
                  const SizedBox(height: 6),
                  _categoryPicker(),
                  const SizedBox(height: AppSpacing.md),
                  LabeledField(
                    label: 'Descripción',
                    hint: 'Contá qué producís y qué ofrecés',
                    controller: _descriptionController,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  LabeledField(
                    label: 'Teléfono',
                    hint: 'Ej. 8888 8888',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  LabeledField(
                    label: 'Correo',
                    hint: 'Ej. correo@ejemplo.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  LabeledField(
                    label: 'Sitio web',
                    hint: 'Ej. https://mifinca.com',
                    controller: _websiteController,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.done,
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: SizedBox(
            height: 62,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _submit,
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
              icon: _isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline, size: 28),
              label: Text(
                _isSaving
                    ? 'Guardando...'
                    : (editing ? 'Guardar cambios' : 'Crear mi empresa'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _categoryPicker() {
    if (_categoriesLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_categoriesError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'No pudimos cargar las categorías',
            style: AppText.bodySecondary,
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: _loadCategories,
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
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _categoryChip(id: '', label: 'Sin categoría'),
        ..._categories.map(
          (FarmerCategory category) =>
              _categoryChip(id: category.id, label: category.name),
        ),
      ],
    );
  }

  Widget _categoryChip({required String id, required String label}) {
    final bool selected = _categoryId == id;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => setState(() => _categoryId = id),
      labelStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: selected ? Colors.white : AppColors.dark,
      ),
      labelPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      backgroundColor: Colors.white,
      selectedColor: AppColors.blackGreen,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        side: BorderSide(
          color: selected ? AppColors.blackGreen : AppTints.border,
          width: 1.5,
        ),
      ),
    );
  }
}

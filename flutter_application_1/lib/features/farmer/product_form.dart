import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/core/photo_picker.dart';
import 'package:flutter_application_1/core/token_store.dart';
import 'package:flutter_application_1/features/farmer/catalog_repository.dart';
import 'package:flutter_application_1/features/farmer/product_models.dart';
import 'package:flutter_application_1/ui/app_tokens.dart';
import 'package:flutter_application_1/ui/labeled_field.dart';

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({
    super.key,
    required this.userId,
    this.repository,
    this.photoPicker = const DevicePhotoPicker(),
  });

  final String userId;
  final CatalogRepository? repository;
  final PhotoPicker photoPicker;

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final CatalogRepository _repository =
      widget.repository ??
      CatalogRepository(apiClient: ApiClient(), tokenStore: TokenStore());

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  DateTime _expiresAt = DateUtils.dateOnly(DateTime.now())
      .add(const Duration(days: 30));

  List<FarmerCategory> _categories = <FarmerCategory>[];
  bool _categoriesLoading = true;
  Object? _categoriesError;
  String _categoryId = '';
  bool _categoryMissing = false;
  bool _isSaving = false;
  bool _uploadingPhoto = false;
  PickedPhoto? _photo;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _categoriesLoading = true;
      _categoriesError = null;
    });
    try {
      final List<FarmerCategory> categories = await _repository
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

  FarmerCategory? get _selectedCategory {
    for (final FarmerCategory category in _categories) {
      if (category.id == _categoryId) return category;
    }
    return null;
  }

  double _parseNumber(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;
  }

  String? _required(String? value, String message) {
    return (value ?? '').trim().isEmpty ? message : null;
  }

  String? _positive(String? value, String message) {
    final double? parsed = double.tryParse(
      (value ?? '').trim().replaceAll(',', '.'),
    );
    return parsed == null || parsed <= 0 ? message : null;
  }

  Future<void> _selectDate() async {
    final DateTime today = DateUtils.dateOnly(DateTime.now());
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: _expiresAt,
      firstDate: today,
      lastDate: DateTime(2100),
      helpText: '¿Hasta cuándo lo vas a vender?',
      cancelText: 'Volver',
      confirmText: 'Guardar',
    );
    if (selected == null || !mounted) return;
    setState(() => _expiresAt = DateUtils.dateOnly(selected));
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    final bool fieldsValid = _formKey.currentState?.validate() ?? false;
    final FarmerCategory? category = _selectedCategory;
    setState(() => _categoryMissing = category == null);
    if (!fieldsValid || category == null) return;
    if (widget.userId.isEmpty) {
      _showMessage('No pudimos publicar. Volvé a entrar.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      String? imageUrl;
      final PickedPhoto? photo = _photo;
      if (photo != null) {
        setState(() => _uploadingPhoto = true);
        imageUrl = await _repository.uploadImage(
          filePath: photo.path,
          filename: photo.filename,
        );
        if (mounted) setState(() => _uploadingPhoto = false);
      }

      final ProductDraft draft = ProductDraft(
        userId: widget.userId,
        name: _nameController.text.trim(),
        variety: 'General',
        unitOfMeasureId: category.defaultUnitOfMeasureId,
        quantityAvailable: _parseNumber(_quantityController.text),
        categoryId: category.id,
        description: _descriptionController.text.trim(),
        price: _parseNumber(_priceController.text),
        expiresAt: _expiresAt,
        imageUrl: imageUrl,
      );

      await _repository.publish(draft);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      _showMessage(_publishErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _uploadingPhoto = false;
        });
      }
    }
  }

  String _publishErrorMessage(Object error) {
    if (error is ApiException) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        return 'No pudimos publicar. Volvé a entrar.';
      }
      if (error.statusCode == 400) {
        return 'Revisá los datos y probá de nuevo.';
      }
      return 'No pudimos publicar. Probá de nuevo.';
    }
    if (error is NetworkException) return error.message;
    return 'No pudimos publicar. Probá de nuevo.';
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whitemodeBackgrund,
      appBar: AppBar(
        backgroundColor: AppColors.blackGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Publicar un producto', style: AppText.appBarText),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _photoStep(),
                      const SizedBox(height: AppSpacing.lg),
                      const Text('Categoría', style: AppText.fieldLabel),
                      const SizedBox(height: 6),
                      _categoryPicker(),
                      if (_categoryMissing) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Elegí una categoría',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      LabeledField(
                        label: 'Nombre del producto',
                        hint: 'Ej. Naranjas',
                        controller: _nameController,
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        validator: (String? value) => _required(
                          value,
                          'Escribí el nombre de tu producto',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      LabeledField(
                        label: 'Precio',
                        hint: 'Ej. 1500',
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        validator: (String? value) =>
                            _positive(value, 'Escribí un precio mayor a cero'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      LabeledField(
                        label: 'Cantidad disponible',
                        hint: 'Ej. 20',
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        validator: (String? value) => _positive(
                          value,
                          'Escribí una cantidad mayor a cero',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _moreData(),
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
                    _uploadingPhoto
                        ? 'Subiendo la foto…'
                        : (_isSaving ? 'Publicando…' : 'Publicar'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoStep() {
    final PickedPhoto? photo = _photo;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dark.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Foto del producto', style: AppText.fieldLabel),
          const SizedBox(height: AppSpacing.sm),
          if (photo == null)
            Row(
              children: [
                const Icon(
                  Icons.photo_camera_outlined,
                  size: 36,
                  color: AppColors.blackGreen,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Mostrá cómo se ve lo que vendés. Con foto te compran más.',
                    style: AppText.bodySecondary,
                  ),
                ),
              ],
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(photo.path),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: _uploadingPhoto ? null : _pickPhoto,
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(photo == null ? 'Elegir una foto' : 'Cambiar la foto'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final PickedPhoto? photo = await widget.photoPicker.pick();
    if (photo == null || !mounted) return;
    setState(() => _photo = photo);
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
      children: _categories.map(_categoryChip).toList(),
    );
  }

  Widget _categoryChip(FarmerCategory category) {
    final bool selected = category.id == _categoryId;
    return ChoiceChip(
      label: Text(category.name),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => setState(() {
        _categoryId = category.id;
        _categoryMissing = false;
      }),
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

  Widget _moreData() {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        iconColor: AppColors.blackGreen,
        collapsedIconColor: AppColors.blackGreen,
        title: const Text('Más datos (opcional)', style: AppText.sectionTitle),
        childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '¿Hasta cuándo lo vas a vender?',
                  style: AppText.fieldLabel,
                ),
              ),
              OutlinedButton.icon(
                onPressed: _selectDate,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.blackGreen,
                  minimumSize: const Size(0, 50),
                  side: const BorderSide(color: AppColors.blackGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                icon: const Icon(Icons.event_outlined, size: 22),
                label: Text(_formatDate(_expiresAt)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          LabeledField(
            label: 'Descripción',
            hint: 'Contá cómo es tu producto',
            controller: _descriptionController,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}

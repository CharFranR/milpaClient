import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/core/token_store.dart';
import 'package:flutter_application_1/features/buyer/supply_request_models.dart';
import 'package:flutter_application_1/features/buyer/supply_request_repository.dart';
import 'package:flutter_application_1/ui/app_tokens.dart';
import 'package:flutter_application_1/ui/labeled_field.dart';

class SupplyRequestFormPage extends StatefulWidget {
  const SupplyRequestFormPage({super.key, this.request, this.repository});

  final SupplyRequest? request;
  final SupplyRequestRepository? repository;

  @override
  State<SupplyRequestFormPage> createState() => _SupplyRequestFormPageState();
}

class _SupplyRequestFormPageState extends State<SupplyRequestFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final SupplyRequestRepository _repository =
      widget.repository ??
      SupplyRequestRepository(apiClient: ApiClient(), tokenStore: TokenStore());

  late final TextEditingController _productController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _totalAmountController;
  late final TextEditingController _numberOfUnitsController;
  late final TextEditingController _amountPerUnitController;
  late final TextEditingController _minAmountController;
  late final TextEditingController _departmentController;
  late final TextEditingController _municipalityController;
  late final TextEditingController _addressController;

  late MeasureUnit _unit;
  late DateTime _requestDeadline;
  late DateTime _deliveryDeadline;
  late bool _multipleProviders;
  bool _isSaving = false;
  String? _dateError;

  bool get _isEditing => widget.request != null;

  @override
  void initState() {
    super.initState();
    final SupplyRequestDraft draft = widget.request == null
        ? _defaultDraft()
        : SupplyRequestDraft.fromRequest(widget.request!);
    _productController = TextEditingController(text: draft.productName);
    _descriptionController = TextEditingController(text: draft.description);
    _totalAmountController = _numberController(draft.totalAmount);
    _numberOfUnitsController = _numberController(draft.numberOfUnits);
    _amountPerUnitController = _numberController(draft.amountPerUnit);
    _minAmountController = _numberController(draft.minAmountPerProvider);
    _departmentController = TextEditingController(text: draft.department);
    _municipalityController = TextEditingController(text: draft.municipality);
    _addressController = TextEditingController(text: draft.addressLine);
    _unit = draft.amountUnit == MeasureUnit.unknown
        ? (draft.unitOfMeasure == MeasureUnit.unknown
              ? MeasureUnit.kilogram
              : draft.unitOfMeasure)
        : draft.amountUnit;
    final DateTime today = DateUtils.dateOnly(DateTime.now());
    _requestDeadline =
        draft.requestDeadline ?? today.add(const Duration(days: 30));
    _deliveryDeadline =
        draft.deliveryDeadline ?? today.add(const Duration(days: 60));
    _multipleProviders = draft.multipleProviders;
  }

  SupplyRequestDraft _defaultDraft() {
    final DateTime today = DateUtils.dateOnly(DateTime.now());
    return SupplyRequestDraft(
      productName: '',
      description: '',
      totalAmount: 0,
      actualAmount: 0,
      amountUnit: MeasureUnit.kilogram,
      numberOfUnits: 0,
      amountPerUnit: 0,
      unitOfMeasure: MeasureUnit.kilogram,
      department: '',
      municipality: '',
      addressLine: '',
      latitude: 0,
      longitude: 0,
      requestDeadline: today.add(const Duration(days: 30)),
      deliveryDeadline: today.add(const Duration(days: 60)),
      multipleProviders: false,
      minAmountPerProvider: 0,
    );
  }

  TextEditingController _numberController(double value) {
    return TextEditingController(text: value == 0 ? '' : _formatNumber(value));
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }

  @override
  void dispose() {
    _productController.dispose();
    _descriptionController.dispose();
    _totalAmountController.dispose();
    _numberOfUnitsController.dispose();
    _amountPerUnitController.dispose();
    _minAmountController.dispose();
    _departmentController.dispose();
    _municipalityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  double _parseNumber(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;
  }

  String? _required(String? value, String label) {
    return (value ?? '').trim().isEmpty ? 'Ingresa $label' : null;
  }

  String? _positive(String? value, String label) {
    final String trimmed = (value ?? '').trim();
    final double? parsed = double.tryParse(trimmed.replaceAll(',', '.'));
    return parsed == null || parsed <= 0 ? 'Ingresa $label' : null;
  }

  Future<void> _selectDate({required bool requestDate}) async {
    final DateTime current = requestDate ? _requestDeadline : _deliveryDeadline;
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: requestDate ? 'Fecha límite' : 'Fecha de entrega',
      cancelText: 'Volver',
      confirmText: 'Aceptar',
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (requestDate) {
        _requestDeadline = DateUtils.dateOnly(selected);
      } else {
        _deliveryDeadline = DateUtils.dateOnly(selected);
      }
      _dateError = null;
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_requestDeadline.isAfter(_deliveryDeadline)) {
      setState(
        () =>
            _dateError = 'La fecha límite no puede ser posterior a la entrega',
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);
    final SupplyRequestDraft draft = SupplyRequestDraft(
      productName: _productController.text.trim(),
      description: _descriptionController.text.trim(),
      totalAmount: _parseNumber(_totalAmountController.text),
      actualAmount: widget.request?.actualAmount ?? 0,
      amountUnit: _unit,
      numberOfUnits: _parseNumber(_numberOfUnitsController.text),
      amountPerUnit: _parseNumber(_amountPerUnitController.text),
      unitOfMeasure: _unit,
      department: _departmentController.text.trim(),
      municipality: _municipalityController.text.trim(),
      addressLine: _addressController.text.trim(),
      latitude: widget.request?.latitude ?? 0,
      longitude: widget.request?.longitude ?? 0,
      requestDeadline: _requestDeadline,
      deliveryDeadline: _deliveryDeadline,
      multipleProviders: _multipleProviders,
      minAmountPerProvider: _multipleProviders
          ? _parseNumber(_minAmountController.text)
          : 0,
    );

    try {
      if (_isEditing) {
        await _repository.update(widget.request!.id, draft);
      } else {
        await _repository.create(draft);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      _showMessage(supplyRequestErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
        title: Text(
          _isEditing ? 'Editar solicitud' : 'Nueva solicitud',
          style: AppText.appBarText,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LabeledField(
                  label: 'Producto',
                  hint: 'Ej. Café pergamino',
                  controller: _productController,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  validator: (String? value) => _required(value, 'producto'),
                ),
                const SizedBox(height: AppSpacing.md),
                LabeledField(
                  label: 'Descripción',
                  hint: 'Contá qué necesitás',
                  controller: _descriptionController,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  maxLines: 3,
                ),
                const SizedBox(height: AppSpacing.md),
                LabeledField(
                  label: 'Cantidad total',
                  hint: 'Ej. 800',
                  controller: _totalAmountController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  validator: (String? value) =>
                      _positive(value, 'cantidad total'),
                ),
                const SizedBox(height: AppSpacing.md),
                LabeledField(
                  label: 'Cantidad de unidades',
                  hint: 'Ej. 100',
                  controller: _numberOfUnitsController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  validator: (String? value) =>
                      _positive(value, 'cantidad de unidades'),
                ),
                const SizedBox(height: AppSpacing.md),
                LabeledField(
                  label: 'Precio por unidad',
                  hint: 'Ej. 8,50',
                  controller: _amountPerUnitController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  validator: (String? value) =>
                      _positive(value, 'precio por unidad'),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Unidad de medida', style: AppText.fieldLabel),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<MeasureUnit>(
                  segments: const <ButtonSegment<MeasureUnit>>[
                    ButtonSegment<MeasureUnit>(
                      value: MeasureUnit.kilogram,
                      label: Text('kg'),
                    ),
                    ButtonSegment<MeasureUnit>(
                      value: MeasureUnit.pound,
                      label: Text('lb'),
                    ),
                    ButtonSegment<MeasureUnit>(
                      value: MeasureUnit.ton,
                      label: Text('ton'),
                    ),
                  ],
                  selected: <MeasureUnit>{_unit},
                  onSelectionChanged: (Set<MeasureUnit> selected) {
                    if (selected.isNotEmpty) {
                      setState(() => _unit = selected.first);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                LabeledField(
                  label: 'Departamento',
                  hint: 'Ej. Masaya',
                  controller: _departmentController,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  validator: (String? value) =>
                      _required(value, 'departamento'),
                ),
                const SizedBox(height: AppSpacing.md),
                LabeledField(
                  label: 'Municipio',
                  hint: 'Ej. Masate',
                  controller: _municipalityController,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  validator: (String? value) => _required(value, 'municipio'),
                ),
                const SizedBox(height: AppSpacing.md),
                LabeledField(
                  label: 'Dirección',
                  hint: 'Dirección de entrega',
                  controller: _addressController,
                  keyboardType: TextInputType.streetAddress,
                  textInputAction: TextInputAction.next,
                  validator: (String? value) => _required(value, 'dirección'),
                ),
                const SizedBox(height: AppSpacing.lg),
                _dateRow(
                  label: 'Fecha límite',
                  date: _requestDeadline,
                  onTap: () => _selectDate(requestDate: true),
                ),
                const SizedBox(height: AppSpacing.sm),
                _dateRow(
                  label: 'Fecha de entrega',
                  date: _deliveryDeadline,
                  onTap: () => _selectDate(requestDate: false),
                ),
                if (_dateError != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _dateError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Proveedores múltiples'),
                  value: _multipleProviders,
                  activeThumbColor: AppColors.blackGreen,
                  onChanged: (bool value) {
                    setState(() => _multipleProviders = value);
                  },
                ),
                if (_multipleProviders) ...[
                  const SizedBox(height: AppSpacing.sm),
                  LabeledField(
                    label: 'Monto mínimo por proveedor',
                    hint: 'Opcional',
                    controller: _minAmountController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  height: 52,
                  child: TextButton(
                    onPressed: _isSaving ? null : _save,
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.blackGreen,
                      disabledBackgroundColor: AppColors.dark.withValues(
                        alpha: 0.12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: _isSaving
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
                        : Text(
                            _isEditing
                                ? 'Guardar cambios'
                                : 'Publicar solicitud',
                            style: AppText.button,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dateRow({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        Expanded(child: Text(label, style: AppText.fieldLabel)),
        OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.blackGreen,
            side: const BorderSide(color: AppColors.blackGreen),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          child: Text(_formatDate(date)),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

String supplyRequestErrorMessage(Object error) {
  if (error is ApiException) {
    if (error.statusCode == 403) {
      return 'Solo los compradores mayoristas pueden hacer esto';
    }
    if (error.statusCode == 409) {
      return 'La solicitud no se puede modificar en este momento';
    }
    if (error.statusCode == 400) return 'Revisá los datos del formulario';
    return 'No se pudo completar la acción. Intenta de nuevo.';
  }
  if (error is NetworkException) return error.message;
  return 'No se pudo completar la acción. Intenta de nuevo.';
}

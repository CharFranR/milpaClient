import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/core/token_store.dart';
import 'package:flutter_application_1/features/buyer/catalog_models.dart';
import 'package:flutter_application_1/features/buyer/liquidation_models.dart';
import 'package:flutter_application_1/features/farmer/lot_models.dart';
import 'package:flutter_application_1/features/farmer/lot_repository.dart';
import 'package:flutter_application_1/ui/app_tokens.dart';
import 'package:flutter_application_1/ui/labeled_field.dart';

class LotFormPage extends StatefulWidget {
  const LotFormPage({super.key, this.repository});

  final LotRepository? repository;

  @override
  State<LotFormPage> createState() => _LotFormPageState();
}

class _LotFormPageState extends State<LotFormPage> {
  static const List<String> _units = <String>[
    'kg',
    'lb',
    'tonelada',
    'unidad',
    'docena',
  ];

  static const List<LiquidationVisibility> _audiences = <LiquidationVisibility>[
    LiquidationVisibility.public,
    LiquidationVisibility.wholesale,
    LiquidationVisibility.wholesaleRetail,
    LiquidationVisibility.wholesaleCorporate,
  ];

  late final LotRepository _repository =
      widget.repository ??
      LotRepository(apiClient: ApiClient(), tokenStore: TokenStore());

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitPriceController = TextEditingController();

  String _unit = 'kg';
  LiquidationVisibility _visibility = LiquidationVisibility.public;
  AllocationMethod _allocation = AllocationMethod.manual;
  DateTime? _expiresAt;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _quantityController.addListener(_onNumbersChanged);
    _unitPriceController.addListener(_onNumbersChanged);
  }

  @override
  void dispose() {
    _quantityController.removeListener(_onNumbersChanged);
    _unitPriceController.removeListener(_onNumbersChanged);
    _productController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  void _onNumbersChanged() => setState(() {});

  double _parseNumber(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;

  String? _required(String? value, String message) =>
      (value ?? '').trim().isEmpty ? message : null;

  String? _positive(String? value, String message) {
    final double parsed = _parseNumber(value ?? '');
    return parsed <= 0 ? message : null;
  }

  Future<void> _selectDate() async {
    final DateTime today = DateUtils.dateOnly(DateTime.now());
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? today.add(const Duration(days: 7)),
      firstDate: today,
      lastDate: DateTime(2100),
      helpText: '¿Hasta cuándo querés mostrarlo?',
      cancelText: 'Volver',
      confirmText: 'Guardar',
    );
    if (selected == null || !mounted) return;
    setState(() => _expiresAt = DateUtils.dateOnly(selected));
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);
    final LotDraft draft = LotDraft(
      productName: _productController.text.trim(),
      quantity: _parseNumber(_quantityController.text),
      unitOfMeasure: _unit,
      unitPrice: _parseNumber(_unitPriceController.text),
      visibility: _visibility,
      allocationMethod: _allocation,
      expiresAt: _expiresAt,
    );
    try {
      await _repository.publish(draft);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      _showMessage(_publishErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
        title: const Text('Publicar un lote', style: AppText.appBarText),
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
                      LabeledField(
                        label: '¿Qué estás vendiendo?',
                        hint: 'Ej. Naranjas',
                        controller: _productController,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        validator: (String? value) =>
                            _required(value, 'Escribí qué estás vendiendo'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      LabeledField(
                        label: '¿Cuánto tenés?',
                        hint: 'Ej. 50',
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        validator: (String? value) =>
                            _positive(value, 'Escribí cuánto tenés'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Text('¿En qué unidad?', style: AppText.fieldLabel),
                      const SizedBox(height: AppSpacing.sm),
                      _chipGroup(
                        options: _units
                            .map((String unit) => (unit, unit))
                            .toList(),
                        selected: _unit,
                        onSelected: (String value) =>
                            setState(() => _unit = value),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      LabeledField(
                        label: '¿Cuánto vale cada uno?',
                        hint: 'Ej. 90',
                        controller: _unitPriceController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        validator: (String? value) =>
                            _positive(value, 'Escribí cuánto vale cada uno'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _totalSummary(),
                      const SizedBox(height: AppSpacing.lg),
                      const Text(
                        '¿Quién puede verlo?',
                        style: AppText.fieldLabel,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _chipGroup(
                        options: _audiences
                            .map(
                              (LiquidationVisibility audience) =>
                                  (audience.wire, audience.label),
                            )
                            .toList(),
                        selected: _visibility.wire,
                        onSelected: (String value) => setState(
                          () => _visibility = LiquidationVisibility.fromWire(
                            value,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const Text(
                        '¿A quién se lo das?',
                        style: AppText.fieldLabel,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _chipGroup(
                        options: const <(String, String)>[
                          ('manual', 'Yo elijo a quién dárselo'),
                          ('first_come', 'El primero que pregunta'),
                        ],
                        selected: _allocation == AllocationMethod.manual
                            ? 'manual'
                            : 'first_come',
                        onSelected: (String value) => setState(
                          () => _allocation = value == 'manual'
                              ? AllocationMethod.manual
                              : AllocationMethod.firstCome,
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
                      : const Icon(Icons.campaign_outlined, size: 28),
                  label: Text(_isSaving ? 'Publicando…' : 'Publicar el lote'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalSummary() {
    final double total =
        _parseNumber(_quantityController.text) *
        _parseNumber(_unitPriceController.text);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.whiteGreen.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        'En total: ${formatPrice(total)}',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.blackGreen,
        ),
      ),
    );
  }

  Widget _chipGroup({
    required List<(String, String)> options,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: options.map((option) {
        final bool isSelected = option.$1 == selected;
        return ChoiceChip(
          label: Text(option.$2),
          selected: isSelected,
          showCheckmark: false,
          onSelected: (_) => onSelected(option.$1),
          labelStyle: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.dark,
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
              color: isSelected ? AppColors.blackGreen : AppTints.border,
              width: 1.5,
            ),
          ),
        );
      }).toList(),
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
                  '¿Hasta cuándo querés mostrarlo?',
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
                label: Text(
                  _expiresAt == null ? 'Elegir' : _formatDate(_expiresAt!),
                ),
              ),
            ],
          ),
          if (_expiresAt != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _expiresAt = null),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.blackGreen,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                icon: const Icon(Icons.close, size: 22),
                label: const Text('Quitar la fecha'),
              ),
            ),
        ],
      ),
    );
  }
}

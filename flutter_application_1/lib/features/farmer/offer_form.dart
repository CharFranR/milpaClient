import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/core/token_store.dart';
import 'package:flutter_application_1/features/buyer/supply_request_models.dart';
import 'package:flutter_application_1/features/farmer/order_models.dart';
import 'package:flutter_application_1/features/farmer/order_repository.dart';
import 'package:flutter_application_1/ui/app_tokens.dart';
import 'package:flutter_application_1/ui/labeled_field.dart';

class OfferFormPage extends StatefulWidget {
  const OfferFormPage({super.key, this.request, this.offer, this.repository});

  final AvailableRequest? request;
  final MyOffer? offer;
  final OrderRepository? repository;

  @override
  State<OfferFormPage> createState() => _OfferFormPageState();
}

class _OfferFormPageState extends State<OfferFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final OrderRepository _repository =
      widget.repository ??
      OrderRepository(apiClient: ApiClient(), tokenStore: TokenStore());

  late final TextEditingController _amountController = TextEditingController(
    text: _initialAmount(),
  );
  late final TextEditingController _priceController = TextEditingController(
    text: _initialPrice(),
  );
  late final TextEditingController _daysController = TextEditingController(
    text: _initialDays().toString(),
  );
  late final TextEditingController _commentController = TextEditingController(
    text: widget.offer?.comments ?? '',
  );

  bool _saving = false;

  bool get _isEditing => widget.offer != null;

  MeasureUnit get _unit =>
      widget.offer?.measurement ?? widget.request!.amountUnit;

  String get _unitWord => switch (_unit) {
    MeasureUnit.kilogram => 'kilos',
    MeasureUnit.pound => 'libras',
    MeasureUnit.ton => 'toneladas',
    MeasureUnit.unknown => 'unidades',
  };

  double get _minAmount => widget.request?.minAmountPerProvider ?? 0;

  String get _productName =>
      widget.offer?.productName ?? widget.request?.productName ?? '';

  @override
  void dispose() {
    _amountController.dispose();
    _priceController.dispose();
    _daysController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  String _initialAmount() {
    final MyOffer? offer = widget.offer;
    if (offer != null) return _plain(offer.totalAmount);
    return _plain(widget.request?.actualAmount ?? 0);
  }

  String _initialPrice() {
    final MyOffer? offer = widget.offer;
    if (offer != null && offer.pricePerUnit > 0) {
      return _plain(offer.pricePerUnit);
    }
    return '';
  }

  int _initialDays() {
    final DateTime? date = widget.offer?.deliveryDate;
    if (date == null) return 7;
    final DateTime today = DateUtils.dateOnly(DateTime.now());
    final int days = DateUtils.dateOnly(date.toLocal())
        .difference(today)
        .inDays;
    return days < 1 ? 1 : days;
  }

  double _parseNumber(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;

  String _plain(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }

  String? _validateAmount(String? value) {
    final double amount = _parseNumber(value ?? '');
    if (amount <= 0) return 'Escribí cuántos $_unitWord ofrecés';
    if (_minAmount > 0 && amount < _minAmount) {
      return 'El comprador pide al menos ${_plain(_minAmount)} ${_unit.label}';
    }
    return null;
  }

  String? _validatePrice(String? value) =>
      _parseNumber(value ?? '') <= 0 ? 'Escribí a cuánto lo vendés' : null;

  String? _validateDays(String? value) => _parseNumber(value ?? '') < 1
      ? 'Escribí en cuántos días lo podés entregar'
      : null;

  Future<void> _submit() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    final int days = _parseNumber(_daysController.text).round().clamp(1, 3650);
    final OfferDraft draft = OfferDraft(
      supplyRequestId: widget.offer?.supplyRequestId ?? widget.request!.id,
      totalAmount: _parseNumber(_amountController.text),
      pricePerUnit: _parseNumber(_priceController.text),
      measurement: _unit,
      deliveryDay: DateUtils.dateOnly(DateTime.now()).add(Duration(days: days)),
      comments: _commentController.text,
    );

    try {
      final MyOffer? offer = widget.offer;
      if (offer == null) {
        await _repository.offerOn(draft);
      } else {
        await _repository.updateOffer(offer.id, draft);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      _showMessage(_submitErrorMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _submitErrorMessage(Object error) {
    if (error is ApiException) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        return 'No pudimos enviar tu oferta. Volvé a entrar.';
      }
      if (error.statusCode == 400) {
        return 'Revisá la cantidad y el precio, y probá de nuevo.';
      }
      if (error.statusCode == 409) {
        return 'Ese pedido ya no está disponible. Probá con otro.';
      }
      return 'No pudimos enviar tu oferta. Probá de nuevo.';
    }
    if (error is NetworkException) return error.message;
    return 'No pudimos enviar tu oferta. Probá de nuevo.';
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
          _isEditing ? 'Cambiar mi oferta' : 'Ofertar',
          style: AppText.appBarText,
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_productName.isNotEmpty) ...[
                        _productBox(),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      LabeledField(
                        label: '¿Cuántos $_unitWord ofrecés?',
                        hint: 'Ej. 300',
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        validator: _validateAmount,
                      ),
                      if (_minAmount > 0) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'El comprador pide al menos '
                          '${_plain(_minAmount)} ${_unit.label}.',
                          style: AppText.bodySecondary,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      LabeledField(
                        label: '¿A cuánto lo vendés?',
                        hint: 'Precio por ${_unit.label}. Ej. 1500',
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        validator: _validatePrice,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _daysSection(),
                      const SizedBox(height: AppSpacing.lg),
                      LabeledField(
                        label: 'Comentario (si querés)',
                        hint: 'Contale cómo lo entregás',
                        controller: _commentController,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        maxLines: 3,
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
                  onPressed: _saving ? null : _submit,
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
                  icon: _saving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_outlined, size: 28),
                  label: Text(_saving ? 'Enviando…' : 'Enviar mi oferta'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productBox() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.whiteGreen.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.eco_outlined, size: 30, color: AppColors.blackGreen),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pedido de un comprador', style: AppText.fieldLabel),
                const SizedBox(height: 2),
                Text(_productName, style: AppText.headline),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _daysSection() {
    final int selected = _parseNumber(_daysController.text).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '¿En cuántos días lo podés entregar?',
          style: AppText.fieldLabel,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final int days in <int>[3, 7, 15]) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      setState(() => _daysController.text = days.toString()),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: selected == days
                        ? AppColors.whiteGreen.withValues(alpha: 0.22)
                        : Colors.white,
                    foregroundColor: AppColors.blackGreen,
                    minimumSize: const Size(0, 54),
                    padding: EdgeInsets.zero,
                    side: BorderSide(
                      color: selected == days
                          ? AppColors.blackGreen
                          : AppTints.border,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text('$days días'),
                ),
              ),
              if (days != 15) const SizedBox(width: AppSpacing.sm),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        LabeledField(
          label: 'Otro plazo',
          hint: 'Ej. 10',
          controller: _daysController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          validator: _validateDays,
          onFieldSubmitted: (_) => _submit(),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/core/models/auth_models.dart';
import 'package:flutter_application_1/features/auth/session_controller.dart';
import 'package:flutter_application_1/ui/app_tokens.dart';
import 'package:flutter_application_1/ui/labeled_field.dart';

const double _kWideBreakpoint = 600;

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _municipalityController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isSaving = false;
  bool _prefilled = false;

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = SessionScope.of(context);
    if (session.user == null) {
      session.loadUser();
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    _municipalityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  static String _digitsOnly(String value) =>
      value.replaceAll(RegExp(r'[^0-9]'), '');

  void _prefill(User user) {
    _prefilled = true;
    _firstNameController.text = user.firstName;
    _lastNameController.text = user.lastName;
    _emailController.text = user.email;
    _phoneController.text = user.phoneNumber;
    _departmentController.text = user.department;
    _municipalityController.text = user.municipality;
    _addressController.text = user.addressLine;
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();
    final session = SessionScope.of(context);
    setState(() => _isSaving = true);

    try {
      await session.updateProfile(
        email: _emailController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _digitsOnly(_phoneController.text.trim()),
        department: _departmentController.text.trim(),
        municipality: _municipalityController.text.trim(),
        address: _addressController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).maybePop();
    } catch (error) {
      if (!mounted) return;
      _showMessage(_saveErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _saveErrorMessage(Object error) {
    if (error is ApiException) {
      if (error.statusCode == 409) return 'Ese correo ya está registrado';
      return 'No se pudo guardar. Intenta de nuevo.';
    }
    if (error is NetworkException) return error.message;
    return 'No se pudo guardar. Intenta de nuevo.';
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      backgroundColor: AppColors.blackGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Volver',
      ),
      title: const Text('Editar perfil', style: AppText.appBarText),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final User? user = session.user;
    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.whitemodeBackgrund,
        appBar: _appBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (!_prefilled) _prefill(user);

    return Scaffold(
      backgroundColor: AppColors.whitemodeBackgrund,
      appBar: _appBar(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool isWide = constraints.maxWidth >= _kWideBreakpoint;
            final double horizontalPadding = isWide ? AppSpacing.xl : 24;
            final double maxContentWidth = isWide ? 520 : 420;

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.md,
                horizontalPadding,
                AppSpacing.xl,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _pairedFields(
                          isWide,
                          _firstNameField(),
                          _lastNameField(),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _emailField(),
                        const SizedBox(height: AppSpacing.md),
                        _phoneField(),
                        const SizedBox(height: AppSpacing.md),
                        _pairedFields(
                          isWide,
                          _departmentField(),
                          _municipalityField(),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _addressField(),
                        const SizedBox(height: AppSpacing.xl),
                        _saveButton(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _firstNameField() {
    return LabeledField(
      label: 'Nombre',
      hint: 'Juan',
      controller: _firstNameController,
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.next,
      autofillHints: const <String>[AutofillHints.givenName],
      validator: _required('Ingresa tu nombre'),
    );
  }

  Widget _lastNameField() {
    return LabeledField(
      label: 'Apellido',
      hint: 'Pérez',
      controller: _lastNameController,
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.next,
      autofillHints: const <String>[AutofillHints.familyName],
      validator: _required('Ingresa tu apellido'),
    );
  }

  Widget _emailField() {
    return LabeledField(
      label: 'Correo',
      hint: 'usuario@ejemplo.com',
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: const <String>[AutofillHints.email],
      validator: _validateEmail,
    );
  }

  Widget _phoneField() {
    return LabeledField(
      label: 'Teléfono',
      hint: 'Número de teléfono',
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      autofillHints: const <String>[AutofillHints.telephoneNumber],
    );
  }

  Widget _departmentField() {
    return LabeledField(
      label: 'Departamento',
      hint: 'Ej. Masaya',
      controller: _departmentController,
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _municipalityField() {
    return LabeledField(
      label: 'Municipio',
      hint: 'Ej. Masate',
      controller: _municipalityController,
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _addressField() {
    return LabeledField(
      label: 'Dirección',
      hint: 'Dirección',
      controller: _addressController,
      keyboardType: TextInputType.streetAddress,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _save(),
    );
  }

  Widget _saveButton() {
    return SizedBox(
      height: 52,
      child: TextButton(
        onPressed: _isSaving ? null : _save,
        style: TextButton.styleFrom(
          backgroundColor: AppColors.blackGreen,
          disabledBackgroundColor: AppColors.dark.withValues(alpha: 0.12),
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
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text('Guardar cambios', style: AppText.button),
      ),
    );
  }

  Widget _pairedFields(bool isWide, Widget left, Widget right) {
    if (!isWide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          left,
          const SizedBox(height: AppSpacing.md),
          right,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: left),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: right),
      ],
    );
  }

  FormFieldValidator<String> _required(String message) {
    return (String? value) => (value ?? '').trim().isEmpty ? message : null;
  }

  String? _validateEmail(String? value) {
    final String email = (value ?? '').trim();
    if (email.isEmpty) return 'Ingresa tu correo electrónico';
    if (!_emailPattern.hasMatch(email)) return 'Ingresa un correo válido';
    return null;
  }
}

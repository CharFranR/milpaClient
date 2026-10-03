import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/features/auth/register_models.dart';
import 'package:flutter_application_1/features/auth/session_controller.dart';
import 'package:flutter_application_1/ui/app_tokens.dart';
import 'package:flutter_application_1/ui/labeled_field.dart';

/// Ancho a partir del cual el formulario pasa a dos columnas.
///
/// Se decide por el ancho disponible, NO por `MediaQuery.orientation` ni por
/// el tipo de dispositivo: la documentación oficial de adaptive layout lo
/// descarta porque la orientación no dice nada sobre cuánto espacio hay.
const double _kWideBreakpoint = 600;

/// Mínimo y máximo de dígitos que se aceptan como teléfono.
const int _kPhoneMinDigits = 8;
const int _kPhoneMaxDigits = 15;

/// Formulario de registro de Milpa.
class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _municipalityController = TextEditingController();

  /// `null` significa "todavía no eligió". El botón de enviar permanece
  /// deshabilitado mientras esté en `null`.
  RegisterRole? _role;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _departmentController.dispose();
    _municipalityController.dispose();
    super.dispose();
  }

  /// El backend guarda el teléfono como string plano y no lo normaliza, así
  /// que se envía solo dígitos. No se agrega código de país: no hay catálogo
  /// que confirme el prefijo y adivinarlo sends false location data.
  static String _digitsOnly(String value) =>
      value.replaceAll(RegExp(r'[^0-9]'), '');

  bool get _canSubmit => _role != null && !_isSubmitting;

  Future<void> _submit() async {
    if (_role == null || _isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();
    final session = SessionScope.of(context);
    setState(() => _isSubmitting = true);

    try {
      await session.signUp(
        email: _emailController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _digitsOnly(_phoneController.text.trim()),
        role: _role!.roleId,
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
        department: _departmentController.text.trim(),
        municipality: _municipalityController.text.trim(),
      );
      // Cierra el autofill para que el gestor de contraseñas del sistema pueda
      // guardar (o descartar) lo escrito.
      TextInput.finishAutofillContext();
      if (!mounted) return;
      Navigator.of(context).maybePop();
    } catch (error) {
      if (!mounted) return;
      _showMessage(_registerErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _registerErrorMessage(Object error) {
    if (error is ApiException) {
      if (error.statusCode == 409) return 'Ese correo ya está registrado';
      if (error.statusCode == 400) return 'Revisá los datos del formulario';
      return 'No se pudo crear la cuenta. Intenta de nuevo.';
    }
    if (error is NetworkException) return error.message;
    return 'No se pudo crear la cuenta. Intenta de nuevo.';
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool isWide = constraints.maxWidth >= _kWideBreakpoint;
            final double horizontalPadding = isWide ? AppSpacing.xl : 24;
            final double maxContentWidth = isWide ? 520 : 420;

            return SingleChildScrollView(
              // El teclado tapa la parte baja del formulario; con scroll el
              // usuario la puede uncovering arrastrando.
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.sm,
                horizontalPadding,
                AppSpacing.xl,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  child: AutofillGroup(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _BackButton(),
                          const SizedBox(height: AppSpacing.md),
                          const Text(
                            'Crear cuenta',
                            style: AppText.screenTitle,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Crea tu cuenta en Milpa',
                            style: AppText.bodySecondary,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          ..._roleSection(),
                          ..._personalDataSection(isWide),
                          ..._locationSection(isWide),
                          _submitButton(),
                          const SizedBox(height: AppSpacing.xl),
                          _loginFooter(),
                        ],
                      ),
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

  // ───────────────────────── SOY… ─────────────────────────

  List<Widget> _roleSection() {
    final bool isBuyer =
        _role == RegisterRole.compradorMinorista ||
        _role == RegisterRole.compradorMayoristaDetallista ||
        _role == RegisterRole.compradorMayoristaCorporativo;

    return <Widget>[
      const Text('Soy…', style: AppText.sectionTitle),
      const SizedBox(height: AppSpacing.sm),
      // IntrinsicHeight iguala la altura de las dos tarjetas sin pedirle una
      // altura al Row (que dentro de un scroll la tiene infinita).
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: _RoleCard(
                title: 'Comprador',
                description: 'Quiero comprar productos',
                assetPath: 'assets/comprador.png',
                selected: isBuyer,
                onTap: () =>
                    setState(() => _role = RegisterRole.compradorMinorista),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _RoleCard(
                title: 'Productor',
                description: 'Quiero vender mis cosechas',
                assetPath: 'assets/productor.png',
                selected: _role == RegisterRole.agricultor,
                onTap: () => setState(() => _role = RegisterRole.agricultor),
              ),
            ),
          ],
        ),
      ),
      if (isBuyer) ...<Widget>[
        const SizedBox(height: AppSpacing.md),
        Text('Tipo de comprador', style: AppText.caption),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            _BuyerTypeChip(
              label: 'Minorista',
              selected: _role == RegisterRole.compradorMinorista,
              onTap: () =>
                  setState(() => _role = RegisterRole.compradorMinorista),
            ),
            _BuyerTypeChip(
              label: 'Detallista',
              selected: _role == RegisterRole.compradorMayoristaDetallista,
              onTap: () => setState(
                () => _role = RegisterRole.compradorMayoristaDetallista,
              ),
            ),
            _BuyerTypeChip(
              label: 'Corporativo',
              selected: _role == RegisterRole.compradorMayoristaCorporativo,
              onTap: () => setState(
                () => _role = RegisterRole.compradorMayoristaCorporativo,
              ),
            ),
          ],
        ),
      ],
      const SizedBox(height: AppSpacing.xl),
    ];
  }

  // ───────────────────── DATOS PERSONALES ─────────────────────

  List<Widget> _personalDataSection(bool isWide) {
    final Widget firstName = LabeledField(
      label: 'Nombre',
      hint: 'Juan',
      controller: _firstNameController,
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.next,
      autofillHints: const <String>[AutofillHints.givenName],
      validator: _required('Ingresa tu nombre'),
    );

    final Widget lastName = LabeledField(
      label: 'Apellido',
      hint: 'Pérez',
      controller: _lastNameController,
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.next,
      autofillHints: const <String>[AutofillHints.familyName],
      validator: _required('Ingresa tu apellido'),
    );

    final Widget email = LabeledField(
      label: 'Correo electrónico',
      hint: 'usuario@ejemplo.com',
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: const <String>[AutofillHints.email],
      validator: _validateEmail,
    );

    final Widget phone = LabeledField(
      label: 'Teléfono',
      hint: 'Número de teléfono',
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      autofillHints: const <String>[AutofillHints.telephoneNumber],
      validator: _validatePhone,
    );

    final Widget password = LabeledField(
      label: 'Contraseña',
      hint: '••••••••',
      controller: _passwordController,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.next,
      autofillHints: const <String>[AutofillHints.newPassword],
      suffix: _visibilityToggle(
        isObscured: _obscurePassword,
        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
      ),
      validator: _validatePassword,
    );

    final Widget confirmPassword = LabeledField(
      label: 'Confirmar contraseña',
      hint: '••••••••',
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      textInputAction: TextInputAction.done,
      autofillHints: const <String>[AutofillHints.newPassword],
      onFieldSubmitted: (_) => _submit(),
      suffix: _visibilityToggle(
        isObscured: _obscureConfirmPassword,
        onPressed: () =>
            setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
      ),
      validator: _validateConfirmPassword,
    );

    return <Widget>[
      const Text('Datos personales', style: AppText.sectionTitle),
      const SizedBox(height: AppSpacing.sm),
      _pairedFields(isWide, firstName, lastName),
      const SizedBox(height: AppSpacing.md),
      email,
      const SizedBox(height: AppSpacing.md),
      phone,
      const SizedBox(height: AppSpacing.md),
      _pairedFields(isWide, password, confirmPassword),
      const SizedBox(height: AppSpacing.xl),
    ];
  }

  // ───────────────────────── UBICACIÓN ─────────────────────────

  List<Widget> _locationSection(bool isWide) {
    // Sin validadores: el backend acepta estas dos como texto libre y
    // opcionales. No existe endpoint de catálogo de departamentos/municipios.
    final Widget department = LabeledField(
      label: 'Departamento / Provincia',
      hint: 'Ej. Masaya',
      controller: _departmentController,
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.next,
    );

    final Widget municipality = LabeledField(
      label: 'Municipio',
      hint: 'Ej. Masate',
      controller: _municipalityController,
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.next,
    );

    return <Widget>[
      const Text('Ubicación', style: AppText.sectionTitle),
      const SizedBox(height: AppSpacing.sm),
      _pairedFields(isWide, department, municipality),
      const SizedBox(height: AppSpacing.xl),
    ];
  }

  // ───────────────────────── ENVÍO ─────────────────────────

  Widget _submitButton() {
    return SizedBox(
      height: 52,
      child: TextButton(
        onPressed: _canSubmit ? _submit : null,
        style: TextButton.styleFrom(
          backgroundColor: AppColors.blackGreen,
          disabledBackgroundColor: AppColors.dark.withValues(alpha: 0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text('Crear cuenta', style: AppText.button),
      ),
    );
  }

  Widget _loginFooter() {
    // `Wrap` y no `Row`: con la fuente del sistema escalada por accesibilidad
    // el `Row` se salía del ancho disponible.
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.xs,
      children: <Widget>[
        const Text('¿Ya tienes cuenta?', style: AppText.body),
        GestureDetector(
          // Vuelve a la pantalla de login, que es de donde se llega aquí.
          // Si esta vista es la raíz, maybePop no hace nada.
          onTap: () {
            Navigator.of(context).maybePop();
          },
          child: const Text('Iniciar sesión', style: AppText.link),
        ),
      ],
    );
  }

  // ───────────────────────── HELPERS ─────────────────────────

  /// Dos campos juntos en pantallas anchas, uno debajo del otro en angostas.
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

  Widget _visibilityToggle({
    required bool isObscured,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        isObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        size: 20,
        color: AppTints.muted,
      ),
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

  String? _validatePhone(String? value) {
    final String raw = (value ?? '').trim();
    if (raw.isEmpty) return 'Ingresa tu número de teléfono';
    final int digits = _digitsOnly(raw).length;
    if (digits < _kPhoneMinDigits || digits > _kPhoneMaxDigits) {
      return 'Ingresa un teléfono de $_kPhoneMinDigits a $_kPhoneMaxDigits dígitos';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final String password = value ?? '';
    if (password.isEmpty) return 'Ingresa una contraseña';
    if (password.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final String confirm = value ?? '';
    if (confirm.isEmpty) return 'Confirma tu contraseña';
    if (confirm != _passwordController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }
}

// ───────────────────────── BACK ─────────────────────────

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        // maybePop ya no hace nada si no hay ruta debajo, así que no hace
        // falta preguntar por canPop() antes.
        onPressed: () {
          Navigator.of(context).maybePop();
        },
        tooltip: 'Volver',
        icon: const Icon(Icons.arrow_back, size: 22, color: AppColors.dark),
      ),
    );
  }
}

// ───────────────────────── TARJETA DE ROL ─────────────────────────

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.description,
    required this.assetPath,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;

  /// Ilustración del Figma, no un ícono de Material: son piezas de marca a
  /// color y no admiten tinte.
  final String assetPath;

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = selected
        ? AppColors.blackGreen
        : AppColors.dark.withValues(alpha: AppAlpha.border);

    return Material(
      // El tinte vive en el Material para que el ripple de InkWell se vea.
      color: selected
          ? AppColors.blackGreen.withValues(alpha: 0.06)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
            boxShadow: selected
                ? <BoxShadow>[
                    BoxShadow(
                      color: AppColors.blackGreen.withValues(alpha: 0.15),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : const <BoxShadow>[],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Image.asset(
                assetPath,
                width: 44,
                height: 44,
                fit: BoxFit.contain,
                // Los PNG exportados de Figma vienen a 512x512 y se muestran a
                // 44px: sin esto cada escala del árbol es un salto grande de memoria.
                filterQuality: FilterQuality.medium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.blackGreen : AppColors.dark,
                ),
              ),
              const SizedBox(height: 2),
              Text(description, style: AppText.caption),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuyerTypeChip extends StatelessWidget {
  const _BuyerTypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.blackGreen : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected ? Colors.transparent : AppColors.blackGreen,
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.blackGreen,
            ),
          ),
        ),
      ),
    );
  }
}

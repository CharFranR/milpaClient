import 'package:flutter/material.dart';
import 'package:flutter_application_1/presets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  // Estado del teclado según su DIRECCIÓN (sube/baja), no según llegue a 0.
  bool _keyboardOpen = false;
  double _lastInset = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    final inset = View.of(context).viewInsets.bottom;

    // Sube → abierto. Baja → cerrado (desde el PRIMER frame de cierre).
    final bool? next = inset > _lastInset
        ? true
        : inset < _lastInset
            ? false
            : null;
    _lastInset = inset;

    if (next != null && next != _keyboardOpen) {
      setState(() => _keyboardOpen = next);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Inicio de sesión correcto')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whitemodeBackgrund,
      body: SafeArea(
        child: Center(
          // Responsive para tablet: no se estira más allá de 420dp.
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    children: [
                      // ───── CABECERA FLEXIBLE ─────
                      // Ocupa el espacio sobrante. FittedBox es la red de
                      // seguridad: si aun así no cabe, se escala.
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: FittedBox(
                            // fit: BoxFit.scaleDown,
                            alignment: Alignment.center,
                            child: _Header(compact: _keyboardOpen),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ───── BLOQUE FIJO ─────
                      _LabeledField(
                        label: 'Correo electrónico',
                        hint: 'usuario@ejemplo.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        validator: (v) {
                          final email = v?.trim() ?? '';
                          if (email.isEmpty) {
                            return 'Ingrese su correo electrónico';
                          }
                          final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                          if (!re.hasMatch(email)) {
                            return 'Ingrese un correo válido';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      _LabeledField(
                        label: 'Contraseña',
                        hint: '••••••••',
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _login(),
                        validator: (v) {
                          final p = v ?? '';
                          if (p.isEmpty) return 'Ingrese su contraseña';
                          if (p.length < 6) {
                            return 'Debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                        suffix: IconButton(
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                            color: AppColors.dark.withValues(alpha: 0.5),
                          ),
                        ),
                      ),

                      // ───── ¿OLVIDASTE TU CONTRASEÑA? ─────
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {}, // TODO: recuperar contraseña
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            '¿Olvidaste tu contraseña?',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.blackGreen,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ───── BOTÓN INICIAR SESIÓN ─────
                      SizedBox(
                        height: 52,
                        width: double.infinity,
                        child: TextButton(
                          onPressed: _isLoading ? null : _login,
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.blackGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      AppColors.whitemodeBackgrund,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Iniciar sesión',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.whitemodeBackgrund,
                                  ),
                                ),
                        ),
                      ),

                      // ───── SECUNDARIO: divisor + Google (se oculta) ─────
                      _Collapsible(
                        show: !_keyboardOpen,
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: AppColors.dark.withValues(alpha: 0.15),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    'o',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.dark.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: AppColors.dark.withValues(alpha: 0.15),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 52,
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: null, // TODO: Google Sign-In
                                icon: const Icon(Icons.g_mobiledata, size: 28),
                                label: const Text(
                                  'Continuar con Google',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.blackGreen,
                                  side: BorderSide(color: AppColors.blackGreen),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ───── CREAR CUENTA: abajo, se desvanece con teclado ─────
                      Expanded(
                         flex: _keyboardOpen ? 0 : 1,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 250),
                              opacity: _keyboardOpen ? 0 : 1,
                              child: const _SignUpRow(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── COLAPSABLE ─────────────────────────
/// Colapsa/expande su hijo con animación de altura + fade.
class _Collapsible extends StatelessWidget {
  const _Collapsible({required this.show, required this.child});

  final bool show;
  final Widget child;

  static const _duration = Duration(milliseconds: 250);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedAlign(
        duration: _duration,
        curve: Curves.easeOut,
        alignment: Alignment.topCenter,
        heightFactor: show ? 1.0 : 0.0,
        child: AnimatedOpacity(
          duration: _duration,
          curve: Curves.easeOut,
          opacity: show ? 1.0 : 0.0,
          child: child,
        ),
      ),
    );
  }
}

// ───────────────────────── HEADER ─────────────────────────
class _Header extends StatelessWidget {
  const _Header({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Collapsible(
            show: !compact,
            child: Column(
              children: [
                Image.asset(
                  'assets/LogoApp.png',
                  width: 90,
                  height: 90,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.dark,
            ),
            child: const Text(
              'Bienvenido a Milpa',
              textAlign: TextAlign.center,
            ),
          ),
          _Collapsible(
            show: !compact,
            child: Column(
              children: [
                const SizedBox(height: 4),
                Text(
                  'Inicia sesión para continuar',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.dark.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────── CAMPO CON LABEL ENCIMA ───────────────────
class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.onFieldSubmitted,
    this.suffix,
    this.validator,
    this.autofillHints,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final ValueChanged<String>? onFieldSubmitted;
  final Widget? suffix;
  final FormFieldValidator<String>? validator;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          onFieldSubmitted: onFieldSubmitted,
          validator: validator,
          autofillHints: autofillHints,
          // fontSize >= 16 evita el zoom automático en navegadores móviles.
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.dark.withValues(alpha: 0.35),
              fontSize: 15,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
            suffixIcon: suffix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: AppColors.dark.withValues(alpha: 0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: AppColors.dark.withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: AppColors.blackGreen,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────── CREAR CUENTA (abajo) ───────────────────
class _SignUpRow extends StatelessWidget {
  const _SignUpRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿No tienes cuenta? ',
          style: TextStyle(fontSize: 14, color: AppColors.dark),
        ),
        GestureDetector(
          onTap: () {}, 
          child: Text(
            'Crear cuenta',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.blackGreen,
            ),
          ),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_application_1/ui/app_tokens.dart';

/// Campo de formulario con el label encima del input.
///
/// Extraído de `login.dart` para que login y register compartan exactamente
/// el mismo control: mismo radio, mismos estados de borde y el mismo
/// `fontSize: 16` que evita el zoom automático en navegadores móviles.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.maxLines = 1,
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

  /// `1` en campos normales. Súbelo solo para textos largos; con
  /// [obscureText] debe quedarse en `1`.
  final int maxLines;

  final ValueChanged<String>? onFieldSubmitted;
  final Widget? suffix;
  final FormFieldValidator<String>? validator;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.fieldLabel),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          maxLines: maxLines,
          onFieldSubmitted: onFieldSubmitted,
          validator: validator,
          autofillHints: autofillHints,
          // fontSize >= 16 evita el zoom automático en navegadores móviles.
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: AppText.hint,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
            suffixIcon: suffix,
            border: _border(AppTints.border, 1),
            enabledBorder: _border(AppTints.border, 1),
            focusedBorder: _border(AppColors.blackGreen, 1.5),
            errorBorder: _border(Colors.red, 1.2),
            focusedErrorBorder: _border(Colors.red, 1.5),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

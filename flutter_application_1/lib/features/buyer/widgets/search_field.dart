import 'package:flutter/material.dart';
import 'package:flutter_application_1/ui/app_tokens.dart';

/// Campo de búsqueda para las cabeceras verdes del comprador.
class SearchField extends StatelessWidget {
  const SearchField({super.key, required this.hint});

  /// Texto de ayuda que se muestra con el campo vacío.
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.search, color: Colors.white70, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              textInputAction: TextInputAction.search,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

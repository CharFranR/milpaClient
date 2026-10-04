import 'package:flutter/material.dart';
import 'package:flutter_application_1/ui/app_tokens.dart';

class FarmerProductsPage extends StatelessWidget {
  const FarmerProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _EmptyState(
      icon: Icons.inventory_2_outlined,
      title: 'Mis productos',
      message: 'Todavía no hay productos acá.',
      hint:
          'Primero vas a poder cargar lo que tenés para vender desde '
          'esta pantalla.',
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.hint,
  });

  final IconData icon;
  final String title;
  final String message;
  final String hint;

  @override
  Widget build(BuildContext context) {
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
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(hint, textAlign: TextAlign.center, style: AppText.body),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/auth/session_controller.dart';
import 'package:flutter_application_1/ui/app_tokens.dart';

class FarmerHome extends StatelessWidget {
  const FarmerHome({
    super.key,
    this.onProducts,
    this.onOrders,
    this.onMessages,
    this.onAccount,
  });

  final VoidCallback? onProducts;
  final VoidCallback? onOrders;
  final VoidCallback? onMessages;
  final VoidCallback? onAccount;

  @override
  Widget build(BuildContext context) {
    final String firstName = SessionScope.of(context).user?.firstName ?? '';
    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        top: AppSpacing.lg,
        bottom: AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  firstName.isEmpty ? 'Hola' : 'Hola, $firstName',
                  style: AppText.screenTitle,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text('¿Qué querés hacer hoy?', style: AppText.bodySecondary),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _HomeCard(
            icon: Icons.inventory_2_outlined,
            title: 'Mis productos',
            description: 'Cargá y mirá lo que tenés para vender.',
            onTap: onProducts,
          ),
          _HomeCard(
            icon: Icons.receipt_long_outlined,
            title: 'Pedidos',
            description: 'Mirá los pedidos de los compradores.',
            onTap: onOrders,
          ),
          _HomeCard(
            icon: Icons.chat_bubble_outline,
            title: 'Mensajes',
            description: 'Hablá con los compradores.',
            onTap: onMessages,
          ),
          _HomeCard(
            icon: Icons.account_circle_outlined,
            title: 'Mi cuenta',
            description: 'Mirá tus datos y cerrá tu sesión.',
            onTap: onAccount,
          ),
        ],
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  const _HomeCard({
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: AppSpacing.md,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppTints.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.whiteGreen.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(icon, size: 32, color: AppColors.blackGreen),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(description, style: AppText.bodySecondary),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 26, color: AppTints.hint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

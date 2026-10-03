import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/buyer/mock_data.dart';
import 'package:flutter_application_1/features/buyer/widgets/product_card.dart';
import 'package:flutter_application_1/features/buyer/widgets/search_field.dart';
import 'package:flutter_application_1/ui/app_tokens.dart';

/// Exploración del catálogo con buscador, chips y filtros.
class BuyerExplore extends StatefulWidget {
  const BuyerExplore({super.key});

  @override
  State<BuyerExplore> createState() => _BuyerExploreState();
}

class _BuyerExploreState extends State<BuyerExplore> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whitemodeBackgrund,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.blackGreen,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Explorar',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const SearchField(hint: 'Buscar productos...'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: const [
                          _CategoryChip(label: 'Todos', active: true),
                          SizedBox(width: 8),
                          _CategoryChip(label: 'Verduras'),
                          SizedBox(width: 8),
                          _CategoryChip(label: 'Frutas'),
                          SizedBox(width: 8),
                          _CategoryChip(label: 'Lácteos'),
                          SizedBox(width: 8),
                          _CategoryChip(label: 'Carnes'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      children: const [
                        _FilterPill(icon: Icons.tune, label: 'Filtros'),
                        SizedBox(width: 8),
                        _FilterPill(icon: Icons.swap_vert, label: 'Precio'),
                        SizedBox(width: 8),
                        _FilterPill(icon: Icons.star, label: 'Valoración'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Text(
                      '124 productos encontrados',
                      style: TextStyle(fontSize: 13, color: AppTints.muted),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.8,
                    children: mockProducts
                        .map((p) => ProductCard(product: p))
                        .toList(),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip de categoría sobre la cabecera verde.
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, this.active = false});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF064407) : null,
        border: active ? null : Border.all(color: Colors.white, width: 1.2),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Pastilla de filtro rápida sobre el contenido claro.
class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.blackGreen, width: 1.2),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.blackGreen),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.blackGreen,
            ),
          ),
        ],
      ),
    );
  }
}

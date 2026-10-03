import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/ui/app_tokens.dart';

const Color _sectionAccent = Color(0xff2563eb);

const Color _editProfileButton = Color(0xff064407);


const String _buyerName = 'Oscar Francisco Reyes Guevara';
const String _buyerEmail = 'oscar@milpa.com';

class BuyerProfile extends StatefulWidget {
  const BuyerProfile({super.key});

  @override
  State<BuyerProfile> createState() => _BuyerProfileState();
}

class _BuyerProfileState extends State<BuyerProfile> {
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.whitemodeBackgrund,
        body: Column(
          children: [
            const _ProfileHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  top: AppSpacing.lg,
                  bottom: AppSpacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SectionHeader(
                      icon: Icons.person,
                      label: 'DATOS PERSONALES',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const _InfoCard(
                      rows: [
                        _ProfileRowData(
                          title: 'Nombre completo',
                          value: _buyerName,
                        ),
                        _ProfileRowData(title: 'Correo', value: _buyerEmail),
                        _ProfileRowData(
                          title: 'Teléfono',
                          value: '+505 8888 1234',
                        ),
                        _ProfileRowData(
                          title: 'Ubicación',
                          value: 'Managua, Nicaragua',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const _SectionHeader(
                      icon: Icons.settings,
                      label: 'CONFIGURACIÓN',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const _InfoCard(
                      rows: [
                        _ProfileRowData(
                          title: 'Notificaciones',
                          value: 'Activadas',
                        ),
                        _ProfileRowData(title: 'Idioma', value: 'Español'),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const _SectionHeader(
                      icon: Icons.lock_outline,
                      label: 'SEGURIDAD',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const _InfoCard(
                      rows: [
                        _ProfileRowData(title: 'Cambiar contraseña'),
                        _ProfileRowData(title: 'Cerrar sesión'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cabecera verde con avatar, identidad del comprador y acción de edición.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.blackGreen,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            children: [
              const _ProfileAvatar(),
              const SizedBox(height: AppSpacing.md),
              const Text(
                _buyerName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                _buyerEmail,
                style: TextStyle(fontSize: 13, color: AppColors.yelow),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: _editProfileButton,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Editar perfil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Image.asset(
        'assets/oscar.png',
        width: 88,
        height: 88,
        fit: BoxFit.cover,
      ),
    );
  }
}

/// Título de sección: ícono + etiqueta en mayúsculas y azul.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _sectionAccent),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _sectionAccent,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card blanca con filas separadas por divisores.
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});

  final List<_ProfileRowData> rows;

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [];
    for (int i = 0; i < rows.length; i++) {
      if (i > 0) {
        children.add(
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.dark.withValues(alpha: 0.08),
          ),
        );
      }
      children.add(_ProfileRow(data: rows[i]));
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dark.withValues(alpha: 0.06)),
      ),
      child: Column(children: children),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.data});

  final _ProfileRowData data;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dark,
                    ),
                  ),
                  if (data.value != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      data.value!,
                      style: TextStyle(fontSize: 13, color: AppTints.secondary),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 22, color: AppTints.hint),
          ],
        ),
      ),
    );
  }
}

class _ProfileRowData {
  const _ProfileRowData({required this.title, this.value});

  final String title;
  final String? value;
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/models/auth_models.dart';
import 'package:flutter_application_1/core/photo_picker.dart';
import 'package:flutter_application_1/features/auth/session_controller.dart';
import 'package:flutter_application_1/features/buyer/edit_profile.dart';
import 'package:flutter_application_1/features/buyer/liquidations.dart';
import 'package:flutter_application_1/features/buyer/supply_requests.dart';
import 'package:flutter_application_1/ui/app_tokens.dart';

const Color _sectionAccent = Color(0xff2563eb);

const Color _editProfileButton = Color(0xff064407);

class BuyerProfile extends StatefulWidget {
  const BuyerProfile({
    super.key,
    this.photoPicker = const DevicePhotoPicker(),
  });

  final PhotoPicker photoPicker;

  @override
  State<BuyerProfile> createState() => _BuyerProfileState();
}

class _BuyerProfileState extends State<BuyerProfile> {
  bool _requestedLoad = false;
  bool _uploadingPhoto = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_requestedLoad) {
      _requestedLoad = true;
      SessionScope.of(context).loadUser();
    }
  }

  Future<void> _changePhoto() async {
    if (_uploadingPhoto) return;

    final PickedPhoto? photo = await widget.photoPicker.pick();
    if (photo == null || !mounted) return;

    setState(() => _uploadingPhoto = true);
    try {
      await SessionScope.of(
        context,
      ).updatePhoto(filePath: photo.path, filename: photo.filename);
      if (!mounted) return;
      _showMessage('Foto actualizada');
    } catch (_) {
      if (!mounted) return;
      _showMessage('No pudimos actualizar tu foto');
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  String _fullName(User? user) {
    if (user == null) return '—';
    final String name = '${user.firstName} ${user.lastName}'.trim();
    return name.isEmpty ? '—' : name;
  }

  String _location(User user) {
    final String joined = <String>[
      user.municipality,
      user.department,
    ].where((String value) => value.isNotEmpty).join(', ');
    if (joined.isNotEmpty) return joined;
    return user.addressLine.isEmpty ? '—' : user.addressLine;
  }

  Widget _content(SessionController session, User? user) {
    if (user == null) {
      if (session.loadingUser) {
        return const Center(child: CircularProgressIndicator());
      }
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No se pudo cargar el perfil'),
            TextButton(
              onPressed: () => session.loadUser(force: true),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        top: AppSpacing.lg,
        bottom: AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader(icon: Icons.person, label: 'DATOS PERSONALES'),
          const SizedBox(height: AppSpacing.md),
          _InfoCard(
            rows: [
              _ProfileRowData(title: 'Nombre completo', value: _fullName(user)),
              _ProfileRowData(title: 'Correo', value: user.email),
              _ProfileRowData(
                title: 'Teléfono',
                value: user.phoneNumber.isEmpty ? '—' : user.phoneNumber,
              ),
              _ProfileRowData(title: 'Ubicación', value: _location(user)),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const _SectionHeader(icon: Icons.settings, label: 'CONFIGURACIÓN'),
          const SizedBox(height: AppSpacing.md),
          const _InfoCard(
            rows: [
              _ProfileRowData(title: 'Notificaciones', value: 'Activadas'),
              _ProfileRowData(title: 'Idioma', value: 'Español'),
            ],
          ),
          if (canPublishSupplyRequests(user.role)) ...[
            const SizedBox(height: AppSpacing.xl),
            const _SectionHeader(
              icon: Icons.receipt_long,
              label: 'COMPRAS MAYORISTAS',
            ),
            const SizedBox(height: AppSpacing.md),
            _InfoCard(
              rows: [
                _ProfileRowData(
                  title: 'Mis solicitudes',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SupplyRequestsPage(),
                    ),
                  ),
                ),
                _ProfileRowData(
                  title: 'Lotes disponibles',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const LiquidationsPage(),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          const _SectionHeader(icon: Icons.lock_outline, label: 'SEGURIDAD'),
          const SizedBox(height: AppSpacing.md),
          _InfoCard(
            rows: [
              const _ProfileRowData(title: 'Cambiar contraseña'),
              _ProfileRowData(
                title: 'Cerrar sesión',
                onTap: () => SessionScope.of(context).signOut(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final User? user = session.user;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.whitemodeBackgrund,
        body: Column(
          children: [
            _ProfileHeader(
              name: _fullName(user),
              email: user?.email ?? '—',
              photoSrc: user?.photoSrc,
              uploadingPhoto: _uploadingPhoto,
              onChangePhoto: _changePhoto,
              onEdit: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const EditProfilePage(),
                ),
              ),
            ),
            Expanded(child: _content(session, user)),
          ],
        ),
      ),
    );
  }
}

/// Cabecera verde con avatar, identidad del comprador y acción de edición.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.onEdit,
    this.photoSrc,
    this.uploadingPhoto = false,
    this.onChangePhoto,
  });

  final String name;
  final String email;
  final VoidCallback onEdit;
  final String? photoSrc;
  final bool uploadingPhoto;
  final VoidCallback? onChangePhoto;

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
              _ProfileAvatar(
                photoSrc: photoSrc,
                uploading: uploadingPhoto,
                onTap: onChangePhoto,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                email,
                style: const TextStyle(fontSize: 13, color: AppColors.yelow),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: onEdit,
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
  const _ProfileAvatar({this.photoSrc, this.uploading = false, this.onTap});

  final String? photoSrc;
  final bool uploading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              width: 88,
              height: 88,
              child: uploading
                  ? const ColoredBox(
                      color: Colors.white24,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _AvatarImage(photoSrc: photoSrc),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: AppColors.yelow,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.photo_camera,
                size: 17,
                color: AppColors.blackGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarImage extends StatelessWidget {
  const _AvatarImage({this.photoSrc});

  final String? photoSrc;

  @override
  Widget build(BuildContext context) {
    final String? src = photoSrc;
    if (src == null || src.isEmpty) return const _AvatarFallback();
    return Image.network(
      src,
      width: 88,
      height: 88,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : const _AvatarFallback(),
      errorBuilder: (context, error, stackTrace) => const _AvatarFallback(),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      color: Colors.white.withValues(alpha: 0.15),
      child: const Center(
        child: Icon(
          Icons.person,
          key: ValueKey<String>('avatarFallback'),
          size: 46,
          color: Colors.white,
        ),
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
      onTap: data.onTap,
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
  const _ProfileRowData({required this.title, this.value, this.onTap});

  final String title;
  final String? value;
  final VoidCallback? onTap;
}

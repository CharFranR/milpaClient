import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/models/auth_models.dart';
import 'package:flutter_application_1/features/auth/session_controller.dart';
import 'package:flutter_application_1/ui/app_tokens.dart';

class FarmerAccountPage extends StatelessWidget {
  const FarmerAccountPage({super.key});

  Future<void> _signOut(BuildContext context) async {
    final NavigatorState navigator = Navigator.of(context);
    await SessionScope.of(context).signOut();
    if (!context.mounted) return;
    navigator.popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final User? user = SessionScope.of(context).user;
    return Scaffold(
      backgroundColor: AppColors.whitemodeBackgrund,
      appBar: AppBar(
        backgroundColor: AppColors.blackGreen,
        foregroundColor: Colors.white,
        title: const Text(
          'Mi cuenta',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: _AccountAvatar(photoSrc: user?.photoSrc)),
            const SizedBox(height: AppSpacing.lg),
            Text(
              _fullName(user),
              textAlign: TextAlign.center,
              style: AppText.headline,
            ),
            const SizedBox(height: AppSpacing.xl),
            _InfoCard(
              rows: [
                _RowData(title: 'Nombre completo', value: _fullName(user)),
                _RowData(
                  title: 'Teléfono',
                  value: _valueOrDash(user?.phoneNumber),
                ),
                _RowData(title: 'Dirección', value: _address(user)),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            SizedBox(
              height: 58,
              child: FilledButton.icon(
                onPressed: () => _signOut(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.blackGreen,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                icon: const Icon(Icons.logout, size: 26),
                label: const Text('Cerrar sesión'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fullName(User? user) {
    if (user == null) return '—';
    final String name = '${user.firstName} ${user.lastName}'.trim();
    return name.isEmpty ? '—' : name;
  }

  String _valueOrDash(String? value) {
    if (value == null || value.isEmpty) return '—';
    return value;
  }

  String _address(User? user) {
    if (user == null) return '—';
    final String location = <String>[
      user.municipality,
      user.department,
    ].where((String value) => value.isNotEmpty).join(', ');
    if (user.addressLine.isNotEmpty && location.isNotEmpty) {
      return '${user.addressLine}, $location';
    }
    if (user.addressLine.isNotEmpty) return user.addressLine;
    if (location.isNotEmpty) return location;
    return '—';
  }
}

class _AccountAvatar extends StatelessWidget {
  const _AccountAvatar({this.photoSrc});

  final String? photoSrc;

  @override
  Widget build(BuildContext context) {
    final String? src = photoSrc;
    return ClipOval(
      child: SizedBox(
        width: 96,
        height: 96,
        child: src == null || src.isEmpty
            ? const _AvatarFallback()
            : Image.network(
                src,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : const _AvatarFallback(),
                errorBuilder: (context, error, stackTrace) =>
                    const _AvatarFallback(),
              ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.blackGreen.withValues(alpha: 0.12),
      child: const Center(
        child: Icon(Icons.person, size: 52, color: AppColors.blackGreen),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});

  final List<_RowData> rows;

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
      children.add(_Row(data: rows[i]));
    }
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppTints.border),
      ),
      child: Column(children: children),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.data});

  final _RowData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data.title, style: AppText.label),
          const SizedBox(height: AppSpacing.xs),
          Text(
            data.value,
            style: const TextStyle(fontSize: 17, color: AppColors.dark),
          ),
        ],
      ),
    );
  }
}

class _RowData {
  const _RowData({required this.title, required this.value});

  final String title;
  final String value;
}

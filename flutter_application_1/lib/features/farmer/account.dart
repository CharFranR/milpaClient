import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/models/auth_models.dart';
import 'package:flutter_application_1/features/auth/session_controller.dart';
import 'package:flutter_application_1/features/buyer/offering_models.dart';
import 'package:flutter_application_1/features/buyer/offering_repository.dart';
import 'package:flutter_application_1/features/company/company_repository.dart';
import 'package:flutter_application_1/features/farmer/business.dart';
import 'package:flutter_application_1/ui/app_tokens.dart';

class FarmerAccountPage extends StatefulWidget {
  const FarmerAccountPage({
    super.key,
    this.offeringRepository,
    this.companyRepository,
  });

  final OfferingRepository? offeringRepository;
  final CompanyRepository? companyRepository;

  @override
  State<FarmerAccountPage> createState() => _FarmerAccountPageState();
}

class _FarmerAccountPageState extends State<FarmerAccountPage> {
  late final OfferingRepository _repository =
      widget.offeringRepository ?? OfferingRepository(apiClient: ApiClient());

  String _userId = '';
  RatingSummary? _rating;
  bool _loadingRating = true;
  bool _ratingFailed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final String userId = SessionScope.of(context).user?.id ?? '';
    if (userId.isNotEmpty && userId != _userId) {
      _userId = userId;
      _loadRating();
    }
  }

  Future<void> _loadRating() async {
    setState(() {
      _loadingRating = true;
      _ratingFailed = false;
    });
    try {
      final RatingSummary rating = await _repository.fetchRating(_userId);
      if (!mounted) return;
      setState(() {
        _rating = rating;
        _loadingRating = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _ratingFailed = true;
        _loadingRating = false;
      });
    }
  }

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
            const SizedBox(height: AppSpacing.lg),
            _ReputationCard(
              summary: _rating,
              loading: _loadingRating,
              failed: _ratingFailed,
            ),
            const SizedBox(height: AppSpacing.lg),
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
            const SizedBox(height: AppSpacing.lg),
            _BusinessCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => FarmerBusinessPage(
                    companyRepository: widget.companyRepository,
                  ),
                ),
              ),
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

class _ReputationCard extends StatelessWidget {
  const _ReputationCard({
    required this.summary,
    required this.loading,
    required this.failed,
  });

  final RatingSummary? summary;
  final bool loading;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppTints.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lo que dicen los compradores', style: AppText.sectionTitle),
          const SizedBox(height: AppSpacing.md),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (loading) {
      return const Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              'Estamos buscando tus calificaciones...',
              style: TextStyle(fontSize: 17, color: AppColors.dark),
            ),
          ),
        ],
      );
    }
    if (failed) {
      return const Text(
        'No pudimos cargar tu calificación. Probá más tarde.',
        style: TextStyle(fontSize: 17, color: AppColors.dark),
      );
    }
    final RatingSummary? rating = summary;
    if (rating == null || !rating.hasReviews) {
      return const Text(
        'Todavía no tenés calificaciones. Cuando cierres tus primeros '
        'tratos, acá vas a ver lo que dicen los compradores.',
        style: TextStyle(fontSize: 17, color: AppColors.dark),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tu calificación: ${rating.average.toStringAsFixed(1)} '
          '(${rating.count})',
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: List<Widget>.generate(
            5,
            (int index) => Icon(
              _starIcon(rating.average, index),
              size: 34,
              color: AppColors.yelow,
            ),
          ),
        ),
      ],
    );
  }

  IconData _starIcon(double average, int index) {
    if (average >= index + 1) return Icons.star;
    if (average >= index + 0.5) return Icons.star_half;
    return Icons.star_border;
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

class _BusinessCard extends StatelessWidget {
  const _BusinessCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
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
              const Icon(
                Icons.storefront_outlined,
                size: 30,
                color: AppColors.blackGreen,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mi negocio', style: AppText.headline),
                    const SizedBox(height: AppSpacing.xs),
                    Text('Tu perfil de empresa', style: AppText.bodySecondary),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 26, color: AppTints.hint),
            ],
          ),
        ),
      ),
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

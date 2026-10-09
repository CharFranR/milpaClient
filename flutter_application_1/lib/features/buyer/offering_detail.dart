import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/token_store.dart';
import 'package:flutter_application_1/features/buyer/catalog_models.dart';
import 'package:flutter_application_1/features/buyer/chat.dart';
import 'package:flutter_application_1/features/buyer/conversation_models.dart';
import 'package:flutter_application_1/features/buyer/conversation_repository.dart';
import 'package:flutter_application_1/features/buyer/farmer_map.dart';
import 'package:flutter_application_1/features/buyer/offering_models.dart';
import 'package:flutter_application_1/features/buyer/offering_repository.dart';
import 'package:flutter_application_1/features/buyer/report_dialog.dart';
import 'package:flutter_application_1/features/buyer/report_repository.dart';
import 'package:flutter_application_1/features/buyer/widgets/product_image.dart';
import 'package:flutter_application_1/features/company/company_models.dart';
import 'package:flutter_application_1/features/company/company_repository.dart';
import 'package:flutter_application_1/ui/app_tokens.dart';

class OfferingDetailPage extends StatefulWidget {
  const OfferingDetailPage({
    super.key,
    required this.offeringId,
    this.offeringRepository,
    this.conversationRepository,
    this.reportRepository,
    this.companyRepository,
  });

  final String offeringId;
  final OfferingRepository? offeringRepository;
  final ConversationRepository? conversationRepository;
  final ReportRepository? reportRepository;
  final CompanyRepository? companyRepository;

  @override
  State<OfferingDetailPage> createState() => _OfferingDetailPageState();
}

class _OfferingDetailPageState extends State<OfferingDetailPage> {
  late final OfferingRepository _offeringRepository =
      widget.offeringRepository ?? OfferingRepository(apiClient: ApiClient());
  late final ConversationRepository _conversationRepository =
      widget.conversationRepository ??
      ConversationRepository(apiClient: ApiClient(), tokenStore: TokenStore());
  late final CompanyRepository _companyRepository =
      widget.companyRepository ??
      CompanyRepository(apiClient: ApiClient(), tokenStore: TokenStore());

  OfferingDetail? _detail;
  SellerProfile? _seller;
  RatingSummary? _rating;
  Company? _company;
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final OfferingDetail detail = await _offeringRepository.fetchDetail(
        widget.offeringId,
      );
      final (SellerProfile seller, RatingSummary rating) = await (
        _offeringRepository.fetchSeller(detail.userId),
        _offeringRepository.fetchRating(detail.userId),
      ).wait;
      final Company? company = await _fetchCompany(detail.companyId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _seller = seller;
        _rating = rating;
        _company = company;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudo cargar la oferta';
      });
    }
  }

  Future<Company?> _fetchCompany(String? companyId) async {
    if (companyId == null) return null;
    try {
      return await _companyRepository.fetchById(companyId);
    } catch (_) {
      return null;
    }
  }

  void _retry() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _load();
  }

  Future<void> _openConversation() async {
    final SellerProfile? seller = _seller;
    if (_sending || _detail == null || seller == null) return;
    setState(() => _sending = true);
    try {
      final List<Conversation> conversations = await _conversationRepository
          .fetchAll();
      Conversation? existing;
      for (final Conversation conversation in conversations) {
        if (conversation.offeringId == widget.offeringId &&
            conversation.farmerId == seller.id) {
          existing = conversation;
          break;
        }
      }
      final Conversation conversation =
          existing ??
          await _conversationRepository.start(
            farmerId: seller.id,
            offeringId: widget.offeringId,
          );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BuyerChat(
            conversationId: conversation.id,
            counterpartName: seller.fullName,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage('No se pudo iniciar la conversación');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _openReport() async {
    final ({String targetType, String targetId})? target =
        await showModalBottomSheet<({String targetType, String targetId})>(
          context: context,
          builder: (_) => _ReportOptionsSheet(
            offeringId: widget.offeringId,
            sellerId: _seller?.id,
            offeringRepository: _offeringRepository,
          ),
        );
    if (target == null || !mounted) return;
    await showReportDialog(
      context: context,
      targetType: target.targetType,
      targetId: target.targetId,
      repository: widget.reportRepository,
    );
  }

  bool get _canChat =>
      !_sending && _detail != null && _seller != null && _rating != null;

  String _initial(String fullName) =>
      fullName.isEmpty ? '?' : fullName[0].toUpperCase();

  String _location(SellerProfile seller) => <String>[
    seller.municipality,
    seller.department,
  ].where((String value) => value.isNotEmpty).join(', ');

  Widget _sellerCard(SellerProfile seller) {
    final String location = _location(seller);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dark.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF3E6),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _initial(seller.fullName),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blackGreen,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(seller.fullName, style: AppText.label),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(location, style: AppText.caption),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _companyCard(Company company) {
    final String location = <String>[
      company.municipality,
      company.department,
    ].where((String value) => value.isNotEmpty).join(', ');
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dark.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF3E6),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _initial(company.name),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blackGreen,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(company.name, style: AppText.label),
                if (company.verified) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.yelow,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: const Text(
                      'Proveedor Verificado',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                  ),
                ],
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(location, style: AppText.caption),
                ],
                if (company.description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(company.description, style: AppText.caption),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool get _hasCoordinates {
    final OfferingDetail? detail = _detail;
    if (detail == null) return false;
    final double? latitude = detail.latitude;
    final double? longitude = detail.longitude;
    if (latitude == null || longitude == null) return false;
    return latitude != 0 && longitude != 0;
  }

  IconData _starIcon(double average, int index) {
    if (average >= index + 1) return Icons.star;
    if (average >= index + 0.5) return Icons.star_half;
    return Icons.star_border;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whitemodeBackgrund,
      appBar: AppBar(
        backgroundColor: AppColors.blackGreen,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Reportar',
            icon: const Icon(Icons.flag_outlined, color: Colors.white),
            onPressed: _openReport,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: SizedBox(
            height: 52,
            child: TextButton(
              onPressed: _canChat ? _openConversation : null,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.blackGreen,
                disabledBackgroundColor: AppColors.dark.withValues(alpha: 0.12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: _sending
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Chatear', style: AppText.button),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final String? error = _error;
    if (error != null) {
      return _ErrorState(message: error, onRetry: _retry);
    }
    final OfferingDetail detail = _detail!;
    final SellerProfile seller = _seller!;
    final RatingSummary rating = _rating!;
    final Company? company = _company;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: SizedBox(
              height: 240,
              width: double.infinity,
              child: ColoredBox(
                color: const Color(0xFFEAF3E6),
                child: ProductImage(imageSrc: detail.imageSrc, emoji: '🌿'),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(detail.name, style: AppText.headline),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.yelow,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              detail.type == 1 ? 'Servicio' : 'Producto',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            formatPrice(detail.price),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.blackGreen,
            ),
          ),
          if (detail.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(detail.description, style: AppText.bodySecondary),
          ],
          const SizedBox(height: AppSpacing.xl),
          if (company == null)
            _sellerCard(seller)
          else
            _companyCard(company),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (int index = 0; index < 5; index++)
                Icon(
                  _starIcon(rating.average, index),
                  size: 18,
                  color: AppColors.yelow,
                ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                rating.hasReviews
                    ? '${rating.average.toStringAsFixed(1)} (${rating.count})'
                    : 'Sin reseñas',
                style: AppText.caption,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Ubicación del agricultor', style: AppText.sectionTitle),
          const SizedBox(height: AppSpacing.sm),
          if (_hasCoordinates) ...[
            FarmerMap(
              latitude: detail.latitude!,
              longitude: detail.longitude!,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Arrastrá el mapa y hacé zoom para ubicar la finca.',
              style: AppText.caption,
            ),
          ] else
            Text(
              'El agricultor no compartió su ubicación.',
              style: AppText.caption,
            ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off, size: 40, color: AppTints.muted),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: AppColors.blackGreen),
            child: const Text(
              'Reintentar',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportOptionsSheet extends StatefulWidget {
  const _ReportOptionsSheet({
    required this.offeringId,
    required this.sellerId,
    required this.offeringRepository,
  });

  final String offeringId;
  final String? sellerId;
  final OfferingRepository offeringRepository;

  @override
  State<_ReportOptionsSheet> createState() => _ReportOptionsSheetState();
}

class _ReportOptionsSheetState extends State<_ReportOptionsSheet> {
  String? _sellerId;
  bool _loadingSeller = false;
  bool _sellerFailed = false;

  @override
  void initState() {
    super.initState();
    _sellerId = widget.sellerId;
    if (_sellerId == null || _sellerId!.isEmpty) {
      _loadSeller();
    }
  }

  Future<void> _loadSeller() async {
    setState(() {
      _loadingSeller = true;
      _sellerFailed = false;
    });
    try {
      final OfferingDetail detail = await widget.offeringRepository.fetchDetail(
        widget.offeringId,
      );
      final SellerProfile seller = await widget.offeringRepository.fetchSeller(
        detail.userId,
      );
      if (!mounted) return;
      setState(() {
        _sellerId = seller.id;
        _loadingSeller = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingSeller = false;
        _sellerFailed = true;
      });
    }
  }

  void _report(String targetType, String targetId) {
    Navigator.of(context).pop((targetType: targetType, targetId: targetId));
  }

  @override
  Widget build(BuildContext context) {
    final String? sellerId = _sellerId;
    final bool canReportFarmer =
        !_loadingSeller &&
        !_sellerFailed &&
        sellerId != null &&
        sellerId.isNotEmpty;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text('Reportar', style: AppText.label),
          ),
          ListTile(
            leading: const Icon(
              Icons.flag_outlined,
              color: AppColors.blackGreen,
            ),
            title: const Text('Reportar publicación'),
            onTap: () => _report('offering', widget.offeringId),
          ),
          ListTile(
            leading: _loadingSeller
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.person_outline,
                    color: AppColors.blackGreen,
                  ),
            title: const Text('Reportar al agricultor'),
            subtitle: _loadingSeller
                ? const Text('Cargando agricultor…')
                : _sellerFailed
                ? const Text('No se pudo cargar el agricultor')
                : null,
            enabled: canReportFarmer,
            onTap: canReportFarmer ? () => _report('user', sellerId) : null,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

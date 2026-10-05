import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/models/auth_models.dart';
import 'package:flutter_application_1/features/auth/session_controller.dart';
import 'package:flutter_application_1/features/farmer/account.dart';
import 'package:flutter_application_1/features/farmer/home.dart';
import 'package:flutter_application_1/features/farmer/messages.dart';
import 'package:flutter_application_1/features/farmer/orders.dart';
import 'package:flutter_application_1/features/farmer/products.dart';
import 'package:flutter_application_1/ui/app_tokens.dart';

class FarmerLayout extends StatefulWidget {
  const FarmerLayout({super.key});

  @override
  State<FarmerLayout> createState() => _FarmerLayoutState();
}

class _FarmerLayoutState extends State<FarmerLayout> {
  int _currentIndex = 0;
  bool _requestedLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_requestedLoad) {
      _requestedLoad = true;
      SessionScope.of(context).loadUser();
    }
  }

  void _select(int index) => setState(() => _currentIndex = index);

  Future<void> _openAccount() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const FarmerAccountPage()));
  }

  Widget _page(int index) {
    return switch (index) {
      0 => FarmerHome(
        onProducts: () => _select(1),
        onOrders: () => _select(2),
        onMessages: () => _select(3),
        onAccount: _openAccount,
      ),
      1 => const FarmerProductsPage(),
      2 => const FarmerOrdersPage(),
      _ => const FarmerMessagesPage(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final User? user = SessionScope.of(context).user;
    final String name = _fullName(user);
    return Scaffold(
      backgroundColor: AppColors.whitemodeBackgrund,
      body: Column(
        children: [
          _FarmerHeader(
            name: name,
            photoSrc: user?.photoSrc,
            onTap: _openAccount,
          ),
          Expanded(child: _page(_currentIndex)),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        height: 84,
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              label: 'Inicio',
              index: 0,
              current: _currentIndex,
              onTap: _select,
            ),
            _NavItem(
              icon: Icons.inventory_2_outlined,
              label: 'Mis productos',
              index: 1,
              current: _currentIndex,
              onTap: _select,
            ),
            _NavItem(
              icon: Icons.receipt_long_outlined,
              label: 'Pedidos',
              index: 2,
              current: _currentIndex,
              onTap: _select,
            ),
            _NavItem(
              icon: Icons.chat_bubble_outline,
              label: 'Mensajes',
              index: 3,
              current: _currentIndex,
              onTap: _select,
            ),
          ],
        ),
      ),
    );
  }

  String _fullName(User? user) {
    if (user == null) return '';
    return '${user.firstName} ${user.lastName}'.trim();
  }
}

class _FarmerHeader extends StatelessWidget {
  const _FarmerHeader({required this.name, required this.onTap, this.photoSrc});

  final String name;
  final String? photoSrc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.blackGreen,
      child: SafeArea(
        bottom: false,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                _FarmerAvatar(photoSrc: photoSrc),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? 'Agricultor' : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const Row(
                        children: [
                          Icon(
                            Icons.account_circle_outlined,
                            size: 18,
                            color: AppColors.yelow,
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Text(
                            'Mi cuenta',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.yelow,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white70),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FarmerAvatar extends StatelessWidget {
  const _FarmerAvatar({this.photoSrc});

  final String? photoSrc;

  @override
  Widget build(BuildContext context) {
    final String? src = photoSrc;
    return ClipOval(
      child: SizedBox(
        width: 52,
        height: 52,
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
      color: Colors.white.withValues(alpha: 0.15),
      child: const Center(
        child: Icon(Icons.person, size: 30, color: Colors.white),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final active = current == index;
    final Color color = active ? AppColors.blackGreen : AppTints.muted;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 26, color: color),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

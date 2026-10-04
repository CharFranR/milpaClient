import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/buyer/explore.dart';
import 'package:flutter_application_1/features/buyer/home.dart';
import 'package:flutter_application_1/features/buyer/messages.dart';
import 'package:flutter_application_1/features/buyer/profile.dart';
import 'package:flutter_application_1/features/buyer/supply_requests.dart';
import 'package:flutter_application_1/features/auth/session_controller.dart';
import 'package:flutter_application_1/ui/app_tokens.dart';

/// Contenedor del comprador: páginas con barra inferior y FAB central.
class BuyerLayout extends StatefulWidget {
  const BuyerLayout({super.key});

  @override
  State<BuyerLayout> createState() => _BuyerLayoutState();
}

class _BuyerLayoutState extends State<BuyerLayout> {
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

  Widget _page(int index) {
    return switch (index) {
      0 => BuyerHome(onExplore: () => _select(1)),
      1 => const BuyerExplore(),
      2 => const BuyerMessages(),
      _ => const BuyerProfile(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whitemodeBackgrund,
      body: _page(_currentIndex),
      floatingActionButton:
          canPublishSupplyRequests(SessionScope.of(context).user?.role)
          ? FloatingActionButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SupplyRequestsPage(),
                ),
              ),
              backgroundColor: AppColors.blackGreen,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              elevation: 2,
              child: const Icon(Icons.add, size: 28),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        height: 66,
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
              icon: Icons.grid_view,
              label: 'Explorar',
              index: 1,
              current: _currentIndex,
              onTap: _select,
            ),
            const SizedBox(width: 72),
            _NavItem(
              icon: Icons.mail_outline,
              label: 'Mensajes',
              index: 2,
              current: _currentIndex,
              onTap: _select,
            ),
            _NavItem(
              icon: Icons.account_circle_outlined,
              label: 'Perfil',
              index: 3,
              current: _currentIndex,
              onTap: _select,
            ),
          ],
        ),
      ),
    );
  }
}

/// Ítem de la barra inferior con estado activo resaltado.
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
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (active)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.whiteGreen.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 22, color: AppColors.blackGreen),
              )
            else
              Icon(icon, size: 22, color: AppTints.muted),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? AppColors.blackGreen : AppTints.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

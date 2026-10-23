import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';

/// Navigation inférieure de l'agent : accueil, missions, profil.
class AgentBottomNav extends StatelessWidget {
  final int currentIndex;

  const AgentBottomNav({super.key, required this.currentIndex});

  static const List<String> _routes = [
    '/agent/home',
    '/agent/missions',
    '/agent/profil',
  ];

  void _naviguer(BuildContext context, int index) {
    if (index == currentIndex) return;
    context.go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(64, 8, 64, 12),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF64748B), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavIcone(
                tooltip: 'Accueil',
                actif: currentIndex == 0,
                onTap: () => _naviguer(context, 0),
                child: Image.asset(
                  'assets/images/icons/home_icon.png',
                  width: 28,
                  height: 28,
                ),
              ),
              _NavIcone(
                tooltip: 'Mes missions',
                actif: currentIndex == 1,
                onTap: () => _naviguer(context, 1),
                child: const Icon(
                  Icons.location_on_outlined,
                  size: 32,
                  color: AppColors.darkBlue,
                ),
              ),
              _NavIcone(
                tooltip: 'Mon profil',
                actif: currentIndex == 2,
                onTap: () => _naviguer(context, 2),
                child: Image.asset(
                  'assets/images/icons/user_icon.png',
                  width: 28,
                  height: 28,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavIcone extends StatelessWidget {
  final String tooltip;
  final bool actif;
  final VoidCallback onTap;
  final Widget child;

  const _NavIcone({
    required this.tooltip,
    required this.actif,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: onTap,
          tooltip: tooltip,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 40),
          icon: child,
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: actif ? 16 : 0,
          height: 3,
          decoration: BoxDecoration(
            color: const Color(0xFFFF7A00),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

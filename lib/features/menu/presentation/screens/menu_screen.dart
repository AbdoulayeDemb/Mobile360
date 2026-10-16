import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';

class MenuScreen extends ConsumerWidget {
  final VoidCallback? onClose;
  final VoidCallback? onMonCompteTap;
  final VoidCallback? onMesSignalementsTap;
  final VoidCallback? onActualiteTap;
  final VoidCallback? onApprentissageTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onAProposTap;
  final VoidCallback? onContactTap;
  final VoidCallback? onModeEmploiTap;
  final VoidCallback? onDeconnexionTap;

  const MenuScreen({
    super.key,
    this.onClose,
    this.onMonCompteTap,
    this.onMesSignalementsTap,
    this.onActualiteTap,
    this.onApprentissageTap,
    this.onNotificationsTap,
    this.onAProposTap,
    this.onContactTap,
    this.onModeEmploiTap,
    this.onDeconnexionTap,
  });

  void _fermerMenu(BuildContext context) {
    if (onClose != null) {
      onClose!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // En-tête : logo et bouton de fermeture
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'assets/images/logo/logo_alert360.png',
                    height: 38,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) {
                      return const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shield_rounded,
                            color: Color(0xFF2563EB),
                            size: 28,
                          ),
                          SizedBox(width: 6),
                          Text(
                            "Alert'360",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkBlue,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  IconButton(
                    onPressed: () => _fermerMenu(context),
                    tooltip: 'Fermer le menu',
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      fixedSize: const Size(40, 40),
                    ),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.darkBlue,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),

            // Liste des options
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _MenuItem(
                        icon: Icons.person_rounded,
                        iconColor: const Color(0xFF072B61),
                        title: 'Mon compte',
                        onTap: onMonCompteTap,
                      ),
                      _MenuItem(
                        icon: Icons.list_alt_rounded,
                        iconColor: const Color(0xFF072B61),
                        title: 'Mes signalements',
                        onTap: onMesSignalementsTap,
                      ),
                      _MenuItem(
                        icon: Icons.campaign_rounded,
                        iconColor: const Color(0xFF072B61),
                        title: 'Mon fil d’actualité',
                        onTap: onActualiteTap,
                      ),
                      _MenuItem(
                        icon: Icons.menu_book_rounded,
                        iconColor: const Color(0xFF072B61),
                        title: 'Mon apprentissage',
                        onTap: onApprentissageTap,
                      ),
                      _MenuItem(
                        icon: Icons.notifications_rounded,
                        iconColor: const Color(0xFF072B61),
                        title: 'Mes notifications',
                        onTap: onNotificationsTap,
                      ),
                      _MenuItem(
                        icon: Icons.info_rounded,
                        iconColor: const Color(0xFF072B61),
                        title: 'À propos de nous',
                        onTap: onAProposTap,
                      ),
                      _MenuItem(
                        icon: Icons.phone_rounded,
                        iconColor: const Color(0xFF072B61),
                        title: 'Contactez-nous',
                        onTap: onContactTap,
                      ),
                      _MenuItem(
                        icon: Icons.play_circle_rounded,
                        iconColor: const Color(0xFF072B61),
                        title: 'Mode d’emploi',
                        onTap: onModeEmploiTap,
                      ),

                      // Déconnexion
                      _MenuItem(
                        icon: Icons.logout_rounded,
                        title: 'Déconnexion',
                        iconColor: const Color(0xFFDC2626),
                        iconBg: const Color(0xFFFEF2F2),
                        textColor: const Color(0xFFDC2626),
                        onTap: onDeconnexionTap,
                        showDivider: false,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color iconColor;
  final Color iconBg;
  final Color? textColor;
  final VoidCallback? onTap;
  final bool showDivider;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.iconColor = const Color(0xFF2563EB),
    this.iconBg = const Color(0xFFEFF6FF),
    this.textColor,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                children: [
                  // Icône dans un cercle coloré
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),

                  const SizedBox(width: 16),

                  // Libellé
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: textColor ?? AppColors.darkBlue,
                      ),
                    ),
                  ),

                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF94A3B8),
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),

        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFF1F5F9),
            indent: 18,
            endIndent: 18,
          ),
      ],
    );
  }
}

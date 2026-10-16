import 'dart:async';

import 'package:alert360_mobile/features/about/presentation/screens/about_screen.dart';
import 'package:alert360_mobile/features/auth/data/services/auth_service.dart';
import 'package:alert360_mobile/features/auth/data/services/utilisateur_service.dart';
import 'package:alert360_mobile/features/menu/presentation/screens/contact_screen.dart';
import 'package:alert360_mobile/features/menu/presentation/screens/user_guide_flow.dart';
import 'package:alert360_mobile/features/sos/presentation/screens/urgences_proximite_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:alert360_mobile/features/menu/presentation/screens/menu_screen.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSignalProblem;
  final VoidCallback? onAllCategories;
  final VoidCallback? onSosLongPress;
  final int currentNavIndex;
  final ValueChanged<int>? onNavTap;

  const HomeScreen({
    super.key,
    this.onSignalProblem,
    this.onAllCategories,
    this.onSosLongPress,
    this.currentNavIndex = 0,
    this.onNavTap,
  });
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const int _dureeSos = 3;

  Timer? _timerSos;
  int _secondesRestantes = _dureeSos;
  bool _maintienEnCours = false;
  bool _sosDeclenche = false;

  void _commencerMaintienSos() {
    if (_maintienEnCours || _sosDeclenche) return;

    setState(() {
      _maintienEnCours = true;
      _secondesRestantes = _dureeSos;
    });

    _timerSos = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (!_maintienEnCours) {
        timer.cancel();
        return;
      }

      if (_secondesRestantes <= 1) {
        timer.cancel();

        setState(() {
          _secondesRestantes = 0;
          _maintienEnCours = false;
          _sosDeclenche = true;
        });

        _ouvrirUrgencesProximite();
        return;
      }

      setState(() {
        _secondesRestantes--;
      });
    });
  }

  void _annulerMaintienSos() {
    if (!_maintienEnCours || _sosDeclenche) return;

    _timerSos?.cancel();

    setState(() {
      _maintienEnCours = false;
      _secondesRestantes = _dureeSos;
    });
  }

  void _ouvrirUrgencesProximite() {
    if (!mounted) return;

    final navigation = Navigator.of(context);

    navigation
        .push(
          MaterialPageRoute<void>(
            builder: (_) => const UrgencesProximiteScreen(),
          ),
        )
        .then((_) {
          if (!mounted) return;

          setState(() {
            _sosDeclenche = false;
            _maintienEnCours = false;
            _secondesRestantes = _dureeSos;
          });
        });
  }

  @override
  void dispose() {
    _timerSos?.cancel();
    super.dispose();
  }

  void _ouvrirMenu(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          onClose: () => Navigator.of(context).pop(),

          onMonCompteTap: () {
            Navigator.of(context).pop();
            context.push('/profil');
          },

          onMesSignalementsTap: () {
            Navigator.of(context).pop();
            context.push('/mes-signalements');
          },

          onActualiteTap: () {
            Navigator.of(context).pop();
            // TODO : ouvrir le fil d'actualité
          },

          onApprentissageTap: () {
            Navigator.of(context).pop();
            // TODO : ouvrir l'écran d'apprentissage
          },

          onNotificationsTap: () {
            Navigator.of(context).pop();
            // TODO : ouvrir les notifications
          },

          onAProposTap: () {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const AboutScreen()));
          },

          onContactTap: () {
            Navigator.of(context).pop();

            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ContactScreen(
                  chargerEmail: () async {
                    final authService = AuthService();
                    final utilisateurService = UtilisateurService();

                    final idUtilisateur = await authService.getCurrentUserId();

                    if (idUtilisateur == null) {
                      return null;
                    }

                    final profil = await utilisateurService.getUtilisateurById(
                      idUtilisateur,
                    );

                    final email = profil['email'];

                    if (email == null || email.toString().trim().isEmpty) {
                      return null;
                    }

                    return email.toString().trim();
                  },
                ),
              ),
            );
          },

          onModeEmploiTap: () {
            Navigator.of(context).pop();

            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const UserGuideFlow()));
          },
          onDeconnexionTap: () {
            Navigator.of(context).pop();
            // TODO : déconnecter l'utilisateur
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final utilisateur = authState.asData?.value;

    final prenom = utilisateur?.prenom?.trim() ?? '';
    final nomAffiche = prenom.isNotEmpty ? prenom : 'citoyen';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 1. En-tête fixé en haut (Logo + Menu burger)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              color: AppColors.background,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'assets/images/logo/logo_alert360.png',
                    height: 45,
                    fit: BoxFit.contain,
                  ),
                  IconButton(
                    onPressed: () => _ouvrirMenu(context),
                    tooltip: 'Ouvrir le menu',
                    icon: const Icon(
                      Icons.menu_rounded,
                      color: AppColors.darkBlue,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),

            // 2. Reste du contenu défilable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Localisation et météo
                    Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_pin,
                            color: AppColors.primaryBlue,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Bamako, Mali',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkBlue,
                              ),
                            ),
                          ),
                          Container(
                            height: 24,
                            width: 1,
                            color: const Color(0xFFCBD5E1),
                          ),
                          const SizedBox(width: 16),
                          const Text('☀️', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 6),
                          const Text(
                            '32 °C',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkBlue,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Bannière
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        height: 150,
                        width: double.infinity,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              'assets/images/home_banner.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFFCBD5E1),
                                child: const Icon(
                                  Icons.image,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.8),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                                child: const Text(
                                  'Eaux usées, accident, incendies, vols...\n'
                                  'signalez ce que vous observez',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Carte de signalement
                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                      child: InkWell(
                        onTap: widget.onSignalProblem,
                        borderRadius: BorderRadius.circular(24),
                        child: Ink(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00A8B5),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    height: 90,
                                    width: 90,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1,
                                      ),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.camera_alt_rounded,
                                        color: Colors.white,
                                        size: 52,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Signaler un problème',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Voiries, Salubrité, Panne d’eau/électricité...',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 11,
                                            color: Colors.white70,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF00838F),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Text(
                                            'Inclut : Santé, Incendie, Sécurité & Police',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFFFFD54F),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Bouton "Toutes les catégories" identique à la maquette
                              InkWell(
                                onTap: widget.onAllCategories,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: double.infinity,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Text(
                                        'Toutes les catégories',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF00A8B5),
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 18,
                                        color: Color(0xFF00A8B5),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // SOS

                    // SOS URGENCE DIRECT
                    Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: (_) => _commencerMaintienSos(),
                      onPointerUp: (_) => _annulerMaintienSos(),
                      onPointerCancel: (_) => _annulerMaintienSos(),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _maintienEnCours
                              ? const Color(0xFFFF0000)
                              : const Color(0xFFFF7A00),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF7A00)
                                  .withValues(alpha: 0.18),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: 48,
                              width: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.notifications_active_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'SOS URGENCE DIRECT',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _maintienEnCours
                                        ? 'Maintenez encore $_secondesRestantes seconde(s)...'
                                        : 'Maintenez 3 secondes pour trouver les secours',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              height: 50,
                              width: 58,
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      value: _maintienEnCours
                                          ? (_dureeSos - _secondesRestantes) /
                                                _dureeSos
                                          : 0,
                                      backgroundColor: Colors.white30,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _maintienEnCours
                                        ? '${_secondesRestantes}s'
                                        : '3 sec',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 9,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Section "Mes récompenses"
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mes récompenses',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkBlue,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Découvrez vos points civiques et badges',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFFF1F5F9),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Image.asset(
                                        'assets/images/icons/star_icon.png',
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                              Icons.star_rounded,
                                              color: Color(0xFFEAB308),
                                              size: 32,
                                            ),
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: const [
                                          Text(
                                            '450',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.darkBlue,
                                            ),
                                          ),
                                          Text(
                                            'Points civiques',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFFF1F5F9),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Image.asset(
                                        'assets/images/icons/badget_icon.png',
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                              Icons.workspace_premium_rounded,
                                              color: Color(0xFFD97706),
                                              size: 32,
                                            ),
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: const [
                                          Text(
                                            '100',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.darkBlue,
                                            ),
                                          ),
                                          Text(
                                            'Badges obtenus',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        color: Colors.transparent,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavButton(
                assetPath: 'assets/images/icons/home_icon.png',
                index: 0,
                currentIndex: widget.currentNavIndex,
                onTap: widget.onNavTap,
              ),
              _NavButton(
                assetPath: 'assets/images/icons/list_icon.png',
                index: 1,
                currentIndex: widget.currentNavIndex,
                onTap: (index) {
                  if (index == 1) {
                    context.push('/mes-signalements');
                  } else {
                    widget.onNavTap?.call(index);
                  }
                },
              ),

              _NavButton(
                assetPath: 'assets/images/icons/user_icon.png',
                index: 2,
                currentIndex: widget.currentNavIndex,
                onTap: (index) {
                  if (index == 2) {
                    context.push('/profil');
                  } else {
                    widget.onNavTap?.call(index);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final String assetPath;
  final int index;
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const _NavButton({
    required this.assetPath,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => onTap?.call(index),
      icon: Image.asset(assetPath, width: 26, height: 26, fit: BoxFit.contain),
    );
  }
}

import 'dart:async';

import 'package:alert360_mobile/core/config/api_config.dart';
import 'package:alert360_mobile/core/providers/weather_provider.dart';
import 'package:alert360_mobile/core/theme/app_colors.dart';
import 'package:alert360_mobile/features/about/presentation/screens/about_screen.dart';
import 'package:alert360_mobile/features/auth/data/services/auth_service.dart';
import 'package:alert360_mobile/features/auth/data/services/utilisateur_service.dart';
import 'package:alert360_mobile/features/menu/presentation/screens/contact_screen.dart';
import 'package:alert360_mobile/features/menu/presentation/screens/menu_screen.dart';
import 'package:alert360_mobile/features/menu/presentation/screens/user_guide_flow.dart';
import 'package:alert360_mobile/features/signalements/data/models/signalement.dart';
import 'package:alert360_mobile/features/signalements/presentation/providers/signalement_provider.dart';
import 'package:alert360_mobile/features/sos/presentation/screens/urgences_proximite_screen.dart';
import 'package:alert360_mobile/features/auth/presentation/providers/auth_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  // Carousel de la bannière
  final PageController _bannerPageController = PageController();
  Timer? _bannerTimer;
  int _currentBannerIndex = 0;

  final List<Map<String, String>> _banners = [
    {
      'image': 'assets/images/home_banner4.jpg',
      'text':
          'Eaux usées, accident, incendies, vols...\n'
          'signalez ce que vous observez.',
    },
    {
      'image': 'assets/images/home_banner5.jpg',
      'text':
          'Un signalement sur Alert’360, une prise\n'
          'en charge rapide par la bonne structure.',
    },
    {
      'image': 'assets/images/home_banner6.jpg',
      'text':
          'Signalez sur Alert’360, la bonne structure\n'
          'intervient et votre problème est résolu.',
    },
  ];

  // SOS
  Timer? _timerSos;
  int _secondesRestantes = _dureeSos;
  bool _maintienEnCours = false;
  bool _sosDeclenche = false;

  @override
  void initState() {
    super.initState();
    _demarrerCarousel();
  }

  void _demarrerCarousel() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_bannerPageController.hasClients) return;

      final nextPage = (_currentBannerIndex + 1) % _banners.length;

      _bannerPageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  Widget _buildBanner({required String image, required String text}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          image,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          isAntiAlias: true,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFFCBD5E1),
            child: const Icon(Icons.image, size: 40, color: Colors.white),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            child: Text(
              text,
              style: const TextStyle(
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
    );
  }

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

    Navigator.of(context)
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
    _bannerTimer?.cancel();
    _bannerPageController.dispose();
    super.dispose();
  }

  void _ouvrirMenu(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
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
            context.push('/actualites');
          },
          onApprentissageTap: () {
            Navigator.of(context).pop();
            context.push('/contenus-educatifs');
          },
          onNotificationsTap: () {
            Navigator.of(context).pop();

            context.push('/notifications');
          },
          onAProposTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AboutScreen()),
            );
          },
          onContactTap: () {
            Navigator.of(context).pop();

            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ContactScreen(
                  chargerEmail: () async {
                    final authService = AuthService();
                    final utilisateurService = UtilisateurService();

                    final idUtilisateur = await authService.getCurrentUserId();

                    if (idUtilisateur == null) return null;

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
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const UserGuideFlow()),
            );
          },
          onDeconnexionTap: () async {
            Navigator.of(context).pop();
            await ref.read(authControllerProvider.notifier).logout();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final utilisateur = authState.asData?.value;

    final weatherAsync = ref.watch(weatherProvider);
    final citoyenIdAsync = ref.watch(currentCitoyenIdProvider);

    // Actualiser les signalements après une nouvelle création.
    ref.listen<AsyncValue<Signalement?>>(creationSignalementProvider, (
      previous,
      next,
    ) {
      final nouveauSignalement = next.asData?.value;
      if (nouveauSignalement == null) return;

      final ancienSignalement = previous?.asData?.value;

      if (ancienSignalement?.idSignalement ==
          nouveauSignalement.idSignalement) {
        return;
      }

      final idCitoyen = citoyenIdAsync.asData?.value;

      if (idCitoyen != null) {
        ref.invalidate(signalementsByCitoyenProvider(idCitoyen));
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // En-tête : logo et menu.
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

            // Contenu défilable.
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Localisation et météo dynamique.
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
                          const SizedBox(width: 12),
                          weatherAsync.when(
                            loading: () => const SizedBox(
                              width: 64,
                              height: 24,
                              child: Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                              ),
                            ),
                            error: (error, stackTrace) => IconButton(
                              tooltip: 'Réessayer de charger la météo',
                              onPressed: () {
                                ref.invalidate(weatherProvider);
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              icon: const Icon(
                                Icons.refresh_rounded,
                                color: AppColors.primaryBlue,
                                size: 22,
                              ),
                            ),
                            data: (weather) => Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  weather.icon,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${weather.temperature.round()} °C',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Bannière d'accueil : carousel automatique.
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        height: 150,
                        width: double.infinity,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            PageView.builder(
                              controller: _bannerPageController,
                              itemCount: _banners.length,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentBannerIndex = index;
                                });
                              },
                              itemBuilder: (context, index) {
                                return _buildBanner(
                                  image: _banners[index]['image']!,
                                  text: _banners[index]['text']!,
                                );
                              },
                            ),

                            // Indicateurs de position.
                            Positioned(
                              bottom: 8,
                              right: 14,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(_banners.length, (
                                  index,
                                ) {
                                  final isActive = _currentBannerIndex == index;

                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.only(left: 5),
                                    width: isActive ? 18 : 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? Colors.white
                                          : Colors.white.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Carte de signalement.
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
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
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

                    // SOS URGENCE DIRECT.
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

                    const SizedBox(height: 22),

                    // Mes signalements récents.
                    _buildMesSignalementsSection(citoyenIdAsync),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Navigation inférieure.
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

  Widget _buildMesSignalementsSection(AsyncValue<int?> citoyenIdAsync) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F7FA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: Color(0xFF0097A7),
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mes signalements',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkBlue,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Suivez vos 3 dernières déclarations récentes',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => context.push('/mes-signalements'),
                child: const Text(
                  'Voir tout',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0097A7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          citoyenIdAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF0097A7)),
              ),
            ),
            error: (error, stackTrace) => _messageSignalements(
              icon: Icons.error_outline_rounded,
              message: 'Impossible de charger votre compte.',
              actionLabel: 'Réessayer',
              onAction: () => ref.invalidate(currentCitoyenIdProvider),
            ),
            data: (idCitoyen) {
              if (idCitoyen == null) {
                return _messageSignalements(
                  icon: Icons.person_outline_rounded,
                  message: 'Connectez-vous pour consulter vos signalements.',
                );
              }

              final signalementsAsync = ref.watch(
                signalementsByCitoyenProvider(idCitoyen),
              );

              return signalementsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF0097A7)),
                  ),
                ),
                error: (error, stackTrace) => _messageSignalements(
                  icon: Icons.cloud_off_rounded,
                  message: 'Impossible de charger vos signalements.',
                  actionLabel: 'Réessayer',
                  onAction: () {
                    ref.invalidate(signalementsByCitoyenProvider(idCitoyen));
                  },
                ),
                data: (signalements) {
                  if (signalements.isEmpty) {
                    return _messageSignalements(
                      icon: Icons.assignment_outlined,
                      message: 'Vous n’avez pas encore créé de signalement.',
                      actionLabel: 'Signaler un problème',
                      onAction: widget.onSignalProblem,
                    );
                  }

                  final signalementsRecents = [...signalements]
                    ..sort((a, b) {
                      final dateA = a.dateHeureAlerte;
                      final dateB = b.dateHeureAlerte;

                      if (dateA == null && dateB == null) return 0;
                      if (dateA == null) return 1;
                      if (dateB == null) return -1;

                      return dateB.compareTo(dateA);
                    });

                  final troisDerniers = signalementsRecents.take(3).toList();

                  return Column(
                    children: [
                      for (int i = 0; i < troisDerniers.length; i++) ...[
                        _SignalementRecentCard(
                          signalement: troisDerniers[i],
                          onTap: () {
                            context.push('/mes-signalements');
                          },
                        ),
                        if (i < troisDerniers.length - 1)
                          const SizedBox(height: 10),
                      ],
                      if (signalements.length > 5) ...[
                        const SizedBox(height: 12),
                        Text(
                          '${signalements.length - 5} autre(s) signalement(s) disponible(s)',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _messageSignalements({
    required IconData icon,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 30, color: AppColors.textSecondary),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 10),
            TextButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ],
      ),
    );
  }
}

class _SignalementRecentCard extends StatelessWidget {
  final Signalement signalement;
  final VoidCallback onTap;

  const _SignalementRecentCard({
    required this.signalement,
    required this.onTap,
  });

  String get _statutNormalise {
    return signalement.statut
        .trim()
        .toUpperCase()
        .replaceAll('É', 'E')
        .replaceAll('È', 'E')
        .replaceAll(' ', '_');
  }

  Color get _couleurStatut {
    switch (_statutNormalise) {
      case 'RESOLU':
        return const Color(0xFF10B981);
      case 'EN_COURS':
        return const Color(0xFFF59E0B);
      case 'REJETE':
        return const Color(0xFFEF4444);
      case 'DECLARE':
      default:
        return const Color(0xFF3B82F6);
    }
  }

  String get _statutLisible {
    switch (_statutNormalise) {
      case 'DECLARE':
        return 'Déclaré';
      case 'EN_COURS':
        return 'En cours';
      case 'RESOLU':
        return 'Résolu';
      case 'REJETE':
        return 'Rejeté';
      default:
        return signalement.statut.replaceAll('_', ' ');
    }
  }

  String _formaterDate(DateTime? date) {
    if (date == null) return 'Date indisponible';

    final d = date.toLocal();
    final jour = d.day.toString().padLeft(2, '0');
    final mois = d.month.toString().padLeft(2, '0');

    return '$jour/$mois/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = ApiConfig.construireUrl(signalement.photoAvantUrl ?? '');

    debugPrint(
      '[PHOTO SIGNALEMENT ${signalement.idSignalement}] '
      'URL reçue : "$photoUrl"',
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                // Photo du signalement.
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 66,
                    height: 72,
                    child: photoUrl.isNotEmpty
                        ? Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('Erreur chargement photo : $photoUrl');
                              debugPrint('Détail erreur : $error');
                              debugPrintStack(stackTrace: stackTrace);

                              return _photoFallback();
                            },
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;

                              return Container(
                                color: const Color(0xFFF1F5F9),
                                alignment: Alignment.center,
                                child: const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF3B5998),
                                  ),
                                ),
                              );
                            },
                          )
                        : _photoFallback(),
                  ),
                ),

                const SizedBox(width: 12),

                // Informations du signalement.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        signalement.categorieNom?.trim().isNotEmpty == true
                            ? signalement.categorieNom!.trim()
                            : 'Signalement',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        signalement.codeTrackingUnique?.trim().isNotEmpty ==
                                true
                            ? signalement.codeTrackingUnique!.trim()
                            : '#${signalement.idSignalement}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              _formaterDate(signalement.dateHeureAlerte),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Badge de statut.
                Flexible(
                  flex: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _couleurStatut,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statutLisible,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      softWrap: false,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 2),

                const Icon(
                  Icons.chevron_right_rounded,
                  size: 21,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _photoFallback() {
    return Container(
      color: const Color(0xFFEAF0FF),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        size: 25,
        color: Color(0xFF3B5998),
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
      tooltip: index == 0
          ? 'Accueil'
          : index == 1
          ? 'Mes signalements'
          : 'Mon profil',
      icon: Image.asset(assetPath, width: 26, height: 26, fit: BoxFit.contain),
    );
  }
}

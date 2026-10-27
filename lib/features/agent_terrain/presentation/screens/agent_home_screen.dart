import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/weather_provider.dart';
import '../../../../core/services/weather_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../about/presentation/screens/about_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../menu/presentation/screens/contact_screen.dart';
import '../../../menu/presentation/screens/menu_screen.dart';
import '../../../menu/presentation/screens/user_guide_flow.dart';
import '../../data/models/mission.dart';
import '../providers/mission_provider.dart';
import '../widgets/agent_bottom_nav.dart';
import '../widgets/mission_card.dart';
import '../widgets/mission_ui.dart';

class AgentHomeScreen extends ConsumerWidget {
  const AgentHomeScreen({super.key});

  void _ouvrirMenu(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MenuScreen(
          titreSignalements: 'Mes missions',
          onClose: () => Navigator.of(context).pop(),
          onMonCompteTap: () {
            Navigator.of(context).pop();
            context.go('/agent/profil');
          },
          onMesSignalementsTap: () {
            Navigator.of(context).pop();
            context.go('/agent/missions');
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
            context.push('/agent/notifications');
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
                    final profil = await ref.read(profilAgentProvider.future);
                    final email = profil.email?.trim();
                    return email == null || email.isEmpty ? null : email;
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

  Future<void> _actualiser(WidgetRef ref) async {
    ref.invalidate(missionsAgentProvider);
    ref.invalidate(positionAgentProvider);
    ref.invalidate(profilAgentProvider);
    await ref.read(missionsAgentProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider).asData?.value;
    final profil = ref.watch(profilAgentProvider).asData?.value;
    final weatherAsync = ref.watch(weatherProvider);
    final missionsAsync = ref.watch(missionsAgentProvider);
    final position = ref.watch(positionAgentProvider).asData?.value;

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
                    onPressed: () => _ouvrirMenu(context, ref),
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

            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _actualiser(ref),
                color: AppColors.darkBlue,
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  children: [
                    // Localisation et météo.
                    _CarteMeteo(weatherAsync: weatherAsync, ref: ref),
                    const SizedBox(height: 20),

                    // Identité de l'agent.
                    _CarteAgent(
                      prenom: profil?.prenom ?? auth?.prenom,
                      nom: profil?.nom ?? auth?.nom,
                      structure: profil?.nomStructure,
                      matricule: profil?.matriculeAgent,
                    ),
                    const SizedBox(height: 20),

                    ...missionsAsync.when(
                      loading: () => const [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.darkBlue,
                            ),
                          ),
                        ),
                      ],
                      error: (error, _) => [
                        _Message(
                          icone: Icons.cloud_off_rounded,
                          message: 'Impossible de charger vos missions.',
                          actionLabel: 'Réessayer',
                          onAction: () => _actualiser(ref),
                        ),
                      ],
                      data: (missions) => _sectionsMissions(
                        context,
                        missions,
                        position == null
                            ? null
                            : (Mission mission) =>
                                  distanceVersMission(position, mission),
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
      bottomNavigationBar: const AgentBottomNav(currentIndex: 0),
    );
  }

  List<Widget> _sectionsMissions(
    BuildContext context,
    List<Mission> missions,
    double? Function(Mission)? distance,
  ) {
    int compter(EtatMission etat) =>
        missions.where((mission) => mission.etat == etat).length;

    final actives = missions.where((mission) => !mission.estTerminee).toList();
    final prioritaire = actives.isEmpty ? null : actives.first;

    return [
      // Statistiques.
      Row(
        children: [
          Expanded(
            child: _TuileStat(
              valeur: compter(EtatMission.enCours),
              libelle: 'En cours',
              couleur: MissionUi.couleurEtat(EtatMission.enCours),
              icone: Icons.engineering_rounded,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _TuileStat(
              valeur: compter(EtatMission.enAttenteValidation),
              libelle: 'En validation',
              couleur: MissionUi.couleurEtat(EtatMission.enAttenteValidation),
              icone: Icons.hourglass_top_rounded,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _TuileStat(
              valeur: compter(EtatMission.resolue),
              libelle: 'Résolues',
              couleur: MissionUi.couleurEtat(EtatMission.resolue),
              icone: Icons.task_alt_rounded,
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),

      // Mission prioritaire.
      if (prioritaire != null) ...[
        _CartePrioritaire(
          mission: prioritaire,
          distanceMetres: distance?.call(prioritaire),
          onTap: () => context.push(
            prioritaire.aPositionGps
                ? '/agent/missions/${prioritaire.id}/localisation'
                : '/agent/missions/${prioritaire.id}',
          ),
        ),
        const SizedBox(height: 22),
      ],

      // Missions à traiter.
      Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              color: AppColors.primaryBlue,
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mes missions',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBlue,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Les 3 missions les plus urgentes',
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
            onPressed: () => context.go('/agent/missions'),
            child: const Text(
              'Voir tout',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      if (actives.isEmpty)
        const _Message(
          icone: Icons.assignment_turned_in_outlined,
          message: 'Aucune mission en attente. Bon travail !',
        )
      else
        for (final mission in actives.take(3))
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: MissionCard(
              mission: mission,
              distanceMetres: distance?.call(mission),
              onVoirDetails: () =>
                  context.push('/agent/missions/${mission.id}'),
              onIntervenir: () =>
                  context.push('/agent/missions/${mission.id}/localisation'),
            ),
          ),
    ];
  }
}

class _CarteMeteo extends StatelessWidget {
  final AsyncValue<WeatherData> weatherAsync;
  final WidgetRef ref;

  const _CarteMeteo({required this.weatherAsync, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Container(height: 24, width: 1, color: const Color(0xFFCBD5E1)),
          const SizedBox(width: 12),
          weatherAsync.when(
            loading: () => const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryBlue,
              ),
            ),
            error: (_, _) => IconButton(
              tooltip: 'Réessayer de charger la météo',
              onPressed: () => ref.invalidate(weatherProvider),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: const Icon(
                Icons.refresh_rounded,
                color: AppColors.primaryBlue,
                size: 22,
              ),
            ),
            data: (weather) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(weather.icon, style: const TextStyle(fontSize: 20)),
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
    );
  }
}

class _CarteAgent extends StatelessWidget {
  final String? prenom;
  final String? nom;
  final String? structure;
  final String? matricule;

  const _CarteAgent({
    required this.prenom,
    required this.nom,
    required this.structure,
    required this.matricule,
  });

  @override
  Widget build(BuildContext context) {
    final heure = DateTime.now().hour;
    final salutation = heure < 18 ? 'Bonjour' : 'Bonsoir';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.darkBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkBlue.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: MissionUi.bleuAction,
            child: Text(
              MissionUi.initiales(prenom, nom),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$salutation, ${prenom ?? 'agent'} 👋',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  structure == null
                      ? 'Agent de terrain'
                      : 'Agent de terrain - $structure',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                if (matricule != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Matricule $matricule',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TuileStat extends StatelessWidget {
  final int valeur;
  final String libelle;
  final Color couleur;
  final IconData icone;

  const _TuileStat({
    required this.valeur,
    required this.libelle,
    required this.couleur,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: couleur.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icone, size: 17, color: couleur),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$valeur',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            libelle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Grande carte d'action vers la mission la plus urgente.
class _CartePrioritaire extends StatelessWidget {
  final Mission mission;
  final double? distanceMetres;
  final VoidCallback onTap;

  const _CartePrioritaire({
    required this.mission,
    required this.distanceMetres,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final couleur = mission.estUrgente
        ? const Color(0xFFFF7A00)
        : const Color(0xFF00A8B5);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: couleur,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Container(
                height: 72,
                width: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white),
                ),
                child: const Icon(
                  Icons.directions_run_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission.estUrgente
                          ? 'MISSION URGENTE • ${mission.code}'
                          : 'PROCHAINE MISSION • ${mission.code}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mission.titre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      distanceMetres == null
                          ? mission.lieu
                          : '${mission.lieu} • '
                                '${MissionUi.distanceLisible(distanceMetres!)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Intervenir',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: couleur,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: couleur,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icone;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _Message({
    required this.icone,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icone, size: 30, color: AppColors.textSecondary),
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
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

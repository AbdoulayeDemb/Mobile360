import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/mission.dart';
import '../providers/mission_provider.dart';
import '../widgets/agent_bottom_nav.dart';
import '../widgets/mission_card.dart';
import '../widgets/mission_ui.dart';

enum _FiltreMission { toutes, enCours, resolus }

class MissionsTerrainScreen extends ConsumerStatefulWidget {
  const MissionsTerrainScreen({super.key});

  @override
  ConsumerState<MissionsTerrainScreen> createState() =>
      _MissionsTerrainScreenState();
}

class _MissionsTerrainScreenState extends ConsumerState<MissionsTerrainScreen> {
  _FiltreMission _filtre = _FiltreMission.toutes;

  static const Map<_FiltreMission, String> _libellesFiltres = {
    _FiltreMission.toutes: 'Toutes',
    _FiltreMission.enCours: 'En cours',
    _FiltreMission.resolus: 'Résolus',
  };

  List<Mission> _filtrer(List<Mission> missions) {
    switch (_filtre) {
      case _FiltreMission.toutes:
        return missions;
      case _FiltreMission.enCours:
        return missions.where((mission) => !mission.estTerminee).toList();
      case _FiltreMission.resolus:
        return missions
            .where((mission) => mission.etat == EtatMission.resolue)
            .toList();
    }
  }

  Future<void> _actualiser() async {
    ref.invalidate(missionsAgentProvider);
    ref.invalidate(positionAgentProvider);
    await ref.read(missionsAgentProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider).asData?.value;
    final profilAsync = ref.watch(profilAgentProvider);
    final missionsAsync = ref.watch(missionsAgentProvider);
    final position = ref.watch(positionAgentProvider).asData?.value;

    final nomStructure = profilAsync.asData?.value.nomStructure;
    final nombreMissions = missionsAsync.asData?.value
        .where((mission) => !mission.estTerminee)
        .length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // En-tête bleu foncé : identité de l'agent.
          Container(
            width: double.infinity,
            color: AppColors.darkBlue,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 20, 18),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: MissionUi.bleuAction,
                      child: Text(
                        MissionUi.initiales(auth?.prenom, auth?.nom),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            [auth?.prenom, auth?.nom]
                                .whereType<String>()
                                .join(' ')
                                .trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            nomStructure == null || nomStructure.isEmpty
                                ? 'Agent de terrain'
                                : 'Agent de terrain - $nomStructure',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _actualiser,
              color: AppColors.darkBlue,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                children: [
                  Text(
                    nombreMissions == null
                        ? 'Missions terrain'
                        : 'Missions terrain ($nombreMissions)',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Filtres.
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _FiltreMission.values.map((filtre) {
                        final actif = filtre == _filtre;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(_libellesFiltres[filtre]!),
                            selected: actif,
                            showCheckmark: false,
                            onSelected: (_) => setState(() => _filtre = filtre),
                            backgroundColor: Colors.white,
                            selectedColor: AppColors.darkBlue,
                            side: BorderSide(
                              color: actif
                                  ? AppColors.darkBlue
                                  : MissionUi.bordure,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 6,
                            ),
                            labelStyle: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: actif
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 22),

                  ...missionsAsync.when(
                    loading: () => const [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.darkBlue,
                          ),
                        ),
                      ),
                    ],
                    error: (error, _) => [
                      _MessageVide(
                        icone: Icons.cloud_off_rounded,
                        message: error.toString(),
                        actionLabel: 'Réessayer',
                        onAction: _actualiser,
                      ),
                    ],
                    data: (missions) {
                      final filtrees = _filtrer(missions);

                      if (filtrees.isEmpty) {
                        return [
                          _MessageVide(
                            icone: Icons.assignment_turned_in_outlined,
                            message: missions.isEmpty
                                ? 'Aucune mission ne vous a encore été assignée.'
                                : 'Aucune mission dans cette catégorie.',
                          ),
                        ];
                      }

                      return [
                        for (final mission in filtrees)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: MissionCard(
                              mission: mission,
                              distanceMetres: mission.estTerminee
                                  ? null
                                  : distanceVersMission(position, mission),
                              onVoirDetails: () =>
                                  context.push('/agent/missions/${mission.id}'),
                              onIntervenir: () => context.push(
                                '/agent/missions/${mission.id}/localisation',
                              ),
                            ),
                          ),
                      ];
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AgentBottomNav(currentIndex: 1),
    );
  }
}

class _MessageVide extends StatelessWidget {
  final IconData icone;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessageVide({
    required this.icone,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icone, size: 34, color: MissionUi.texteGris),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: MissionUi.texteGris,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

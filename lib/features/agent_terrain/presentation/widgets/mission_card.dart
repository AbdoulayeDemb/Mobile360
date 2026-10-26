import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/mission.dart';
import 'mission_ui.dart';

/// Carte d'une mission terrain (liste et accueil).
class MissionCard extends StatelessWidget {
  final Mission mission;
  final double? distanceMetres;
  final VoidCallback onVoirDetails;
  final VoidCallback onIntervenir;

  const MissionCard({
    super.key,
    required this.mission,
    required this.onVoirDetails,
    required this.onIntervenir,
    this.distanceMetres,
  });

  @override
  Widget build(BuildContext context) {
    final urgence = MissionUi.urgence(mission);
    final etat = mission.etat;

    // Une mission urgente non commencée se traite directement sur le terrain.
    final afficherIntervenir =
        mission.estUrgente && !mission.estTerminee && mission.aPositionGps;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: urgence.bordure, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onVoirDetails,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    BadgeUrgence(mission: mission),
                    const Spacer(),
                    Text(
                      mission.code,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  mission.titre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  mission.lieu,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: MissionUi.texteGris,
                  ),
                ),
                if (distanceMetres != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 11,
                        color: Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'À ${MissionUi.distanceLisible(distanceMetres!)} '
                        'de votre position',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: MissionUi.bleuLien,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFEFF2F6)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        etat == EtatMission.aTraiter
                            ? 'Signalé ${MissionUi.dateRelative(mission.signalement.dateHeureAlerte)}'
                            : 'Statut: ${MissionUi.libelleEtat(etat)}',
                        maxLines: 2,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: etat == EtatMission.aTraiter
                              ? FontWeight.w400
                              : FontWeight.w600,
                          color: etat == EtatMission.aTraiter
                              ? MissionUi.texteGris
                              : MissionUi.couleurEtat(etat),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 32,
                      child: FilledButton(
                        onPressed: afficherIntervenir
                            ? onIntervenir
                            : onVoirDetails,
                        style: FilledButton.styleFrom(
                          backgroundColor: MissionUi.bleuAction,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: afficherIntervenir ? 28 : 22,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          afficherIntervenir ? 'Intervenir' : 'Voir détails >',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: afficherIntervenir ? 13 : 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

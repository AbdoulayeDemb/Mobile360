import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/network/media_url_helper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/mission.dart';
import '../providers/mission_provider.dart';
import '../widgets/agent_page_header.dart';
import '../widgets/mission_ui.dart';

class MissionDetailScreen extends ConsumerStatefulWidget {
  final int idSignalement;

  const MissionDetailScreen({super.key, required this.idSignalement});

  @override
  ConsumerState<MissionDetailScreen> createState() =>
      _MissionDetailScreenState();
}

class _MissionDetailScreenState extends ConsumerState<MissionDetailScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _lectureEnCours = false;
  bool _chargementAudio = false;
  bool _audioCharge = false;

  @override
  void initState() {
    super.initState();

    _audioPlayer.playerStateStream.listen((etat) {
      if (!mounted) return;

      setState(() {
        _lectureEnCours =
            etat.playing && etat.processingState != ProcessingState.completed;
        _chargementAudio =
            etat.processingState == ProcessingState.loading ||
            etat.processingState == ProcessingState.buffering;
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _basculerAudio(String url) async {
    try {
      if (_audioPlayer.playing) {
        await _audioPlayer.pause();
        return;
      }

      if (!_audioCharge) {
        await _audioPlayer.setUrl(url);
        _audioCharge = true;
      } else if (_audioPlayer.processingState == ProcessingState.completed) {
        await _audioPlayer.seek(Duration.zero);
      }

      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Erreur de lecture audio : $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de lire la note vocale.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final missionAsync = ref.watch(missionDetailProvider(widget.idSignalement));
    final mission = missionAsync.asData?.value;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            AgentPageHeader(
              titre: mission == null ? 'Mission' : 'Mission ${mission.code}',
              sousTitre: 'Signalement transmis par le citoyen',
              action: mission == null ? null : BadgeUrgence(mission: mission),
            ),
            Expanded(
              child: missionAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.darkBlue),
                ),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 42,
                          color: Color(0xFFDC2626),
                        ),
                        const SizedBox(height: 10),
                        Text(error.toString(), textAlign: TextAlign.center),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () => ref.invalidate(
                            missionDetailProvider(widget.idSignalement),
                          ),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: _contenu,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: mission == null ? null : _boutons(mission),
    );
  }

  Widget _contenu(Mission mission) {
    final signalement = mission.signalement;
    final photoUrl = MediaUrlHelper.construireUrl(signalement.photoAvantUrl);
    final audioUrl = MediaUrlHelper.construireUrl(signalement.audioUrl);
    final description = signalement.description?.trim() ?? '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      children: [
        // Photo transmise par le citoyen.
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 165,
            child: Stack(
              fit: StackFit.expand,
              children: [
                photoUrl.isEmpty
                    ? _photoAbsente()
                    : Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _photoAbsente(),
                      ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 18, 14, 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: const Text(
                      'Photo transmise par le citoyen',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),

        Text(
          mission.titre,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Signalé ${MissionUi.dateRelative(signalement.dateHeureAlerte)}'
          '  •  ${MissionUi.libelleEtat(mission.etat)}',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            color: MissionUi.texteGris,
          ),
        ),
        const SizedBox(height: 14),

        // Description du citoyen.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: MissionUi.fondGris,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            description.isEmpty
                ? 'Aucune description fournie.'
                : '"$description"',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              height: 1.8,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Localisation : ouvre l'itinéraire.
        Material(
          color: const Color(0xFFE8EBF2),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: mission.aPositionGps
                ? () => context.push('/agent/missions/${mission.id}/localisation')
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: MissionUi.bleuAction,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mission.lieu,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          mission.aPositionGps
                              ? 'GPS: ${_coordonnee(signalement.latitudeGPS!, 'N', 'S')}, '
                                    '${_coordonnee(signalement.longitudeGPS!, 'E', 'W')}'
                              : 'Coordonnées GPS indisponibles',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 9,
                            color: MissionUi.bleuLien,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (mission.aPositionGps)
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: MissionUi.texteGris,
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Note vocale.
        if (audioUrl.isNotEmpty)
          Material(
            color: const Color(0xFFF0F6FC),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _basculerAudio(audioUrl),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFF3B6EA8),
                        shape: BoxShape.circle,
                      ),
                      child: _chargementAudio
                          ? const Padding(
                              padding: EdgeInsets.all(9),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              _lectureEnCours
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Note vocale',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3B6EA8),
                          ),
                        ),
                        Text(
                          _lectureEnCours
                              ? 'Lecture en cours...'
                              : 'Appuyez pour écouter',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3B6EA8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _boutons(Mission mission) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 8, 28, 20),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 54,
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: Color(0xFF94A3B8)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Annuler',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 22),
            Expanded(
              child: SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: () =>
                      context.push('/agent/missions/${mission.id}/rapport'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    mission.estTerminee ? 'Rapport' : 'Suivant',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _coordonnee(double valeur, String positif, String negatif) {
    return '${valeur.abs().toStringAsFixed(4)}° ${valeur >= 0 ? positif : negatif}';
  }

  Widget _photoAbsente() {
    return Container(
      color: const Color(0xFFEAF0FF),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported_outlined,
        size: 40,
        color: AppColors.primaryBlue,
      ),
    );
  }
}

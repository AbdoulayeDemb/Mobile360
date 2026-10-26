import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/media_url_helper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/mission.dart';
import '../../data/models/preuve_resolution.dart';
import '../providers/mission_provider.dart';
import '../widgets/agent_page_header.dart';

class RapportInterventionScreen extends ConsumerWidget {
  final int idSignalement;

  const RapportInterventionScreen({super.key, required this.idSignalement});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionAsync = ref.watch(missionDetailProvider(idSignalement));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AgentPageHeader(
              titre: 'Rapport d’intervention',
              sousTitre: 'Photo ou rapport comme preuve pour le citoyen',
            ),
            Expanded(
              child: missionAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.darkBlue),
                ),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(error.toString(), textAlign: TextAlign.center),
                  ),
                ),
                data: (mission) => _FormulaireRapport(mission: mission),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormulaireRapport extends ConsumerStatefulWidget {
  final Mission mission;

  const _FormulaireRapport({required this.mission});

  @override
  ConsumerState<_FormulaireRapport> createState() => _FormulaireRapportState();
}

class _FormulaireRapportState extends ConsumerState<_FormulaireRapport> {
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _rapportController = TextEditingController();

  late StatutPropose _statut;
  File? _photo;

  bool get _lectureSeule => widget.mission.estTerminee;

  String? get _photoExistanteUrl {
    final url = MediaUrlHelper.construireUrl(
      widget.mission.preuve?.photoApresUrl,
    );
    return url.isEmpty ? null : url;
  }

  @override
  void initState() {
    super.initState();

    final preuve = widget.mission.preuve;
    _statut = preuve?.statutPropose ?? StatutPropose.resolu;
    _rapportController.text = preuve?.rapportSansStatut ?? '';
  }

  @override
  void dispose() {
    _rapportController.dispose();
    super.dispose();
  }

  Future<void> _prendrePhoto() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
      );

      if (image == null || !mounted) return;

      setState(() => _photo = File(image.path));
    } catch (e) {
      debugPrint('Erreur caméra : $e');
      _afficherPopup(
        titre: 'Caméra indisponible',
        message: 'Autorisez l’accès à la caméra pour photographier la réparation.',
        erreur: true,
      );
    }
  }

  /// Message d'erreur si le rapport est incomplet, sinon null.
  String? _verifierRapport() {
    final rapport = _rapportController.text.trim();
    final aUnePhoto = _photo != null || _photoExistanteUrl != null;

    switch (_statut) {
      case StatutPropose.resolu:
        if (!aUnePhoto) {
          return 'Prenez une photo de la réparation pour prouver '
              'la résolution du signalement.';
        }
        return null;
      case StatutPropose.enCours:
        if (rapport.isEmpty) {
          return 'Décrivez l’avancement de l’intervention dans le rapport.';
        }
        return null;
      case StatutPropose.rejete:
        if (rapport.isEmpty) {
          return 'Expliquez dans le rapport pourquoi ce signalement '
              'doit être rejeté.';
        }
        return null;
    }
  }

  Future<void> _enregistrer() async {
    FocusScope.of(context).unfocus();

    final erreur = _verifierRapport();

    if (erreur != null) {
      await _afficherPopup(
        titre: 'Rapport incomplet',
        message: erreur,
        erreur: true,
      );
      return;
    }

    try {
      await ref
          .read(rapportInterventionProvider.notifier)
          .envoyerRapport(
            mission: widget.mission,
            statut: _statut,
            rapport: _rapportController.text,
            photo: _photo,
          );

      if (!mounted) return;

      await _afficherPopup(
        titre: _statut == StatutPropose.enCours
            ? 'Avancement enregistré'
            : 'Rapport envoyé !',
        message: _statut == StatutPropose.enCours
            ? 'Votre responsable peut suivre l’avancement de la mission.'
            : 'Votre rapport a été transmis à votre responsable. '
                  'Le statut sera mis à jour après sa validation.',
      );

      if (mounted) context.go('/agent/missions');
    } catch (error) {
      if (!mounted) return;

      await _afficherPopup(
        titre: 'Envoi impossible',
        message: error.toString(),
        erreur: true,
      );
    }
  }

  Future<void> _afficherPopup({
    required String titre,
    required String message,
    bool erreur = false,
  }) async {
    if (!mounted) return;

    final couleur = erreur ? const Color(0xFFDC2626) : const Color(0xFF10B981);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: couleur.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    erreur
                        ? Icons.error_outline_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 38,
                    color: couleur,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  titre,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF172B4D),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: FilledButton.styleFrom(
                      backgroundColor: couleur,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Compris',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final envoiEnCours = ref.watch(rapportInterventionProvider).isLoading;
    final mission = widget.mission;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            children: [
              _bandeau(mission),
              const SizedBox(height: 16),

              _titre('Mettre à jour le statut :'),
              const SizedBox(height: 12),
              Row(
                children: [
                  _boutonStatut(
                    StatutPropose.enCours,
                    const Color(0xFFF59E0B),
                    envoiEnCours,
                  ),
                  const SizedBox(width: 9),
                  _boutonStatut(
                    StatutPropose.resolu,
                    const Color(0xFF10B981),
                    envoiEnCours,
                  ),
                  const SizedBox(width: 9),
                  _boutonStatut(
                    StatutPropose.rejete,
                    const Color(0xFFDC2626),
                    envoiEnCours,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _titre('Photo APRÈS intervention (Preuve)'),
              const SizedBox(height: 12),
              _zonePhoto(envoiEnCours),
              const SizedBox(height: 20),

              _titre('Rapport de l’agent :'),
              const SizedBox(height: 12),
              TextField(
                controller: _rapportController,
                enabled: !_lectureSeule && !envoiEnCours,
                minLines: 4,
                maxLines: 6,
                maxLength: 1000,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  height: 1.7,
                  color: AppColors.textSecondary,
                ),
                decoration: InputDecoration(
                  hintText: 'Décrivez l’intervention réalisée...',
                  hintStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(14),
                  border: _bordure(),
                  enabledBorder: _bordure(),
                  disabledBorder: _bordure(),
                  focusedBorder: _bordure(couleur: AppColors.primaryBlue),
                ),
              ),
            ],
          ),
        ),
        if (!_lectureSeule)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
              child: SizedBox(
                width: 156,
                height: 54,
                child: FilledButton(
                  onPressed: envoiEnCours ? null : _enregistrer,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF94A3B8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: envoiEnCours
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Enregistrer',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _bandeau(Mission mission) {
    final String texte;
    final Color couleur;
    final Color fond;

    switch (mission.etat) {
      case EtatMission.resolue:
        texte = 'Signalement ${mission.code} résolu';
        couleur = const Color(0xFF10B981);
        fond = const Color(0xFFEAFBF3);
      case EtatMission.rejetee:
        texte = 'Signalement ${mission.code} rejeté';
        couleur = const Color(0xFFDC2626);
        fond = const Color(0xFFFEF2F2);
      case EtatMission.enAttenteValidation:
        texte = 'Rapport ${mission.code} en attente de validation';
        couleur = const Color(0xFF7C3AED);
        fond = const Color(0xFFF3EEFF);
      case EtatMission.aTraiter:
      case EtatMission.enCours:
        texte = 'Clôture du signalement ${mission.code}';
        couleur = const Color(0xFF10B981);
        fond = const Color(0xFFEAFBF3);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '✓ $texte',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: couleur,
        ),
      ),
    );
  }

  Widget _titre(String texte) {
    return Text(
      texte,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFF334155),
      ),
    );
  }

  Widget _boutonStatut(StatutPropose statut, Color couleur, bool envoiEnCours) {
    final actif = _statut == statut;
    final modifiable = !_lectureSeule && !envoiEnCours;

    return Expanded(
      child: SizedBox(
        height: 46,
        child: FilledButton(
          onPressed: modifiable ? () => setState(() => _statut = statut) : null,
          style: FilledButton.styleFrom(
            backgroundColor: actif ? couleur : couleur.withValues(alpha: 0.35),
            disabledBackgroundColor: actif
                ? couleur
                : couleur.withValues(alpha: 0.2),
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              actif ? '✓ ${statut.libelle}' : statut.libelle,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _zonePhoto(bool envoiEnCours) {
    final photoExistante = _photoExistanteUrl;
    final aUneImage = _photo != null || photoExistante != null;

    return GestureDetector(
      onTap: _lectureSeule || envoiEnCours ? null : _prendrePhoto,
      child: CustomPaint(
        painter: _BordurePointillee(),
        child: SizedBox(
          height: 150,
          width: double.infinity,
          child: aUneImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _photo != null
                          ? Image.file(_photo!, fit: BoxFit.cover)
                          : Image.network(photoExistante!, fit: BoxFit.cover),
                      if (!_lectureSeule)
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.camera_alt_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Reprendre',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.darkBlue),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 32,
                        color: AppColors.darkBlue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _lectureSeule
                          ? 'Aucune photo transmise'
                          : 'Prendre photo de la réparation',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkBlue,
                      ),
                    ),
                    if (!_lectureSeule) ...[
                      const SizedBox(height: 6),
                      const Text(
                        'Ouvre la caméra mobile',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 7,
                          color: AppColors.darkBlue,
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  OutlineInputBorder _bordure({Color couleur = const Color(0xFFCBD5E1)}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: couleur),
    );
  }
}

/// Bordure en pointillés de la zone photo.
class _BordurePointillee extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pinceau = Paint()
      ..color = AppColors.darkBlue
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final chemin = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10)),
      );

    const longueurTrait = 6.0;
    const espace = 4.0;

    for (final contour in chemin.computeMetrics()) {
      var distance = 0.0;
      while (distance < contour.length) {
        canvas.drawPath(
          contour.extractPath(distance, distance + longueurTrait),
          pinceau,
        );
        distance += longueurTrait + espace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

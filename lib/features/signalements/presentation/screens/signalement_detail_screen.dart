import 'package:alert360_mobile/features/signalements/data/models/signalement.dart';
import 'package:alert360_mobile/features/signalements/data/services/signalement_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignalementDetailScreen extends ConsumerStatefulWidget {
  final Signalement? signalement;
  final String? signalementId;
  final VoidCallback? onBack;

  const SignalementDetailScreen({
    super.key,
    this.signalement,
    this.signalementId,
    this.onBack,
  });

  @override
  ConsumerState<SignalementDetailScreen> createState() =>
      _SignalementDetailScreenState();
}

class _SignalementDetailScreenState
    extends ConsumerState<SignalementDetailScreen> {
  final SignalementService _signalementService = SignalementService();

  Signalement? _signalement;
  bool _isLoading = false;
  bool _isPlayingAudio = false;
  String? _errorMessage;

  static const Color _primaryColor = Color(0xFF2563EB);
  static const Color _backgroundColor = Color(0xFFF8FAFC);
  static const Color _textColor = Color(0xFF1E293B);
  static const Color _secondaryTextColor = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();

    if (widget.signalement != null) {
      _signalement = widget.signalement;
    } else {
      _chargerSignalement();
    }
  }

  @override
  void didUpdateWidget(covariant SignalementDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.signalement != oldWidget.signalement ||
        widget.signalementId != oldWidget.signalementId) {
      if (widget.signalement != null) {
        setState(() {
          _signalement = widget.signalement;
          _errorMessage = null;
          _isPlayingAudio = false;
        });
      } else {
        _chargerSignalement();
      }
    }
  }

  Future<void> _chargerSignalement() async {
    final String? idTexte = widget.signalementId;

    if (idTexte == null || idTexte.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Aucun signalement n’a été fourni.';
        _isLoading = false;
      });
      return;
    }

    final int? id = int.tryParse(idTexte);

    if (id == null) {
      setState(() {
        _errorMessage = 'L’identifiant du signalement est invalide.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dynamic response = await _signalementService.getSignalementById(id);

      if (response is! Map) {
        throw Exception('Format de réponse inattendu.');
      }

      final signalement = Signalement.fromJson(
        Map<String, dynamic>.from(response),
      );

      if (!mounted) return;

      setState(() {
        _signalement = signalement;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Impossible de charger les détails du signalement.';
      });

      debugPrint('Erreur chargement signalement : $e');
    }
  }

  String _statutLisible(String? statut) {
    switch (statut?.toUpperCase()) {
      case 'DECLARE':
        return 'Déclaré';
      case 'EN_COURS':
        return 'En cours';
      case 'RESOLU':
        return 'Résolu';
      case 'REJETE':
        return 'Rejeté';
      default:
        return statut ?? 'Statut inconnu';
    }
  }

  Color _fondStatut(String? statut) {
    switch (statut?.toUpperCase()) {
      case 'DECLARE':
        return const Color(0xFFDBEAFE);
      case 'EN_COURS':
        return const Color(0xFFFEF3C7);
      case 'RESOLU':
        return const Color(0xFFDCFCE7);
      case 'REJETE':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Color _couleurTexteStatut(String? statut) {
    switch (statut?.toUpperCase()) {
      case 'DECLARE':
        return const Color(0xFF1D4ED8);
      case 'EN_COURS':
        return const Color(0xFF92400E);
      case 'RESOLU':
        return const Color(0xFF166534);
      case 'REJETE':
        return const Color(0xFFB91C1C);
      default:
        return _secondaryTextColor;
    }
  }

  String _urgenceLisible(String? urgence) {
    switch (urgence?.toUpperCase()) {
      case 'FAIBLE':
        return 'Faible';
      case 'MOYENNE':
        return 'Moyenne';
      case 'ELEVEE':
        return 'Élevée';
      case 'CRITIQUE':
        return 'Critique';
      default:
        return urgence ?? 'Non précisée';
    }
  }

  Color _couleurUrgence(String? urgence) {
    switch (urgence?.toUpperCase()) {
      case 'FAIBLE':
        return const Color(0xFF16A34A);
      case 'MOYENNE':
        return const Color(0xFFD97706);
      case 'ELEVEE':
        return const Color(0xFFEA580C);
      case 'CRITIQUE':
        return const Color(0xFFDC2626);
      default:
        return _secondaryTextColor;
    }
  }

  String _dateLisible(DateTime? date) {
    if (date == null) return 'Date non disponible';

    final jour = date.day.toString().padLeft(2, '0');
    final mois = date.month.toString().padLeft(2, '0');
    final annee = date.year.toString();
    final heure = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$jour/$mois/$annee à $heure:$minute';
  }

  String _positionLisible(Signalement signalement) {
    final repere = signalement.repereVisuel?.trim();

    if (repere != null && repere.isNotEmpty) {
      return repere;
    }

    final latitude = signalement.latitudeGPS;
    final longitude = signalement.longitudeGPS;

    if (latitude != null && longitude != null) {
      return '${latitude.toStringAsFixed(5)}, '
          '${longitude.toStringAsFixed(5)}';
    }

    return 'Position non renseignée';
  }

  void _retour() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _construireEntete(),
            Expanded(child: _construireContenu()),
          ],
        ),
      ),
    );
  }

  Widget _construireEntete() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _borderColor)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: _retour,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderColor),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 19,
                color: _textColor,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mes signalements',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _textColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Voir tous mes signalements',
                  style: TextStyle(fontSize: 13, color: _secondaryTextColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construireContenu() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primaryColor),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 54,
                color: _secondaryTextColor,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: _textColor),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _chargerSignalement,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final signalement = _signalement;

    if (signalement == null) {
      return const Center(child: Text('Aucun détail disponible.'));
    }

    return RefreshIndicator(
      color: _primaryColor,
      onRefresh: _chargerSignalement,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          _construirePhoto(signalement),
          const SizedBox(height: 20),
          _construireCarteInformations(signalement),
          const SizedBox(height: 16),
          _construireCarteLocalisation(signalement),
          const SizedBox(height: 16),
          _construireCarteAudio(signalement),
        ],
      ),
    );
  }

  Widget _construirePhoto(Signalement signalement) {
    final photoUrl = signalement.photoAvantUrl?.trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 220,
        width: double.infinity,
        color: const Color(0xFFE2E8F0),
        child: photoUrl != null && photoUrl.isNotEmpty
            ? Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _photoIndisponible();
                },
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;

                  return const Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  );
                },
              )
            : _photoIndisponible(),
      ),
    );
  }

  Widget _photoIndisponible() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.image_not_supported_outlined,
          size: 48,
          color: _secondaryTextColor,
        ),
        SizedBox(height: 8),
        Text(
          'Aucune photo disponible',
          style: TextStyle(fontSize: 14, color: _secondaryTextColor),
        ),
      ],
    );
  }

  Widget _construireCarteInformations(Signalement signalement) {
    final description = signalement.description?.trim();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  'Détails du signalement',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _textColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: _fondStatut(signalement.statut),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statutLisible(signalement.statut),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _couleurTexteStatut(signalement.statut),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _secondaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description != null && description.isNotEmpty
                ? description
                : 'Aucune description disponible.',
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: _borderColor),
          const SizedBox(height: 14),
          _ligneInformation(
            icone: Icons.category_outlined,
            titre: 'Catégorie',
            valeur: signalement.categorieNom?.trim().isNotEmpty == true
                ? signalement.categorieNom!
                : 'Non renseignée',
          ),
          const SizedBox(height: 18),
          _ligneInformation(
            icone: Icons.warning_amber_rounded,
            titre: 'Niveau d’urgence',
            valeur: _urgenceLisible(signalement.typeUrgence),
            valeurCouleur: _couleurUrgence(signalement.typeUrgence),
          ),
          const SizedBox(height: 18),
          _ligneInformation(
            icone: Icons.calendar_today_outlined,
            titre: 'Date de déclaration',
            valeur: _dateLisible(signalement.dateHeureAlerte),
          ),
          const SizedBox(height: 18),
          _ligneInformation(
            icone: Icons.confirmation_number_outlined,
            titre: 'Code de suivi',
            valeur: signalement.codeTrackingUnique?.trim().isNotEmpty == true
                ? signalement.codeTrackingUnique!
                : 'Non disponible',
          ),
        ],
      ),
    );
  }

  Widget _construireCarteLocalisation(Signalement signalement) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on_outlined, color: _primaryColor, size: 22),
              SizedBox(width: 8),
              Text(
                'Localisation',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _positionLisible(signalement),
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: _textColor,
            ),
          ),
          if (signalement.latitudeGPS != null &&
              signalement.longitudeGPS != null) ...[
            const SizedBox(height: 8),
            Text(
              'Latitude : ${signalement.latitudeGPS}\n'
              'Longitude : ${signalement.longitudeGPS}',
              style: const TextStyle(
                fontSize: 12,
                height: 1.6,
                color: _secondaryTextColor,
              ),
            ),
          ],
          const SizedBox(height: 18),
          const Divider(color: _borderColor),
          const SizedBox(height: 14),
          _ligneInformation(
            icone: Icons.apartment_outlined,
            titre: 'Structure assignée',
            valeur: signalement.structureAssigneeNom?.trim().isNotEmpty == true
                ? signalement.structureAssigneeNom!
                : 'Aucune structure assignée',
          ),
        ],
      ),
    );
  }

  Widget _construireCarteAudio(Signalement signalement) {
    final audioUrl = signalement.audioUrl?.trim();
    final audioDisponible = audioUrl != null && audioUrl.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.mic_none_rounded, color: _primaryColor, size: 22),
              SizedBox(width: 8),
              Text(
                'Note vocale',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: audioDisponible
                        ? _primaryColor.withValues(alpha: 0.10)
                        : const Color(0xFFE2E8F0),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    audioDisponible
                        ? Icons.audiotrack_rounded
                        : Icons.mic_off_outlined,
                    color: audioDisponible
                        ? _primaryColor
                        : _secondaryTextColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    audioDisponible
                        ? 'Enregistrement disponible'
                        : 'Aucune note vocale disponible',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _textColor,
                    ),
                  ),
                ),
                if (audioDisponible)
                  IconButton(
                    tooltip: 'La lecture audio nécessite un lecteur audio',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Ajoute un lecteur audio au projet pour écouter cet enregistrement.',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.play_circle_outline_rounded,
                      color: _primaryColor,
                      size: 32,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ligneInformation({
    required IconData icone,
    required String titre,
    required String valeur,
    Color? valeurCouleur,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icone, size: 20, color: _primaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titre,
                style: const TextStyle(
                  fontSize: 12,
                  color: _secondaryTextColor,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                valeur,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valeurCouleur ?? _textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

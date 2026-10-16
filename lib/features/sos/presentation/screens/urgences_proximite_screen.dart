import 'dart:async';

import 'package:alert360_mobile/features/sos/data/models/sos_structure.dart';
import 'package:alert360_mobile/features/sos/data/services/sos_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';

class UrgencesProximiteScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final String positionActuelle;

  const UrgencesProximiteScreen({
    super.key,
    this.onBack,
    this.positionActuelle = 'Localisation en cours...',
  });

  @override
  State<UrgencesProximiteScreen> createState() =>
      _UrgencesProximiteScreenState();
}

class _UrgencesProximiteScreenState extends State<UrgencesProximiteScreen> {
  final SosService _sosService = SosService();

  List<SosStructure> _structures = [];

  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  String _positionActuelle = 'Localisation non déterminée';

  @override
  void initState() {
    super.initState();
    _chargerUrgences();
  }

  // ============================================================
  // CHARGEMENT GPS ET DES STRUCTURES DE SECOURS
  // ============================================================

  Future<void> _chargerUrgences() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _isRefreshing = false;
      _errorMessage = null;
    });

    try {
      // 1. Vérifier que le GPS est activé.
      final bool serviceActive = await Geolocator.isLocationServiceEnabled();

      if (!serviceActive) {
        throw Exception(
          'La localisation GPS est désactivée. '
          'Activez-la pour rechercher les secours à proximité.',
        );
      }

      // 2. Vérifier la permission de localisation.
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception('La permission de localisation a été refusée.');
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'La permission GPS est définitivement refusée. '
          'Autorisez la localisation dans les paramètres du téléphone.',
        );
      }

      // 3. Récupérer la position GPS réelle.
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      if (!mounted) return;

      final String coordonnees =
          '${position.latitude.toStringAsFixed(5)}, '
          '${position.longitude.toStringAsFixed(5)}';

      setState(() {
        _positionActuelle = coordonnees;
      });

      // 4. Interroger le backend avec les coordonnées GPS.
      final List<SosStructure> result = await _sosService
          .obtenirStructuresProches(
            latitude: position.latitude,
            longitude: position.longitude,
            rayonKm: 15,
          );

      if (!mounted) return;

      // 5. Ne conserver que la police et les sapeurs-pompiers.
      final structuresFiltrees = result.where((structure) {
        final type = structure.typeStructure.trim().toUpperCase();

        return type == 'POLICE' || type == 'SAPEURS_POMPIERS';
      }).toList();

      // 6. Trier les structures par distance croissante.
      structuresFiltrees.sort(
        (a, b) => a.distanceEnMetres.compareTo(b.distanceEnMetres),
      );

      setState(() {
        _structures = structuresFiltrees;
        _isLoading = false;
        _isRefreshing = false;
        _errorMessage = null;
      });
    } on TimeoutException {
      _afficherErreur(
        'La récupération de votre position a pris trop de temps. '
        'Vérifiez votre GPS et réessayez.',
      );
    } catch (e) {
      _afficherErreur(_nettoyerErreur(e));
    }
  }

  void _afficherErreur(String message) {
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _isRefreshing = false;
      _errorMessage = message;
    });
  }

  String _nettoyerErreur(Object error) {
    final String message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }

    return message;
  }

  Future<void> _actualiser() async {
    if (_isRefreshing || _isLoading) return;

    setState(() {
      _isRefreshing = true;
    });

    await _chargerUrgences();
  }

  // ============================================================
  // APPEL TÉLÉPHONIQUE
  // ============================================================

  Future<void> _passerAppel(String? numero) async {
    final String? numeroNettoye = numero?.trim();

    if (numeroNettoye == null || numeroNettoye.isEmpty) {
      _afficherMessage(
        'Aucun numéro de téléphone disponible pour cette structure.',
      );
      return;
    }

    final Uri uri = Uri(scheme: 'tel', path: numeroNettoye);

    try {
      final bool ouvert = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!ouvert) {
        _afficherMessage('Impossible d’ouvrir l’application Téléphone.');
      }
    } catch (e) {
      _afficherMessage(
        'Impossible de préparer l’appel. Vérifiez que votre téléphone '
        'dispose d’une application d’appel.',
      );
    }
  }

  void _afficherMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  bool _estPompier(SosStructure structure) {
    return structure.typeStructure.trim().toUpperCase() == 'SAPEURS_POMPIERS';
  }

  // ============================================================
  // INTERFACE PRINCIPALE
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _actualiser,
              child: _buildContenu(),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EN-TÊTE
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 16,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(color: Color(0xFFF97316)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: widget.onBack ?? () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'URGENCES À PROXIMITÉ',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Actualiser',
                onPressed: _isLoading ? null : _actualiser,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.only(left: 52),
            child: Text(
              'Les secours les plus proches de votre position',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                color: Colors.white70,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isLoading
                        ? 'Récupération de votre position GPS...'
                        : 'Votre position GPS : $_positionActuelle',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONTENU
  // ============================================================

  Widget _buildContenu() {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: const [
          SizedBox(height: 100),
          Center(child: CircularProgressIndicator(color: Color(0xFFF97316))),
          SizedBox(height: 20),
          Center(
            child: Text(
              'Recherche des structures de secours à proximité...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 70),
          const Icon(
            Icons.location_off_rounded,
            size: 64,
            color: Color(0xFFF97316),
          ),
          const SizedBox(height: 16),
          const Text(
            'Localisation ou chargement indisponible',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkBlue,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 22),
          ElevatedButton.icon(
            onPressed: _chargerUrgences,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF97316),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: Geolocator.openLocationSettings,
            icon: const Icon(Icons.settings_rounded),
            label: const Text('Paramètres de localisation'),
          ),
          OutlinedButton.icon(
            onPressed: Geolocator.openAppSettings,
            icon: const Icon(Icons.app_settings_alt_rounded),
            label: const Text('Autorisations de l’application'),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        _buildCarteRadar(),
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(
              child: Text(
                'STRUCTURES COMPÉTENTES À PROXIMITÉ',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkBlue,
                ),
              ),
            ),
            if (_isRefreshing)
              const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${_structures.length} structure(s) trouvée(s) '
          'dans un rayon de 15 km',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 14),
        if (_structures.isEmpty)
          _buildAucuneStructure()
        else
          ..._structures.map(
            (structure) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildCarteStructure(structure),
            ),
          ),
        const SizedBox(height: 8),
        const Text(
          'Les distances sont calculées à partir de votre position GPS. '
          'Vérifiez le numéro avant d’appeler.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // APERÇU VISUEL DU RADAR
  // ============================================================

  Widget _buildCarteRadar() {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              color: const Color(0xFFCBD5E1),
              child: const Center(
                child: Icon(Icons.map_rounded, size: 50, color: Colors.white70),
              ),
            ),
            Container(
              height: 75,
              width: 75,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF97316).withValues(alpha: 0.12),
                border: Border.all(
                  color: const Color(0xFFF97316).withValues(alpha: 0.5),
                ),
              ),
            ),
            Container(
              height: 14,
              width: 14,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF97316),
              ),
            ),
            Positioned(
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Votre position GPS',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBlue,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // AUCUNE STRUCTURE
  // ============================================================

  Widget _buildAucuneStructure() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.location_searching_rounded,
            size: 48,
            color: Color(0xFFF97316),
          ),
          SizedBox(height: 12),
          Text(
            'Aucune structure trouvée',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.darkBlue,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Aucune structure de police ou de sapeurs-pompiers '
            'n’a été retournée dans ce rayon. Réessayez ou '
            'contactez directement les services d’urgence locaux.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARTE D'UNE STRUCTURE
  // ============================================================

  Widget _buildCarteStructure(SosStructure structure) {
    final bool estPompier = _estPompier(structure);

    final IconData iconData = estPompier
        ? Icons.local_fire_department_rounded
        : Icons.shield_rounded;

    final Color iconBgColor = estPompier
        ? const Color(0xFFFEF3C7)
        : const Color(0xFFEFF6FF);

    final Color iconColor = estPompier
        ? const Color(0xFFD97706)
        : const Color(0xFF2563EB);

    final Color buttonColor = estPompier
        ? const Color(0xFFF97316)
        : AppColors.darkBlue;

    final String? quartier = structure.quartier?.trim();

    final String subtitle = [
      if (quartier != null && quartier.isNotEmpty) quartier,
      structure.distanceFormatee,
    ].join(' — ');

    final String? telephone = structure.telephoneUrgence?.trim();

    final bool possedeTelephone = telephone != null && telephone.isNotEmpty;

    return _StructureCard(
      iconData: iconData,
      iconBgColor: iconBgColor,
      iconColor: iconColor,
      title: structure.nomStructure,
      subtitle: subtitle,
      description: estPompier
          ? 'Sapeurs-pompiers : incendies et opérations de secours.'
          : 'Police : sécurité publique et interventions policières.',
      buttonText: possedeTelephone
          ? 'APPELER $telephone'
          : 'NUMÉRO INDISPONIBLE',
      buttonColor: buttonColor,
      enabled: possedeTelephone,
      onPressed: () {
        if (possedeTelephone) {
          _passerAppel(telephone);
        } else {
          _afficherMessage(
            'Cette structure ne possède pas de numéro renseigné.',
          );
        }
      },
    );
  }
}

// ============================================================
// WIDGET RÉUTILISABLE : CARTE DE STRUCTURE
// ============================================================

class _StructureCard extends StatelessWidget {
  final IconData iconData;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String description;
  final String buttonText;
  final Color buttonColor;
  final VoidCallback onPressed;
  final bool enabled;

  const _StructureCard({
    required this.iconData,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.buttonText,
    required this.buttonColor,
    required this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: enabled ? onPressed : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFCBD5E1),
                disabledForegroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.phone_rounded, size: 18),
              label: Text(
                buttonText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

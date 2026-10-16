import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:alert360_mobile/features/signalements/data/services/signalement_service.dart';
import 'package:alert360_mobile/features/signalements/presentation/screens/mes_signalements_screen.dart';
import 'package:alert360_mobile/features/signalements/presentation/screens/signalement_confirmation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/signalement_request.dart';
import '../../data/repositories/signalement_repository.dart';

final signalementRepositoryProvider = Provider<SignalementRepository>((ref) {
  return SignalementRepository();
});

class ProblemDetailsScreen extends ConsumerStatefulWidget {
  final int categoryId;
  final String categoryTitle;
  final VoidCallback? onBack;
  final VoidCallback? onSubmitSignalement;

  const ProblemDetailsScreen({
    super.key,
    required this.categoryId,
    required this.categoryTitle,
    this.onBack,
    this.onSubmitSignalement,
  });

  @override
  ConsumerState<ProblemDetailsScreen> createState() =>
      _ProblemDetailsScreenState();
}

class _ProblemDetailsScreenState extends ConsumerState<ProblemDetailsScreen> {
  final TextEditingController _descriptionController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  static const int _maxAudioSeconds = 30;

  Position? _position;

  File? _photoFile;
  String? _audioPath;

  bool _isLoadingLocation = true;
  bool _isSubmitting = false;
  bool _isRecording = false;
  bool _isPlayingAudio = false;
  bool _isTakingPhoto = false;

  String? _locationError;
  String? _quartier;
  String? _adresse;

  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;

  static const List<String> _niveauxUrgence = [
    'FAIBLE',
    'MOYENNE',
    'ELEVEE',
    'CRITIQUE',
  ];

  String _selectedUrgence = 'MOYENNE';

  String _libelleUrgence(String niveau) {
    switch (niveau) {
      case 'FAIBLE':
        return 'Faible';
      case 'MOYENNE':
        return 'Moyenne';
      case 'ELEVEE':
        return 'Élevée';
      case 'CRITIQUE':
        return 'Critique';
      default:
        return niveau;
    }
  }

  Color _couleurUrgence(String niveau) {
    switch (niveau) {
      case 'FAIBLE':
        return Colors.green;
      case 'MOYENNE':
        return Colors.orange;
      case 'ELEVEE':
        return Colors.deepOrange;
      case 'CRITIQUE':
        return Colors.red;
      default:
        return AppColors.primaryBlue;
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.darkBlue,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  // Supprimer la photo sélectionnée
  void _supprimerPhoto() {
    setState(() {
      _photoFile = null;
    });
  }

  @override
  void initState() {
    super.initState();
    _getCurrentPosition();

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlayingAudio = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();

    if (_isRecording) {
      _audioRecorder.stop();
    }

    _descriptionController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();

    super.dispose();
  }

  // ============================================================
  // PHOTO : OUVERTURE DIRECTE DE LA CAMÉRA
  // ============================================================

  // ============================================================
  // PHOTO : OUVRIR DIRECTEMENT LA CAMÉRA EN MODE PHOTO
  // ============================================================

  Future<void> _prendrePhoto() async {
    if (_isSubmitting || _isTakingPhoto) return;

    setState(() => _isTakingPhoto = true);

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
      );

      if (!mounted) return;

      if (image != null) {
        setState(() {
          _photoFile = File(image.path);
        });
      }
    } catch (e) {
      debugPrint('Erreur photo : $e');

      if (mounted) {
        _showMessage(
          'Impossible d’ouvrir la caméra photo. Vérifiez les autorisations.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTakingPhoto = false);
      }
    }
  }

  // ============================================================
  // VIDÉO : OUVRIR DIRECTEMENT LA CAMÉRA, LIMITE DE 30 SECONDES
  // ============================================================

  // ============================================================
  // NOTE VOCALE : ENREGISTRER, ÉCOUTER, SUPPRIMER
  // ============================================================

  Future<void> _demarrerEnregistrementAudio() async {
    if (_isSubmitting || _isRecording) return;

    try {
      final autorise = await _audioRecorder.hasPermission();
      if (!mounted) return;

      if (!autorise) {
        _showMessage('Autorisez l’accès au microphone dans les paramètres.');
        return;
      }

      // Évite de remplacer une note existante sans confirmation.
      if (_audioPath != null) {
        final remplacer = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Nouvelle note vocale'),
            content: const Text(
              'Voulez-vous remplacer la note vocale actuelle ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remplacer'),
              ),
            ],
          ),
        );

        if (remplacer != true || !mounted) return;

        await _supprimerAudio();
      }

      final directory = await getTemporaryDirectory();
      final chemin =
          '${directory.path}/alert360_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: chemin,
      );

      if (!mounted) return;

      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });

      _recordingTimer?.cancel();

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || !_isRecording) return;

        if (_recordingDuration.inSeconds >= _maxAudioSeconds - 1) {
          _arreterEnregistrementAudio();
          return;
        }

        setState(() {
          _recordingDuration += const Duration(seconds: 1);
        });
      });
    } catch (e) {
      debugPrint('Erreur enregistrement audio : $e');
      if (mounted) {
        _showMessage('Impossible de démarrer l’enregistrement vocal.');
      }
    }
  }

  Future<void> _arreterEnregistrementAudio() async {
    if (!_isRecording) return;

    _recordingTimer?.cancel();
    _recordingTimer = null;

    try {
      final chemin = await _audioRecorder.stop();

      if (!mounted) return;

      setState(() {
        _isRecording = false;
        _audioPath = chemin;
      });

      if (chemin == null || !await File(chemin).exists()) {
        setState(() {
          _audioPath = null;
        });
        _showMessage('Aucun enregistrement audio n’a été créé.');
      }
    } catch (e) {
      debugPrint('Erreur arrêt audio : $e');

      if (mounted) {
        setState(() => _isRecording = false);
        _showMessage('Impossible d’arrêter l’enregistrement.');
      }
    }
  }

  Future<void> _ecouterAudio() async {
    if (_audioPath == null) return;

    try {
      await _audioPlayer.play(DeviceFileSource(_audioPath!));

      if (mounted) {
        setState(() => _isPlayingAudio = true);
      }
    } catch (e) {
      debugPrint('Erreur lecture audio : $e');

      if (mounted) {
        _showMessage('Impossible de lire la note vocale.');
      }
    }
  }

  Future<void> _arreterLectureAudio() async {
    await _audioPlayer.stop();

    if (mounted) {
      setState(() => _isPlayingAudio = false);
    }
  }

  Future<void> _supprimerAudio() async {
    await _audioPlayer.stop();

    final chemin = _audioPath;

    if (chemin != null) {
      try {
        final fichier = File(chemin);
        if (await fichier.exists()) {
          await fichier.delete();
        }
      } catch (e) {
        debugPrint('Erreur suppression audio : $e');
      }
    }

    if (!mounted) return;

    setState(() {
      _audioPath = null;
      _isPlayingAudio = false;
      _recordingDuration = Duration.zero;
    });
  }

  String _formaterDuree(Duration duree) {
    final minutes = duree.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secondes = duree.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$secondes';
  }

  // ============================================================
  // LOCALISATION GPS
  // ============================================================

  Future<void> _getCurrentPosition() async {
    if (!mounted) return;

    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception('Activez la localisation GPS de votre téléphone.');
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception('La permission de localisation a été refusée.');
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'La localisation est refusée définitivement. '
          'Autorisez-la dans les paramètres du téléphone.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 20),
        ),
      );

      if (!mounted) return;

      setState(() {
        _position = position;
        _isLoadingLocation = false;
        _locationError = null;
        _quartier = null;
        _adresse = null;
      });

      await _rechercherAdresse(position.latitude, position.longitude);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _position = null;
        _quartier = null;
        _adresse = null;
        _isLoadingLocation = false;
        _locationError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ============================================================
  // RECHERCHE D'ADRESSE
  // ============================================================

  Future<void> _rechercherAdresse(double latitude, double longitude) async {
    String? quartier;
    String? adresse;

    try {
      final geocoding = Geocoding(locale: const Locale('fr', 'FR'));

      final placemarks = await geocoding.placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        final lieu = placemarks.first;

        quartier = _premierTexteNonVide([
          lieu.subLocality,
          lieu.subAdministrativeArea,
          lieu.locality,
        ]);

        adresse = _premierTexteNonVide([lieu.street, lieu.name]);
      }
    } catch (e) {
      debugPrint('Géocodage natif indisponible : $e');
    }

    if (quartier == null || adresse == null) {
      try {
        final resultatOsm = await _rechercherAvecOpenStreetMap(
          latitude,
          longitude,
        );

        quartier ??= resultatOsm['quartier'];
        adresse ??= resultatOsm['adresse'];
      } catch (e) {
        debugPrint('Géocodage OpenStreetMap indisponible : $e');
      }
    }

    if (!mounted) return;

    setState(() {
      _quartier = quartier;
      _adresse = adresse;
    });
  }

  Future<Map<String, String?>> _rechercherAvecOpenStreetMap(
    double latitude,
    double longitude,
  ) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'format': 'jsonv2',
      'lat': latitude.toString(),
      'lon': longitude.toString(),
      'zoom': '14',
      'addressdetails': '1',
      'accept-language': 'fr',
    });

    final response = await http
        .get(uri, headers: {'User-Agent': 'Alert360Mobile/1.0'})
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      return {'quartier': null, 'adresse': null};
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final address = data['address'] as Map<String, dynamic>?;

    if (address == null) {
      return {'quartier': null, 'adresse': null};
    }

    final quartier = _premierTexteNonVide([
      address['neighbourhood'] as String?,
      address['quarter'] as String?,
      address['suburb'] as String?,
      address['city_district'] as String?,
      address['residential'] as String?,
      address['town'] as String?,
      address['village'] as String?,
      address['city'] as String?,
    ]);

    final adresse = _premierTexteNonVide([
      address['road'] as String?,
      address['pedestrian'] as String?,
      address['footway'] as String?,
      address['residential'] as String?,
    ]);

    return {'quartier': quartier, 'adresse': adresse};
  }

  String? _premierTexteNonVide(List<String?> valeurs) {
    for (final valeur in valeurs) {
      final texte = valeur?.trim();

      if (texte != null && texte.isNotEmpty && texte.toLowerCase() != 'null') {
        return texte;
      }
    }

    return null;
  }

  // ============================================================
  // ENVOI DU SIGNALEMENT
  // ============================================================

  Future<void> _submit() async {
    if (_isSubmitting) return;

    if (_isRecording) {
      _showMessage('Arrêtez l’enregistrement vocal avant de signaler.');
      return;
    }

    if (_position == null) {
      _showMessage(
        'La position GPS est nécessaire. '
        'Veuillez réessayer de la récupérer.',
      );
      return;
    }

    final description = _descriptionController.text.trim();

    final authState = ref.read(authControllerProvider);
    final auth = authState.asData?.value;

    if (auth == null || auth.idUtilisateur == null) {
      _showMessage(
        'Votre session est indisponible. Veuillez vous reconnecter.',
      );
      return;
    }

    if (auth.role?.toUpperCase() != 'CITOYEN') {
      _showMessage('Seul un compte citoyen peut créer un signalement.');
      return;
    }

    if (auth.estActif != true) {
      _showMessage('Votre compte est inactif.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final signalementService = SignalementService();

      String? photoAvantUrl;
      String? audioUrl;

      // 1. Téléverser la photo.
      if (_photoFile != null) {
        _showMessage('Téléversement de la photo...');

        photoAvantUrl = await signalementService.televerserMedia(
          fichier: _photoFile!,
          endpoint: '/api/medias/photo',
        );
      }

      // 2. Téléverser la note vocale.
      if (_audioPath != null) {
        final audioFile = File(_audioPath!);

        if (!await audioFile.exists()) {
          throw Exception('Le fichier de la note vocale est introuvable.');
        }

        _showMessage('Téléversement de la note vocale...');

        audioUrl = await signalementService.televerserMedia(
          fichier: audioFile,
          endpoint: '/api/medias/audio',
        );
      }

      // 3. Préparer la requête.
      final request = SignalementRequest(
        typeUrgence: _selectedUrgence,
        description: description.isEmpty
            ? 'Aucune description fournie'
            : description,
        latitudeGPS: _position!.latitude,
        longitudeGPS: _position!.longitude,
        citoyenId: auth.idUtilisateur!,
        categorieId: widget.categoryId,
        photoAvantUrl: photoAvantUrl,
        audioUrl: audioUrl,
      );

      // 4. Envoyer le signalement et récupérer la réponse du backend.
      _showMessage('Envoi du signalement...');

      final signalement = await ref
          .read(signalementRepositoryProvider)
          .creerSignalement(request);

      if (!mounted) return;

      // 5. Construire une localisation lisible.
      final localisation = [_adresse, _quartier]
          .whereType<String>()
          .map((element) => element.trim())
          .where((element) => element.isNotEmpty)
          .toSet()
          .join(', ');

      final localisationFinale = localisation.isNotEmpty
          ? localisation
          : '${_position!.latitude.toStringAsFixed(5)}, '
                '${_position!.longitude.toStringAsFixed(5)}';

      // 6. Préparer la référence réelle du signalement.
      final reference =
          signalement.codeTrackingUnique?.trim().isNotEmpty == true
          ? signalement.codeTrackingUnique!
          : 'ALT-${signalement.idSignalement}';

      // 7. Ouvrir directement l'écran de confirmation.
      // L'ancien écran est remplacé pour éviter de revenir
      // au formulaire et de soumettre accidentellement deux fois.
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (confirmationContext) => SignalementConfirmationScreen(
            reference: reference,
            categoryName: signalement.categorieNom ?? widget.categoryTitle,
            locationName: localisationFinale,
            structureName: signalement.structureAssigneeNom,
            status: signalement.statut,

            onBack: () {
              Navigator.of(confirmationContext).maybePop();
            },

            onTrackSignalement: () {
              Navigator.of(confirmationContext).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MesSignalementsScreen(),
                ),
              );
            },
          ),
        ),
      );

      // Le callback n'est conservé que si ton écran parent
      // en a encore besoin. Il n'est pas appelé automatiquement
      // ici afin d'éviter une seconde navigation concurrente.
    } catch (e, stackTrace) {
      debugPrint('Erreur lors du signalement : $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      _showMessage(
        'Échec de l’envoi du signalement : '
        '${e.toString().replaceFirst('Exception: ', '')}',
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // ============================================================
  // APERÇU DES MÉDIAS ET ACTIONS
  // ============================================================

  Widget _construireApercuPhoto() {
    if (_photoFile == null) return const SizedBox.shrink();

    return _apercuMedia(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          _photoFile!,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
      titre: 'Photo capturée',
      onDelete: _supprimerPhoto,
    );
  }

  Widget _construireApercuAudio() {
    if (_audioPath == null && !_isRecording) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isRecording ? Colors.red.shade200 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isRecording ? Icons.fiber_manual_record : Icons.mic_rounded,
            color: _isRecording ? Colors.red : AppColors.primaryBlue,
            size: 26,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isRecording
                      ? 'Enregistrement en cours...'
                      : 'Note vocale prête',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkBlue,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formaterDuree(_recordingDuration),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: _isRecording ? Colors.red : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (_isRecording)
            IconButton(
              tooltip: 'Arrêter',
              onPressed: _arreterEnregistrementAudio,
              icon: const Icon(Icons.stop_circle_rounded, color: Colors.red),
            )
          else ...[
            IconButton(
              tooltip: _isPlayingAudio ? 'Arrêter la lecture' : 'Écouter',
              onPressed: _isPlayingAudio ? _arreterLectureAudio : _ecouterAudio,
              icon: Icon(
                _isPlayingAudio ? Icons.stop_rounded : Icons.play_arrow_rounded,
                color: AppColors.primaryBlue,
              ),
            ),
            IconButton(
              tooltip: 'Supprimer la note vocale',
              onPressed: _isSubmitting ? null : _supprimerAudio,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
            ),
          ],
        ],
      ),
    );
  }

  Widget _apercuMedia({
    required Widget child,
    required String titre,
    required VoidCallback onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  titre,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkBlue,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Supprimer',
                onPressed: _isSubmitting ? null : onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          child,
        ],
      ),
    );
  }

  // ============================================================
  // INTERFACE UTILISATEUR : DESIGN CONSERVÉ
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  InkWell(
                    onTap: widget.onBack ?? () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      height: 40,
                      width: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.darkBlue,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Détails du problème',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkBlue,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Étape 2 sur 2 — Photo, localisation & description',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.circle,
                          color: Color(0xFF3B82F6),
                          size: 8,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.categoryTitle,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "1. Preuve photo de l'incident *",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkBlue,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: _MediaPickerBox(
                            assetPath: 'assets/images/icons/camera_icon.png',
                            label: _photoFile == null
                                ? 'Prendre une photo'
                                : 'Reprendre la photo',
                            isLoading: _isTakingPhoto,
                            onTap: _prendrePhoto,
                          ),
                        ),
                      ],
                    ),

                    _construireApercuPhoto(),

                    const SizedBox(height: 20),

                    const Text(
                      '2. Emplacement géolocalisé *',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkBlue,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 60,
                              width: 60,
                              color: const Color(0xFFDBEAFE),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Positioned(
                                    top: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 6,
                                      color: const Color(0xFF60A5FA),
                                    ),
                                  ),
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      height: 6,
                                      color: const Color(0xFFFBBF24),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.location_pin,
                                    color: Color(0xFFDC2626),
                                    size: 28,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isLoadingLocation
                                      ? 'Recherche de la position...'
                                      : (_adresse ?? 'Position actuelle'),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkBlue,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isLoadingLocation
                                      ? 'Détection du quartier...'
                                      : _position == null
                                      ? 'Adresse indisponible'
                                      : (_quartier ?? 'Quartier non identifié'),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isLoadingLocation
                                      ? 'Récupération des coordonnées GPS...'
                                      : _position != null
                                      ? '${_position!.latitude.toStringAsFixed(5)}, ${_position!.longitude.toStringAsFixed(5)}'
                                      : (_locationError ??
                                            'Position GPS indisponible'),
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _position != null
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_isLoadingLocation)
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            )
                          else
                            IconButton(
                              tooltip: 'Actualiser la position',
                              onPressed: _isSubmitting
                                  ? null
                                  : _getCurrentPosition,
                              icon: const Icon(
                                Icons.refresh_rounded,
                                color: AppColors.primaryBlue,
                                size: 22,
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "3. Niveau d'urgence *",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkBlue,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      height: 54,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedUrgence,
                          isExpanded: true,
                          borderRadius: BorderRadius.circular(12),
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.primaryBlue,
                            size: 24,
                          ),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.darkBlue,
                          ),
                          items: _niveauxUrgence.map((niveau) {
                            return DropdownMenuItem<String>(
                              value: niveau,
                              child: Row(
                                children: [
                                  Container(
                                    width: 9,
                                    height: 9,
                                    decoration: BoxDecoration(
                                      color: _couleurUrgence(niveau),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(_libelleUrgence(niveau)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: _isSubmitting
                              ? null
                              : (nouveauNiveau) {
                                  if (nouveauNiveau == null) return;
                                  setState(
                                    () => _selectedUrgence = nouveauNiveau,
                                  );
                                },
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      '4. Description ou note vocale (Optionnel)',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkBlue,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      height: 110,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _descriptionController,
                        maxLines: 4,
                        enabled: !_isSubmitting,
                        textInputAction: TextInputAction.newline,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13.5,
                          color: AppColors.darkBlue,
                        ),
                        decoration: const InputDecoration(
                          hintText: "Précisez des détails utiles pour l'agent de terrain...",
                          hintStyle: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.5,
                            color: Color(0xFF94A3B8),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      '5. Audio (Max 30s)',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkBlue,
                      ),
                    ),

                    const SizedBox(height: 10),

                    InkWell(
                      onTap: _isSubmitting
                          ? null
                          : (_isRecording
                                ? _arreterEnregistrementAudio
                                : _demarrerEnregistrementAudio),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 60),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _isRecording
                                ? Colors.red.shade300
                                : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isRecording
                                  ? Icons.stop_circle_rounded
                                  : Icons.mic_none_rounded,
                              color: _isRecording
                                  ? Colors.red
                                  : const Color(0xFF64748B),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _isRecording
                                        ? 'Appuyer pour arrêter l’enregistrement'
                                        : _audioPath != null
                                        ? 'Note vocale enregistrée'
                                        : 'Appuyer pour enregistrer un vocal',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12.5,
                                      color: _isRecording
                                          ? Colors.red
                                          : const Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (_isRecording) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      '${_formaterDuree(_recordingDuration)} / 00:30',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value:
                                            _recordingDuration.inSeconds / 30,
                                        minHeight: 3,
                                        backgroundColor: Colors.red.shade100,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    _construireApercuAudio(),
                  ],
                ),
              ),
            ),

            // BOUTON FIXE EN BAS
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B5998),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF94A3B8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'SIGNALER',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
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
}

// ============================================================
// CARTE DE CAPTURE PHOTO / VIDÉO
// ============================================================

class _MediaPickerBox extends StatelessWidget {
  final String assetPath;
  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  const _MediaPickerBox({
    required this.assetPath,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryBlue,
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      assetPath,
                      width: 42,
                      height: 42,
                      fit: BoxFit.contain,
                      color: const Color(0xFF64748B),
                      colorBlendMode: BlendMode.srcIn,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkBlue,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

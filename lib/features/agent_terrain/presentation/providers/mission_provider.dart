import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../auth/data/models/utilisateur.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/mission.dart';
import '../../data/models/preuve_resolution.dart';
import '../../data/models/preuve_resolution_request.dart';
import '../../data/repositories/mission_repository.dart';
import '../../data/services/itineraire_service.dart';

/// Fournit le repository des missions.
final missionRepositoryProvider = Provider<MissionRepository>((ref) {
  return MissionRepository();
});

final itineraireServiceProvider = Provider<ItineraireService>((ref) {
  return ItineraireService();
});

/// Profil complet de l'agent connecté (structure, matricule...).
final profilAgentProvider = FutureProvider.autoDispose<Utilisateur>((
  ref,
) async {
  final json = await ref.watch(utilisateurServiceProvider).getMonProfil();
  return Utilisateur.fromJson(json);
});

/// Missions assignées à l'agent connecté, les plus urgentes en premier.
final missionsAgentProvider = FutureProvider.autoDispose<List<Mission>>((
  ref,
) async {
  final idAgent = ref.watch(authControllerProvider).asData?.value?.idUtilisateur;

  if (idAgent == null) {
    throw Exception('Aucun agent connecté.');
  }

  final missions = await ref
      .watch(missionRepositoryProvider)
      .getMissionsByAgent(idAgent);

  return [...missions]..sort((a, b) {
    if (a.estTerminee != b.estTerminee) return a.estTerminee ? 1 : -1;

    final urgence = a.rangUrgence.compareTo(b.rangUrgence);
    if (urgence != 0) return urgence;

    final dateA = a.signalement.dateHeureAlerte;
    final dateB = b.signalement.dateHeureAlerte;
    if (dateA == null || dateB == null) return 0;

    return dateA.compareTo(dateB);
  });
});

/// Détail d'une mission.
final missionDetailProvider = FutureProvider.autoDispose.family<Mission, int>((
  ref,
  idSignalement,
) {
  return ref.watch(missionRepositoryProvider).getMissionById(idSignalement);
});

/// Position actuelle de l'agent, ou null si la localisation est refusée.
final positionAgentProvider = FutureProvider.autoDispose<Position?>((
  ref,
) async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
  } catch (_) {
    return null;
  }
});

/// Distance en mètres entre l'agent et une mission.
double? distanceVersMission(Position? position, Mission mission) {
  final latitude = mission.signalement.latitudeGPS;
  final longitude = mission.signalement.longitudeGPS;

  if (position == null || latitude == null || longitude == null) return null;

  return Geolocator.distanceBetween(
    position.latitude,
    position.longitude,
    latitude,
    longitude,
  );
}

/// Gère l'envoi du rapport d'intervention.
class RapportInterventionNotifier extends AsyncNotifier<PreuveResolution?> {
  @override
  Future<PreuveResolution?> build() async => null;

  Future<PreuveResolution> envoyerRapport({
    required Mission mission,
    required StatutPropose statut,
    required String rapport,
    File? photo,
  }) async {
    state = const AsyncLoading();

    try {
      final repository = ref.read(missionRepositoryProvider);

      // 1. Téléverser la nouvelle photo, sinon conserver l'ancienne.
      final photoUrl = photo != null
          ? await repository.televerserPhoto(photo)
          : mission.preuve?.photoApresUrl;

      // 2. Envoyer le rapport au responsable.
      final preuve = await repository.enregistrerPreuve(
        idPreuveExistante: mission.preuve?.idPreuve,
        request: PreuveResolutionRequest(
          idSignalement: mission.id,
          typePreuve: photoUrl != null && photoUrl.isNotEmpty
              ? 'PHOTO_APRES'
              : 'RAPPORT_AGENT',
          photoApresUrl: photoUrl,
          rapportTexte: PreuveResolution.composerRapport(statut, rapport),
        ),
      );

      // 3. Actualiser les écrans des missions.
      ref.invalidate(missionsAgentProvider);
      ref.invalidate(missionDetailProvider(mission.id));

      state = AsyncData(preuve);

      return preuve;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

/// Provider d'envoi du rapport d'intervention.
final rapportInterventionProvider =
    AsyncNotifierProvider<RapportInterventionNotifier, PreuveResolution?>(
      RapportInterventionNotifier.new,
    );

import 'dart:io';

import '../../../../core/errors/api_exception.dart';
import '../../../signalements/data/models/signalement.dart';
import '../models/mission.dart';
import '../models/preuve_resolution.dart';
import '../models/preuve_resolution_request.dart';
import '../services/mission_service.dart';

class MissionRepository {
  final MissionService _missionService;

  MissionRepository({MissionService? missionService})
    : _missionService = missionService ?? MissionService();

  /// Récupérer les missions de l'agent avec leurs preuves.
  Future<List<Mission>> getMissionsByAgent(int idAgent) async {
    try {
      final response = await _missionService.getMissionsByAgent(idAgent);

      if (response is! List) {
        throw ApiException(
          message: 'Format de réponse invalide pour les missions.',
        );
      }

      final signalements = response
          .map(
            (item) =>
                Signalement.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();

      final preuves = await _getMesPreuves();

      final preuvesParSignalement = {
        for (final preuve in preuves)
          if (preuve.idSignalement != null) preuve.idSignalement!: preuve,
      };

      return signalements
          .map(
            (signalement) => Mission(
              signalement: signalement,
              preuve: preuvesParSignalement[signalement.idSignalement],
            ),
          )
          .toList();
    } catch (error) {
      if (error is ApiException) rethrow;

      throw ApiException(message: 'Impossible de récupérer vos missions.');
    }
  }

  /// Récupérer le détail d'une mission.
  Future<Mission> getMissionById(int idSignalement) async {
    try {
      final response = await _missionService.getMissionById(idSignalement);

      if (response is! Map) {
        throw ApiException(
          message: 'Format de réponse invalide pour la mission.',
        );
      }

      return Mission(
        signalement: Signalement.fromJson(Map<String, dynamic>.from(response)),
        preuve: await getPreuveBySignalement(idSignalement),
      );
    } catch (error) {
      if (error is ApiException) rethrow;

      throw ApiException(
        message: 'Impossible de récupérer le détail de la mission.',
      );
    }
  }

  /// Récupérer la preuve d'une mission, ou null si aucune n'existe.
  Future<PreuveResolution?> getPreuveBySignalement(int idSignalement) async {
    try {
      final response = await _missionService.getPreuveBySignalement(
        idSignalement,
      );

      if (response is! Map) return null;

      return PreuveResolution.fromJson(Map<String, dynamic>.from(response));
    } on ApiException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Ajouter ou modifier le rapport d'intervention.
  Future<PreuveResolution> enregistrerPreuve({
    required PreuveResolutionRequest request,
    int? idPreuveExistante,
  }) async {
    try {
      final response = idPreuveExistante == null
          ? await _missionService.ajouterPreuve(request.toJson())
          : await _missionService.modifierPreuve(
              idPreuveExistante,
              request.toJson(),
            );

      if (response is! Map) {
        throw ApiException(
          message: 'Format de réponse invalide après l’envoi du rapport.',
        );
      }

      return PreuveResolution.fromJson(Map<String, dynamic>.from(response));
    } catch (error) {
      if (error is ApiException) rethrow;

      throw ApiException(message: 'Impossible d’envoyer le rapport.');
    }
  }

  Future<String> televerserPhoto(File photo) {
    return _missionService.televerserPhoto(photo);
  }

  Future<List<PreuveResolution>> _getMesPreuves() async {
    try {
      final response = await _missionService.getMesPreuves();

      if (response is! List) return const [];

      return response
          .map(
            (item) => PreuveResolution.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } on ApiException {
      // Les missions restent consultables même sans les preuves.
      return const [];
    }
  }
}

import 'dart:io';

import '../../../../core/network/api_service.dart';
import '../../../signalements/data/services/signalement_service.dart';

class MissionService {
  final SignalementService _signalementService;

  MissionService({SignalementService? signalementService})
    : _signalementService = signalementService ?? SignalementService();

  /// Signalements assignés à l'agent de terrain.
  Future<dynamic> getMissionsByAgent(int idAgent) {
    return ApiService.get('/api/signalements/agent/$idAgent');
  }

  Future<dynamic> getMissionById(int idSignalement) {
    return ApiService.get('/api/signalements/$idSignalement');
  }

  /// Le backend renvoie uniquement les preuves des missions de l'agent.
  Future<dynamic> getMesPreuves() {
    return ApiService.get('/api/preuves');
  }

  Future<dynamic> getPreuveBySignalement(int idSignalement) {
    return ApiService.get('/api/preuves/signalement/$idSignalement');
  }

  Future<dynamic> ajouterPreuve(Map<String, dynamic> data) {
    return ApiService.post('/api/preuves', data: data);
  }

  Future<dynamic> modifierPreuve(int idPreuve, Map<String, dynamic> data) {
    return ApiService.put('/api/preuves/$idPreuve', data: data);
  }

  /// Téléverse la photo prise après l'intervention.
  Future<String> televerserPhoto(File photo) {
    return _signalementService.televerserMedia(
      fichier: photo,
      endpoint: '/api/medias/photo',
    );
  }
}

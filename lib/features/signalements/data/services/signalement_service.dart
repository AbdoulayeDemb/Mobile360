import '../../../../core/network/api_service.dart';

class SignalementService {
  /// Créer un nouveau signalement

  /// Créer un nouveau signalement
  Future<dynamic> creerSignalement(Map<String, dynamic> data) {
    return ApiService.post('/api/signalements', data: data);
  }

  /// Récupérer les signalements d'un citoyen
  Future<dynamic> getSignalementsByCitoyen(int idCitoyen) {
    return ApiService.get('/api/signalements/citoyen/$idCitoyen');
  }

  /// Récupérer le détail d'un signalement
  Future<dynamic> getSignalementById(int idSignalement) {
    return ApiService.get('/api/signalements/$idSignalement');
  }
}

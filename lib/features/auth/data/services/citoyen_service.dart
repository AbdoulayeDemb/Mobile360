import '../../../../core/network/api_service.dart';

class CitoyenService {
  Future<Map<String, dynamic>> getCitoyenById(int idUtilisateur) async {
    final response = await ApiService.get('/api/citoyens/$idUtilisateur');

    if (response is Map) {
      final json = Map<String, dynamic>.from(response);
      final data = json['data'];

      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      if (json.containsKey('idUtilisateur')) {
        return json;
      }
    }

    throw Exception('Impossible de récupérer les informations du citoyen.');
  }

  Future<Map<String, dynamic>> modifierProfilCitoyen({
    required int idUtilisateur,
    required Map<String, dynamic> donnees,
  }) async {
    final response = await ApiService.put(
      '/api/citoyens/$idUtilisateur',
      data: donnees,
    );

    if (response is Map) {
      final json = Map<String, dynamic>.from(response);
      final data = json['data'];

      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      if (json.containsKey('idUtilisateur')) {
        return json;
      }
    }

    throw Exception('Impossible de récupérer le profil modifié.');
  }
}

import '../../../../core/network/api_service.dart';

class UtilisateurService {
  /// Récupère le profil d'un utilisateur par son identifiant.
  Future<Map<String, dynamic>> getUtilisateurById(int idUtilisateur) async {
    final response = await ApiService.get('/api/utilisateurs/$idUtilisateur');

    if (response is Map<String, dynamic>) {
      // Réponse contenant directement le profil.
      return response;
    }

    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }

    throw Exception(
      'Format de réponse inattendu lors de la récupération du profil.',
    );
  }

  Future<Map<String, dynamic>> getMonProfil() async {
    final response = await ApiService.get('/api/utilisateurs/me');

    if (response is Map<String, dynamic>) {
      return response;
    }

    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }

    throw Exception(
      'Format de réponse inattendu lors de la récupération du profil.',
    );
  }
}

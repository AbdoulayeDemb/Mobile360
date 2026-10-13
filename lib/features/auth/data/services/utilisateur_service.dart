import '../../../../core/network/api_service.dart';

class UtilisateurService {
  /// Récupère le profil d'un utilisateur par son identifiant.
  Future<dynamic> getUtilisateurById(int idUtilisateur) {
    return ApiService.get('/api/utilisateurs/$idUtilisateur');
  }
}

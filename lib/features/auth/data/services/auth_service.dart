import '../../../../core/storage/secure_storage_service.dart';
import '../models/auth_response.dart';

class AuthService {
  /// Enregistre les informations nécessaires à la session.
  Future<void> saveSession(AuthResponse auth) async {
    await SecureStorageService.saveToken(auth.token);

    if (auth.idUtilisateur != null) {
      await SecureStorageService.saveUserId(auth.idUtilisateur!);
    }
  }

  /// Récupère l'identifiant de l'utilisateur connecté.
  Future<int?> getCurrentUserId() async {
    return SecureStorageService.getUserId();
  }

  /// Vérifie si un token de session existe.
  Future<bool> hasSession() async {
    return SecureStorageService.hasToken();
  }

  /// Supprime les données de session.
  Future<void> clearSession() async {
    await SecureStorageService.deleteUserId();
    await SecureStorageService.deleteToken();
  }
}

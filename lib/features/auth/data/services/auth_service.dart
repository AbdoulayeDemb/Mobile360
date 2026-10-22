import '../../../../core/storage/secure_storage_service.dart';

import 'package:flutter/foundation.dart';

import '../models/auth_response.dart';

class AuthService {
  /// Enregistre les informations nécessaires à la session.
  Future<void> saveSession(AuthResponse auth) async {
    final idUtilisateur = auth.idUtilisateur;

    // Ne pas ouvrir une session sans identifiant utilisateur valide.
    if (idUtilisateur == null || idUtilisateur <= 0) {
      throw StateError(
        'Impossible d’enregistrer la session : '
        'idUtilisateur est absent ou invalide dans la réponse du serveur.',
      );
    }

    // Supprime les informations de l'ancienne session.
    await clearSession();

    // Enregistre la nouvelle session.
    await SecureStorageService.saveUserId(idUtilisateur);
    await SecureStorageService.saveToken(auth.token);

    final tokenEnregistre = await SecureStorageService.getToken();
    final idEnregistre = await SecureStorageService.getUserId();

    debugPrint('TOKEN ENREGISTRÉ : ${tokenEnregistre != null}');
    debugPrint('ID UTILISATEUR ENREGISTRÉ : $idEnregistre');
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

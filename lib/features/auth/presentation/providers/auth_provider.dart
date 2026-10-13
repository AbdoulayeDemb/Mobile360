import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/secure_storage_service.dart';
import '../../data/models/auth_response.dart';
import '../../data/models/utilisateur.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/utilisateur_service.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final utilisateurServiceProvider = Provider<UtilisateurService>((ref) {
  return UtilisateurService();
});

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthResponse?>(AuthController.new);

class AuthController extends AsyncNotifier<AuthResponse?> {
  @override
  Future<AuthResponse?> build() async {
    final authService = ref.read(authServiceProvider);

    // Aucune session enregistrée.
    if (!await authService.hasSession()) {
      return null;
    }

    final userId = await authService.getCurrentUserId();

    // Impossible de restaurer le profil sans identifiant.
    if (userId == null) {
      return null;
    }

    try {
      final response = await ref
          .read(utilisateurServiceProvider)
          .getUtilisateurById(userId);

      if (response is! Map) {
        return null;
      }

      final utilisateur = Utilisateur.fromJson(
        Map<String, dynamic>.from(response),
      );

      // Reconstruire la session à partir du profil récupéré.
      final token = await SecureStorageService.getToken();

      if (token == null || token.isEmpty) {
        return null;
      }

      final auth = AuthResponse(
        token: token,
        type: 'Bearer',
        idUtilisateur: utilisateur.idUtilisateur,
        nom: utilisateur.nom,
        prenom: utilisateur.prenom,
        telephone: utilisateur.telephone,
        email: utilisateur.email,
        role: utilisateur.role,
        quartier: utilisateur.quartier,
        estActif: utilisateur.estActif,
        idStructure: utilisateur.idStructure,
        estResponsable: utilisateur.estResponsable,
      );

      // Vérifier que le profil peut utiliser l'application mobile.
      if (!_isAuthorizedForMobile(auth)) {
        await _clearSessionSafely();
        return null;
      }

      return auth;
    } catch (_) {
      // Une erreur réseau ne signifie pas nécessairement que
      // le token est invalide : ne pas supprimer la session ici.
      return null;
    }
  }

  /// Vérifie si le profil est autorisé à utiliser l'application mobile.
  bool _isAuthorizedForMobile(AuthResponse auth) {
    if (auth.estActif != true) {
      return false;
    }

    final role = auth.role?.toUpperCase();

    if (role == 'CITOYEN') {
      return true;
    }

    if (role == 'STRUCTURE' && auth.estResponsable == false) {
      return true;
    }

    return false;
  }

  /// Supprime la session enregistrée sans masquer l'erreur initiale.
  Future<void> _clearSessionSafely() async {
    try {
      await ref.read(authRepositoryProvider).logout();
    } catch (_) {
      // Si le nettoyage échoue, ne pas faire planter l'application.
    }
  }

  /// Connexion d'un citoyen ou d'un agent de terrain.
  Future<void> login({
    required String telephone,
    required String motDePasse,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final auth = await ref
          .read(authRepositoryProvider)
          .login(telephone: telephone, motDePasse: motDePasse);

      // Défense supplémentaire côté Flutter.
      // Le backend doit également appliquer cette restriction.
      if (!_isAuthorizedForMobile(auth)) {
        await _clearSessionSafely();

        throw Exception(
          "Accès refusé : ce profil n'est pas autorisé "
          "à utiliser l'application mobile Alert'360.",
        );
      }

      return auth;
    });
  }

  /// Déconnexion et suppression de la session locale.
  Future<void> logout() async {
    try {
      await ref.read(authRepositoryProvider).logout();
    } finally {
      state = const AsyncData(null);
    }
  }
}

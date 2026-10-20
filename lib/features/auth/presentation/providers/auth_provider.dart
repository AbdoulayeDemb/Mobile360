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
    final token = await SecureStorageService.getToken();

    // Une session incomplète ne peut pas être restaurée.
    if (userId == null || token == null || token.trim().isEmpty) {
      await _clearSessionSafely();
      return null;
    }

    try {
      final response = await ref
          .read(utilisateurServiceProvider)
          .getUtilisateurById(userId);

      if (response is! Map) {
        // La réponse est invalide : ne pas considérer la session restaurée.
        return null;
      }

      final utilisateur = Utilisateur.fromJson(
        Map<String, dynamic>.from(response),
      );

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

      if (!_isAuthorizedForMobile(auth)) {
        await _clearSessionSafely();
        return null;
      }

      return auth;
    } catch (_) {
      // Une erreur réseau temporaire ne doit pas effacer le token.
      // L'état reste toutefois non authentifié dans cette version.
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

  /// Supprime la session locale sans propager les erreurs de nettoyage.
  Future<void> _clearSessionSafely() async {
    try {
      await ref.read(authRepositoryProvider).logout();
    } catch (_) {
      // Le nettoyage ne doit pas faire planter le contrôleur.
    }
  }

  /// Connexion d'un citoyen ou d'un agent de terrain autorisé.
  Future<void> login({
    required String telephone,
    required String motDePasse,
  }) async {
    state = const AsyncLoading();

    try {
      final auth = await ref
          .read(authRepositoryProvider)
          .login(telephone: telephone, motDePasse: motDePasse);

      // Le repository enregistre déjà la session.
      if (!_isAuthorizedForMobile(auth)) {
        await _clearSessionSafely();

        state = AsyncData(null);

        throw Exception(
          "Accès refusé : ce profil n'est pas autorisé "
          "à utiliser l'application mobile Alert'360.",
        );
      }

      // Publier immédiatement la session authentifiée.
      state = AsyncData(auth);
    } catch (error, stackTrace) {
      // Ne pas laisser l'état bloqué en chargement.
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  /// Déconnexion et suppression de la session locale.
  Future<void> logout() async {
    try {
      await ref.read(authRepositoryProvider).logout();
    } finally {
      // Le routeur peut observer cet état et rediriger vers /login.
      state = const AsyncData(null);
    }
  }
}

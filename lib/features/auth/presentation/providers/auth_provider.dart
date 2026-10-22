import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/secure_storage_service.dart';
import '../../data/models/auth_response.dart';
import '../../data/models/utilisateur.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/utilisateur_service.dart';
import '../../data/models/citoyen_request.dart';

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
    debugPrint('=== RESTAURATION SESSION : DÉBUT ===');

    try {
      final authService = ref.read(authServiceProvider);

      // Vérifier si une session existe localement.
      final hasSession = await authService.hasSession();

      debugPrint('SESSION : TOKEN PRÉSENT = $hasSession');

      if (!hasSession) {
        debugPrint('SESSION : AUCUNE SESSION ENREGISTRÉE');
        return null;
      }

      // Récupérer l'identifiant et le token enregistrés.
      final userId = await authService.getCurrentUserId();
      final token = await SecureStorageService.getToken();

      debugPrint('SESSION : ID = $userId');
      debugPrint(
        'SESSION : TOKEN PRÉSENT = '
        '${token != null && token.trim().isNotEmpty}',
      );

      // Vérifier les données locales.
      if (userId == null ||
          userId <= 0 ||
          token == null ||
          token.trim().isEmpty) {
        debugPrint('SESSION : DONNÉES LOCALES INCOMPLÈTES');
        await _clearSessionSafely();
        return null;
      }

      debugPrint('SESSION : RÉCUPÉRATION DU PROFIL...');

      // IMPORTANT :
      // Le backend identifie l'utilisateur depuis son token JWT.
      // On ne demande plus /api/utilisateurs/{id}.
      final response = await ref
          .read(utilisateurServiceProvider)
          .getMonProfil();

      debugPrint('SESSION : RÉPONSE DU PROFIL REÇUE');

      final Map<String, dynamic> json;

      if (response is Map<String, dynamic>) {
        json = response;
      } else if (response is Map) {
        json = Map<String, dynamic>.from(response);
      } else {
        debugPrint('SESSION : FORMAT DE PROFIL INVALIDE');
        return null;
      }

      final utilisateur = Utilisateur.fromJson(json);

      debugPrint('SESSION : PROFIL PARSÉ');
      debugPrint('SESSION : RÔLE = ${utilisateur.role}');
      debugPrint('SESSION : COMPTE ACTIF = ${utilisateur.estActif}');

      // Reconstruire l'objet d'authentification.
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

      // Vérifier que le compte est autorisé sur mobile.
      if (!_isAuthorizedForMobile(auth)) {
        debugPrint('SESSION : COMPTE INACTIF OU RÔLE NON AUTORISÉ');
        await _clearSessionSafely();
        return null;
      }

      debugPrint('=== RESTAURATION SESSION : SUCCÈS ===');

      return auth;
    } catch (error, stackTrace) {
      // Ne pas supprimer les identifiants locaux sur une erreur
      // temporaire ou une erreur serveur.
      debugPrint('=== ERREUR RESTAURATION SESSION ===');
      debugPrint('TYPE : ${error.runtimeType}');
      debugPrint('DÉTAIL : $error');
      debugPrintStack(stackTrace: stackTrace);

      return null;
    }
  }

  /// Vérifie si le profil peut utiliser l'application mobile.
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

  /// Nettoie la session lorsque cela est nécessaire.
  Future<void> _clearSessionSafely() async {
    try {
      await ref.read(authRepositoryProvider).logout();
    } catch (error) {
      debugPrint('ERREUR NETTOYAGE SESSION : $error');
    }
  }

  /// Connexion.
  Future<void> login({
    required String telephone,
    required String motDePasse,
  }) async {
    state = const AsyncLoading();

    try {
      final auth = await ref
          .read(authRepositoryProvider)
          .login(telephone: telephone, motDePasse: motDePasse);

      if (!_isAuthorizedForMobile(auth)) {
        await _clearSessionSafely();
        state = const AsyncData(null);

        throw Exception(
          "Accès refusé : ce profil n'est pas autorisé "
          "à utiliser l'application mobile Alert'360.",
        );
      }

      state = AsyncData(auth);

      debugPrint('CONNEXION : SESSION ENREGISTRÉE ET ACTIVE');
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  /// Inscription et connexion automatique.
  Future<void> register({required CitoyenRequest request}) async {
    state = const AsyncLoading();

    try {
      final auth = await ref
          .read(authRepositoryProvider)
          .register(request: request);

      if (!_isAuthorizedForMobile(auth)) {
        await _clearSessionSafely();
        state = const AsyncData(null);

        throw Exception(
          "Ce profil n'est pas autorisé à utiliser "
          "l'application mobile Alert'360.",
        );
      }

      state = AsyncData(auth);

      debugPrint('INSCRIPTION : SESSION ENREGISTRÉE ET ACTIVE');
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  /// Déconnexion volontaire.
  Future<void> logout() async {
    try {
      await ref.read(authRepositoryProvider).logout();
    } finally {
      state = const AsyncData(null);
    }
  }
}

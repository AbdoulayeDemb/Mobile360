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

    // Aucun token : aucune session à restaurer.
    if (!await authService.hasSession()) {
      return null;
    }

    final userId = await authService.getCurrentUserId();

    // Sans identifiant, nous ne pouvons pas récupérer le profil.
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

      // Reconstruire AuthResponse avec le profil restauré.
      return AuthResponse(
        token: (await SecureStorageService.getToken())!,
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
    } catch (_) {
      // Le token peut être expiré ou le serveur indisponible.
      // On ne supprime pas automatiquement la session.
      return null;
    }
  }

  Future<void> login({
    required String telephone,
    required String motDePasse,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      return ref
          .read(authRepositoryProvider)
          .login(telephone: telephone, motDePasse: motDePasse);
    });
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }
}

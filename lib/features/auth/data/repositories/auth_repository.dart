import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_service.dart';
import '../../../../shared/models/api_response.dart';
import '../models/auth_response.dart';
import '../models/citoyen_request.dart';
import '../services/auth_service.dart';

class AuthRepository {
  final AuthService _authService;

  AuthRepository({AuthService? authService})
    : _authService = authService ?? AuthService();

  Future<AuthResponse> login({
    required String telephone,
    required String motDePasse,
  }) async {
    final response = await ApiService.post(
      '/api/auth/login',
      data: {'telephone': telephone, 'motDePasse': motDePasse},
    );

    if (response is! Map<String, dynamic>) {
      throw const FormatException('Format de réponse du serveur invalide.');
    }

    final apiResponse = ApiResponse<AuthResponse>.fromJson(
      response,
      dataParser: (json) {
        if (json is! Map<String, dynamic>) {
          throw const FormatException('Données utilisateur invalides.');
        }

        return AuthResponse.fromJson(json);
      },
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw ApiException(
        message: apiResponse.message ?? 'Connexion impossible.',
      );
    }

    final auth = apiResponse.data!;

    // La session est enregistrée uniquement après la connexion.
    await _authService.saveSession(auth);

    return auth;
  }

  /// Inscription d'un nouveau citoyen.
  ///
  /// Cette méthode ne sauvegarde pas de session, car le backend
  /// actuel ne renvoie pas de token JWT lors de l'inscription.
  Future<AuthResponse> register({required CitoyenRequest request}) async {
    final response = await ApiService.post(
      '/api/auth/register/citoyen',
      data: request.toJson(),
    );

    if (response is! Map<String, dynamic>) {
      throw const FormatException('Format de réponse du serveur invalide.');
    }

    final apiResponse = ApiResponse<AuthResponse>.fromJson(
      response,
      dataParser: (json) {
        if (json is! Map<String, dynamic>) {
          throw const FormatException('Données du citoyen invalides.');
        }

        return AuthResponse.fromJson(json);
      },
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw ApiException(
        message: apiResponse.message ?? "Échec de l'inscription.",
      );
    }

    return apiResponse.data!;
  }

  Future<void> logout() async {
    await _authService.clearSession();
  }
}

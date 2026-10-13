import '../../../../core/errors/api_exception.dart';
import '../models/signalement.dart';
import '../models/signalement_request.dart';
import '../services/signalement_service.dart';

class SignalementRepository {
  final SignalementService _signalementService;

  SignalementRepository({SignalementService? signalementService})
    : _signalementService = signalementService ?? SignalementService();

  /// Récupérer les signalements d'un citoyen
  Future<List<Signalement>> getSignalementsByCitoyen(int idCitoyen) async {
    try {
      final response = await _signalementService.getSignalementsByCitoyen(
        idCitoyen,
      );

      if (response is! List) {
        throw ApiException(
          message: 'Format de réponse invalide pour les signalements.',
        );
      }

      return response
          .map(
            (item) =>
                Signalement.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    } catch (error) {
      if (error is ApiException) rethrow;

      throw ApiException(
        message: 'Impossible de récupérer les signalements du citoyen.',
      );
    }
  }

  /// Récupérer le détail d'un signalement
  Future<Signalement> getSignalementById(int idSignalement) async {
    try {
      final response = await _signalementService.getSignalementById(
        idSignalement,
      );

      if (response is! Map) {
        throw ApiException(
          message: 'Format de réponse invalide pour le signalement.',
        );
      }

      return Signalement.fromJson(Map<String, dynamic>.from(response));
    } catch (error) {
      if (error is ApiException) rethrow;

      throw ApiException(
        message: 'Impossible de récupérer le détail du signalement.',
      );
    }
  }

  /// Créer un signalement
  Future<Signalement> creerSignalement(SignalementRequest request) async {
    try {
      final response = await _signalementService.creerSignalement(
        request.toJson(),
      );

      if (response is! Map) {
        throw ApiException(
          message: 'Format de réponse invalide après création.',
        );
      }

      return Signalement.fromJson(Map<String, dynamic>.from(response));
    } catch (error) {
      if (error is ApiException) rethrow;

      throw ApiException(message: 'Impossible de créer le signalement.');
    }
  }
}

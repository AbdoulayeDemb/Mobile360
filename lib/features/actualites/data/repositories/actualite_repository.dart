import '../../../../core/errors/api_exception.dart';
import '../models/actualite.dart';
import '../services/actualite_service.dart';

class ActualiteRepository {
  final ActualiteService _service;

  ActualiteRepository({ActualiteService? service})
    : _service = service ?? ActualiteService();

  /// Récupère toutes les actualités publiées.
  Future<List<Actualite>> getActualites() async {
    final response = await _service.getActualites();

    dynamic rawData = response;

    // Le contrôleur Spring Boot renvoie directement une liste.
    // On accepte également une réponse enveloppée dans "data".
    if (response is Map<String, dynamic>) {
      if (response['success'] == false) {
        throw ApiException(
          message:
              response['message'] as String? ??
              'Impossible de récupérer les actualités.',
        );
      }

      rawData = response['data'];
    }

    if (rawData is! List) {
      throw const FormatException(
        'Le format de la liste des actualités est invalide.',
      );
    }

    return rawData.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Une actualité reçue est invalide.');
      }

      return Actualite.fromJson(item);
    }).toList();
  }

  /// Récupère une actualité à partir de son identifiant.
  Future<Actualite> getActualiteById(int idActualite) async {
    final response = await _service.getActualiteById(idActualite);

    dynamic rawData = response;

    // Accepte une réponse directe ou une enveloppe contenant "data".
    if (response is Map<String, dynamic> && response.containsKey('data')) {
      if (response['success'] == false) {
        throw ApiException(
          message:
              response['message'] as String? ??
              'Impossible de récupérer cette actualité.',
        );
      }

      rawData = response['data'];
    }

    if (rawData is! Map<String, dynamic>) {
      throw const FormatException('Le format de cette actualité est invalide.');
    }

    return Actualite.fromJson(rawData);
  }
}

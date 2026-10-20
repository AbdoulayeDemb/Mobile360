import '../../../../core/errors/api_exception.dart';
import '../models/actualite.dart';
import '../services/actualite_service.dart';

class ActualiteRepository {
  final ActualiteService _service;

  ActualiteRepository({ActualiteService? service})
    : _service = service ?? ActualiteService();

  /// Récupère toutes les actualités publiées,
  /// puis les trie de la plus récente à la plus ancienne.
  Future<List<Actualite>> getActualites() async {
    final response = await _service.getActualites();

    dynamic rawData = response;

    // Accepte une liste directe ou une réponse enveloppée dans "data".
    if (response is Map) {
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

    final actualites = rawData.map<Actualite>((item) {
      if (item is! Map) {
        throw const FormatException('Une actualité reçue est invalide.');
      }

      return Actualite.fromJson(Map<String, dynamic>.from(item));
    }).toList();

    // Les actualités les plus récentes apparaissent en premier.
    // Celles sans date sont placées à la fin.
    actualites.sort((a, b) {
      final dateA = a.datePublication;
      final dateB = b.datePublication;

      if (dateA == null && dateB == null) {
        return 0;
      }

      if (dateA == null) {
        return 1;
      }

      if (dateB == null) {
        return -1;
      }

      return dateB.compareTo(dateA);
    });

    return actualites;
  }

  /// Récupère une actualité à partir de son identifiant.
  Future<Actualite> getActualiteById(int idActualite) async {
    final response = await _service.getActualiteById(idActualite);

    dynamic rawData = response;

    // Accepte une actualité directe ou une réponse enveloppée dans "data".
    if (response is Map && response.containsKey('data')) {
      if (response['success'] == false) {
        throw ApiException(
          message:
              response['message'] as String? ??
              'Impossible de récupérer cette actualité.',
        );
      }

      rawData = response['data'];
    }

    if (rawData is! Map) {
      throw const FormatException('Le format de cette actualité est invalide.');
    }

    return Actualite.fromJson(Map<String, dynamic>.from(rawData));
  }
}

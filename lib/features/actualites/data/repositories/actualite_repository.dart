import '../../../../core/errors/api_exception.dart';
import '../models/actualite.dart';
import '../services/actualite_service.dart';

class ActualiteRepository {
  final ActualiteService _service;

  ActualiteRepository({ActualiteService? service})
    : _service = service ?? ActualiteService();

  Future<List<Actualite>> getActualites() async {
    final response = await _service.getActualites();

    dynamic rawData = response;

    // Accepte également une enveloppe APIResponse si nécessaire.
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

  Future<Actualite> getActualiteById(int idActualite) async {
    final response = await _service.getActualiteById(idActualite);

    dynamic rawData = response;

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

  Future<Actualite> publierActualite({
    required Map<String, dynamic> data,
  }) async {
    final response = await _service.publierActualite(data: data);

    if (response is! Map<String, dynamic>) {
      throw const FormatException(
        'Le format de l’actualité créée est invalide.',
      );
    }

    return Actualite.fromJson(response);
  }

  Future<Actualite> modifierActualite({
    required int idActualite,
    required Map<String, dynamic> data,
  }) async {
    final response = await _service.modifierActualite(
      idActualite: idActualite,
      data: data,
    );

    if (response is! Map<String, dynamic>) {
      throw const FormatException(
        'Le format de l’actualité modifiée est invalide.',
      );
    }

    return Actualite.fromJson(response);
  }

  Future<void> supprimerActualite(int idActualite) {
    return _service.supprimerActualite(idActualite);
  }
}

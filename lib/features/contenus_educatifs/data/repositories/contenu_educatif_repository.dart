
import '../../../../core/errors/api_exception.dart';
import '../models/contenu_educatif.dart';
import '../services/contenu_educatif_service.dart';

class ContenuEducatifRepository {
  final ContenuEducatifService _service;

  ContenuEducatifRepository({
    ContenuEducatifService? service,
  }) : _service = service ?? ContenuEducatifService();

  Future<List<ContenuEducatif>> getContenusEducatifs() async {
    final response = await _service.getContenusEducatifs();
    dynamic rawData = response;

    if (response is Map<String, dynamic>) {
      if (response['success'] == false) {
        throw ApiException(
          message: response['message'] as String? ??
              'Impossible de récupérer les contenus éducatifs.',
        );
      }
      rawData = response['data'];
    }

    if (rawData is! List) {
      throw const FormatException(
        'Le format de la liste des contenus éducatifs est invalide.',
      );
    }

    return rawData.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException(
          'Un contenu éducatif reçu est invalide.',
        );
      }
      return ContenuEducatif.fromJson(item);
    }).toList();
  }

  Future<ContenuEducatif> getContenuEducatifById(int idContenu) async {
    final response = await _service.getContenuEducatifById(idContenu);
    dynamic rawData = response;

    if (response is Map<String, dynamic> &&
        response.containsKey('data')) {
      if (response['success'] == false) {
        throw ApiException(
          message: response['message'] as String? ??
              'Impossible de récupérer ce contenu éducatif.',
        );
      }
      rawData = response['data'];
    }

    if (rawData is! Map<String, dynamic>) {
      throw const FormatException(
        'Le format de ce contenu éducatif est invalide.',
      );
    }

    return ContenuEducatif.fromJson(rawData);
  }
}

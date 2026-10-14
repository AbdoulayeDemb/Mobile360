import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/network/api_service.dart';
import '../../../../core/network/api_client.dart';

class SignalementService {
  Future<dynamic> creerSignalement(Map<String, dynamic> data) {
    return ApiService.post('/api/signalements', data: data);
  }

  Future<dynamic> getSignalementsByCitoyen(int idCitoyen) {
    return ApiService.get('/api/signalements/citoyen/$idCitoyen');
  }

  Future<dynamic> getSignalementById(int idSignalement) {
    return ApiService.get('/api/signalements/$idSignalement');
  }

  /// Téléverse une photo ou un fichier audio.
  /// Le backend attend le champ multipart "fichier".
  Future<String> televerserMedia({
    required File fichier,
    required String endpoint,
  }) async {
    try {
      final formData = FormData.fromMap({
        'fichier': await MultipartFile.fromFile(
          fichier.path,
          filename: fichier.uri.pathSegments.last,
        ),
      });

      final response = await ApiClient.dio.post<dynamic>(
        endpoint,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      final data = response.data;

      if (data is! Map || data['url'] is! String) {
        throw Exception('Le serveur n’a pas retourné l’URL du média.');
      }

      return data['url'] as String;
    } on DioException catch (error) {
      final message = error.response?.data;
      throw Exception(
        'Échec du téléversement du média : '
        '${message ?? error.message ?? "erreur réseau"}',
      );
    }
  }
}

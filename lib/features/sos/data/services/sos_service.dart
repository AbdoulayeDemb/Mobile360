import 'package:alert360_mobile/features/sos/data/models/sos_structure.dart';
import 'package:dio/dio.dart';

import '../../../../../core/network/api_client.dart';

class SosService {
  /// Recherche les structures de secours à proximité de la position GPS.
  ///
  /// Le backend attend :
  /// GET /api/v1/sos/proches
  /// ?latitude=...
  /// &longitude=...
  /// &rayonKm=15
  ///
  /// Le rayon est exprimé en kilomètres.
  Future<List<SosStructure>> obtenirStructuresProches({
    required double latitude,
    required double longitude,
    double rayonKm = 15,
  }) async {
    // Vérification des coordonnées GPS.
    if (latitude < -90 || latitude > 90) {
      throw ArgumentError('La latitude GPS est invalide.');
    }

    if (longitude < -180 || longitude > 180) {
      throw ArgumentError('La longitude GPS est invalide.');
    }

    if (rayonKm <= 0) {
      throw ArgumentError('Le rayon de recherche doit être positif.');
    }

    try {
      final Response<dynamic> response = await ApiClient.dio.get(
        '/api/v1/sos/proches',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'rayonKm': rayonKm,
        },
      );

      final dynamic data = response.data;

      if (data is! List) {
        throw const FormatException(
          'Le serveur n’a pas retourné une liste de structures.',
        );
      }

      final structures = data
          .map((element) {
            if (element is! Map) {
              throw const FormatException(
                'Une structure possède un format de données invalide.',
              );
            }

            return SosStructure.fromJson(Map<String, dynamic>.from(element));
          })
          .where((structure) {
            // On ne conserve que la police et les sapeurs-pompiers.
            return structure.estPolice || structure.estPompier;
          })
          .toList();

      // Classement par distance croissante.
      structures.sort(
        (a, b) => a.distanceEnMetres.compareTo(b.distanceEnMetres),
      );

      return structures;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;

      if (statusCode == 401) {
        throw Exception('Votre session a expiré. Veuillez vous reconnecter.');
      }

      if (statusCode == 403) {
        throw Exception(
          'Accès refusé. Vérifiez les autorisations de votre compte.',
        );
      }

      if (statusCode == 400) {
        throw Exception(
          'Les coordonnées GPS ou le rayon de recherche sont invalides.',
        );
      }

      if (e.response == null) {
        throw Exception(
          'Impossible de contacter le serveur. Vérifiez votre connexion.',
        );
      }

      throw Exception(
        'Erreur du serveur lors de la recherche des structures '
        '(HTTP ${statusCode ?? "inconnu"}).',
      );
    }
  }
}

import 'package:alert360_mobile/core/config/api_config.dart';

class MediaUrlHelper {
  MediaUrlHelper._();

  static String construireUrl(String? chemin) {
    if (chemin == null || chemin.trim().isEmpty) {
      return '';
    }

    final valeur = chemin.trim();

    // Une URL complète provenant de l'ancien backend
    // doit être reconstruite si elle utilise localhost.
    final uri = Uri.tryParse(valeur);

    if (uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty) {
      if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
        return '${ApiConfig.baseUrl}${uri.path}';
      }

      return valeur;
    }

    // Un chemin relatif : /api/medias/photos/...
    final cheminNormalise = valeur.startsWith('/') ? valeur : '/$valeur';

    return '${ApiConfig.baseUrl}$cheminNormalise';
  }
}

import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._();

  /// Adresse imposée au lancement avec --dart-define=API_BASE_URL=...
  static const String _baseUrlImposee = String.fromEnvironment('API_BASE_URL');

  /// Adresse de l'API.
  ///
  /// Web sur le même ordinateur : http://localhost:8080 (par défaut)
  /// Émulateur Android : http://10.0.2.2:8080 (par défaut, = le PC hôte)
  /// Téléphone physique sur le même Wi-Fi :
  ///   --dart-define=API_BASE_URL=http://IP_DE_TON_PC:8080
  static final String baseUrl = _resoudreBaseUrl();

  static String _resoudreBaseUrl() {
    if (_baseUrlImposee.isNotEmpty) return _baseUrlImposee;

    // Sur l'émulateur Android, localhost désigne l'émulateur lui-même.
    // if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    //   return 'http://10.0.2.2:8080';
    // }

    return 'http://localhost:8080';
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout = Duration(seconds: 15);

  /// Construit une URL complète à partir d'un chemin d'API ou de média.
  static String construireUrl(String chemin) {
    final base = baseUrl.replaceAll(RegExp(r'/+$'), '');
    final path = chemin.trim();

    if (path.isEmpty) return '';

    final uri = Uri.tryParse(path);

    if (uri != null && uri.hasScheme) {
      // Remplace localhost par l'adresse configurée pour les anciens médias.
      if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
        final baseUri = Uri.parse(base);

        return uri
            .replace(
              scheme: baseUri.scheme,
              host: baseUri.host,
              port: baseUri.hasPort ? baseUri.port : null,
            )
            .toString();
      }

      return path;
    }

    final pathNormalise = path.replaceFirst(RegExp(r'^/+'), '');

    if (pathNormalise.startsWith('api/')) {
      return '$base/$pathNormalise';
    }

    return '$base/${pathNormalise}';
  }
}

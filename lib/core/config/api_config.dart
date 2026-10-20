class ApiConfig {
  ApiConfig._();

  /// Adresse par défaut pour le développement Web local.
  static const String _defaultBaseUrl = 'http://localhost:8080';

  /// Adresse de l'API configurable au lancement avec --dart-define.
  ///
  /// Web sur le même ordinateur : http://localhost:8080
  /// Téléphone physique sur le même Wi-Fi : http://IP_DE_TON_PC:8080
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultBaseUrl,
  );

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

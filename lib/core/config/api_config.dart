class ApiConfig {
  ApiConfig._();

  /// Adresse par défaut pour le développement local.
  static const String _defaultBaseUrl = 'http://localhost:8080';

  /// URL configurable au lancement avec --dart-define.
  ///
  /// Développement Web sur le PC :
  /// http://localhost:8080
  ///
  /// Téléphone physique sur le même Wi-Fi :
  /// http://IP_DE_TON_PC:8080
  ///
  /// Production :
  /// https://alert360-systeme-signalement-13.onrender.com
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultBaseUrl,
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout = Duration(seconds: 15);

  /// Construit une URL complète à partir d'un chemin d'API
  /// ou d'une URL de média.
  static String construireUrl(String chemin) {
    final base = baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final path = chemin.trim();

    if (path.isEmpty) return '';

    final uri = Uri.tryParse(path);

    // Si le chemin est déjà une URL absolue.
    if (uri != null && uri.hasScheme && uri.hasAuthority) {
      // Corrige les anciennes URL de médias locales.
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

      // Conserve les URL absolues externes, notamment HTTPS.
      return uri.toString();
    }

    // Normalise les chemins relatifs.
    final pathNormalise = path.replaceFirst(RegExp(r'^/+'), '');

    // Évite de doubler le préfixe api/.
    if (pathNormalise == 'api' || pathNormalise.startsWith('api/')) {
      return '$base/$pathNormalise';
    }

    return '$base/$pathNormalise';
  }
}

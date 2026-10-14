class ApiConfig {
  ApiConfig._();

  /// Adresse par défaut pour le développement Web.
  static const String _defaultBaseUrl = 'http://localhost:8080';

  /// Peut être remplacée au lancement avec --dart-define.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultBaseUrl,
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout = Duration(seconds: 15);
}

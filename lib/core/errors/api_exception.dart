class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException({required this.message, this.statusCode});

  factory ApiException.fromStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return const ApiException(
          message: 'Les données envoyées sont invalides.',
          statusCode: 400,
        );
      case 401:
        return const ApiException(
          message: 'Vous devez vous connecter.',
          statusCode: 401,
        );
      case 403:
        return const ApiException(
          message: 'Vous n’avez pas la permission d’effectuer cette action.',
          statusCode: 403,
        );
      case 404:
        return const ApiException(
          message: 'La ressource demandée est introuvable.',
          statusCode: 404,
        );
      case 409:
        return const ApiException(
          message:
              'Cette opération entre en conflit avec les données existantes.',
          statusCode: 409,
        );
      case 500:
        return const ApiException(
          message: 'Une erreur est survenue sur le serveur.',
          statusCode: 500,
        );
      default:
        return ApiException(
          message: statusCode == null
              ? 'Impossible de contacter le serveur. Vérifiez votre connexion.'
              : 'Une erreur est survenue (code $statusCode).',
          statusCode: statusCode,
        );
    }
  }

  @override
  String toString() => message;
}

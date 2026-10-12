import 'package:dio/dio.dart';

import 'api_exception.dart';

class ApiErrorHandler {
  ApiErrorHandler._();

  static ApiException handle(Object error) {
    if (error is ApiException) {
      return error;
    }

    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.transformTimeout:
          return const ApiException(
            message: 'Le serveur met trop de temps à répondre.',
          );

        case DioExceptionType.connectionError:
          return const ApiException(
            message: 'Connexion au serveur impossible. Vérifiez votre réseau.',
          );

        case DioExceptionType.badResponse:
          return ApiException.fromStatusCode(error.response?.statusCode);

        case DioExceptionType.cancel:
          return const ApiException(message: 'La requête a été annulée.');

        case DioExceptionType.badCertificate:
          return const ApiException(
            message: 'La connexion sécurisée au serveur a échoué.',
          );

        case DioExceptionType.unknown:
          return const ApiException(
            message: 'Une erreur réseau inattendue est survenue.',
          );
      }
    }

    return const ApiException(message: 'Une erreur inattendue est survenue.');
  }
}

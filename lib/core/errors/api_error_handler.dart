import 'package:dio/dio.dart';

import 'api_exception.dart';

class ApiErrorHandler {
  static ApiException handle(Object error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final responseData = error.response?.data;

      // Priorité au message détaillé renvoyé par le backend.
      if (responseData is Map) {
        final message = responseData['message'];

        if (message is String && message.trim().isNotEmpty) {
          return ApiException(message: message.trim(), statusCode: statusCode);
        }
      }

      // Si le backend ne fournit aucun message exploitable.
      if (statusCode != null) {
        return ApiException.fromStatusCode(statusCode);
      }

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError) {
        return const ApiException(
          message:
              'Impossible de contacter le serveur. Vérifiez votre connexion.',
        );
      }

      return ApiException(
        message: error.message ?? 'Une erreur inattendue est survenue.',
      );
    }

    return ApiException(message: error.toString());
  }
}

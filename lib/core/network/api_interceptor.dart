import 'package:dio/dio.dart';

class ApiInterceptor extends Interceptor {
  final Future<String?> Function() getToken;

  ApiInterceptor({required this.getToken});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await getToken();

      if (token != null && token.trim().isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }

      handler.next(options);
    } catch (error) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: error,
          message: 'Impossible de récupérer le jeton d’authentification.',
        ),
      );
    }
  }
}

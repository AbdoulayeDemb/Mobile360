import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../storage/secure_storage_service.dart';
import 'api_interceptor.dart';

class ApiClient {
  ApiClient._();

  static final Dio dio = _createDio();

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.sendTimeout,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      ApiInterceptor(getToken: SecureStorageService.getToken),
    );

    // Diagnostic réseau visible dans la console en mode debug.
    if (kDebugMode) {
      debugPrint('[API] baseUrl = ${ApiConfig.baseUrl}');

      dio.interceptors.add(
        InterceptorsWrapper(
          onError: (error, handler) {
            debugPrint(
              '[API] ${error.requestOptions.method} ${error.requestOptions.uri}'
              ' -> ${error.type} ${error.response?.statusCode ?? ''}'
              ' ${error.error ?? error.message ?? ''}',
            );
            handler.next(error);
          },
        ),
      );
    }

    return dio;
  }
}

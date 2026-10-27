import 'package:dio/dio.dart';

import '../errors/api_error_handler.dart';
import 'api_client.dart';

class ApiService {
  ApiService._();

  static final Dio _dio = ApiClient.dio;

  static Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
      );

      return response.data;
    } catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  static Future<dynamic> post(String path, {Object? data}) async {
    try {
      final response = await _dio.post<dynamic>(path, data: data);

      return response.data;
    } catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  static Future<dynamic> put(String path, {Object? data}) async {
    try {
      final response = await _dio.put<dynamic>(path, data: data);

      return response.data;
    } catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  static Future<dynamic> patch(String path, {Object? data}) async {
    try {
      final response = await _dio.patch<dynamic>(path, data: data);

      return response.data;
    } catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  static Future<void> delete(String path) async {
    try {
      await _dio.delete<dynamic>(path);
    } catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  static Future<dynamic> testConnection() async {
    try {
      final response = await _dio.get<dynamic>('/api/categories');
      return response.data;
    } catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../network/api_client.dart';
import '../storage/preferences_service.dart';
import '../storage/secure_storage_service.dart';

/// Instance Dio partagée dans l'application.
final dioProvider = Provider<Dio>((ref) {
  return ApiClient.dio;
});

/// Service de stockage sécurisé du JWT.
final secureStorageProvider = Provider<SecureStorageServiceAccess>((ref) {
  return const SecureStorageServiceAccess();
});

/// Service des préférences locales.
final preferencesProvider = Provider<PreferencesServiceAccess>((ref) {
  return const PreferencesServiceAccess();
});

/// Accès au stockage sécurisé.
class SecureStorageServiceAccess {
  const SecureStorageServiceAccess();

  Future<String?> getToken() => SecureStorageService.getToken();

  Future<void> saveToken(String token) => SecureStorageService.saveToken(token);

  Future<void> deleteToken() => SecureStorageService.deleteToken();

  Future<bool> hasToken() => SecureStorageService.hasToken();
}

/// Accès aux préférences locales.
class PreferencesServiceAccess {
  const PreferencesServiceAccess();

  Future<bool> isOnboardingCompleted() =>
      PreferencesService.isOnboardingCompleted();

  Future<void> setOnboardingCompleted(bool completed) =>
      PreferencesService.setOnboardingCompleted(completed);

  Future<String> getThemeMode() => PreferencesService.getThemeMode();

  Future<void> setThemeMode(String mode) =>
      PreferencesService.setThemeMode(mode);
}

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';

  /// Enregistre le JWT après une connexion réussie.
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Récupère le JWT enregistré.
  static Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  /// Supprime le JWT lors de la déconnexion.
  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  /// Vérifie si un JWT est enregistré.
  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.trim().isNotEmpty;
  }
}

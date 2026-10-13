import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'auth_user_id';

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

  /// Enregistre l'identifiant de l'utilisateur connecté.
  static Future<void> saveUserId(int userId) async {
    await _storage.write(key: _userIdKey, value: userId.toString());
  }

  /// Récupère l'identifiant de l'utilisateur connecté.
  static Future<int?> getUserId() async {
    final value = await _storage.read(key: _userIdKey);
    return value == null ? null : int.tryParse(value);
  }

  /// Supprime l'identifiant utilisateur à la déconnexion.
  static Future<void> deleteUserId() async {
    await _storage.delete(key: _userIdKey);
  }

  /// Vérifie si un JWT est enregistré.
  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.trim().isNotEmpty;
  }
}

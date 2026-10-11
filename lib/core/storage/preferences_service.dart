import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  PreferencesService._();

  static const String _onboardingKey = 'onboarding_completed';
  static const String _themeModeKey = 'theme_mode';

  /// Indique si l'introduction a déjà été affichée.
  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  /// Enregistre la fin de l'introduction.
  static Future<void> setOnboardingCompleted(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, completed);
  }

  /// Récupère le mode d'affichage enregistré.
  static Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeModeKey) ?? 'system';
  }

  /// Enregistre le mode d'affichage.
  /// Valeurs prévues : system, light, dark.
  static Future<void> setThemeMode(String mode) async {
    if (!{'system', 'light', 'dark'}.contains(mode)) {
      throw ArgumentError.value(mode, 'mode', 'Mode non reconnu');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode);
  }
}

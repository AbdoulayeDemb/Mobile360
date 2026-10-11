class ApiEndpoints {
  ApiEndpoints._();

  // Authentification
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';

  // Fonctionnalités
  static const String signalements = '/api/signalements';
  static const String actualites = '/api/actualites';
  static const String contenusEducatifs = '/api/contenus-educatifs';
  static const String actionsCitoyennes = '/api/actions-citoyennes';
  static const String abus = '/api/abus';
  static const String utilisateurs = '/api/utilisateurs';
}

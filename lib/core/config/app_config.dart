class AppConfig {
  AppConfig._();

  static const String appName = 'Alert360';

  static const bool isProduction = bool.fromEnvironment('dart.vm.product');

  static const String environment = isProduction ? 'production' : 'development';
}

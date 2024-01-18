abstract class Env {
  static const String env = String.fromEnvironment(
    'ENV',
    defaultValue: 'DEVELOPMENT',
  );

  static const bool isDev = env == "DEVELOPMENT";
  static const bool isProd = env == "PRODUCTION";
  static const bool isTest = env == "TEST";
}

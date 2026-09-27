class AppConfig {
  static const analysisMode = String.fromEnvironment(
    'ANALYSIS_MODE',
    defaultValue: 'mock',
  );

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8082',
  );

  static bool get usesApi => analysisMode == 'api';

  static const maxImageBytes = 10 * 1024 * 1024;
}
enum AppEnvironment {
  dev,
  staging,
  production,
}

class AppEnvironmentConfig {
  const AppEnvironmentConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.enableAutonomy,
    required this.enableMultistreaming,
    required this.enableRevenueEngine,
    required this.enableCommandCenter,
  });

  final AppEnvironment environment;
  final String apiBaseUrl;
  final bool enableAutonomy;
  final bool enableMultistreaming;
  final bool enableRevenueEngine;
  final bool enableCommandCenter;

  bool get isProduction => environment == AppEnvironment.production;

  static AppEnvironmentConfig fromDartDefines() {
    const env = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
    final environment = switch (env) {
      'production' => AppEnvironment.production,
      'staging' => AppEnvironment.staging,
      _ => AppEnvironment.dev,
    };
    return AppEnvironmentConfig(
      environment: environment,
      apiBaseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://127.0.0.1:5001/yohpal-dev/africa-east1/api',
      ),
      enableAutonomy: const bool.fromEnvironment(
        'ENABLE_AUTONOMY',
        defaultValue: true,
      ),
      enableMultistreaming: const bool.fromEnvironment(
        'ENABLE_MULTISTREAMING',
        defaultValue: true,
      ),
      enableRevenueEngine: const bool.fromEnvironment(
        'ENABLE_REVENUE_ENGINE',
        defaultValue: true,
      ),
      enableCommandCenter: const bool.fromEnvironment(
        'ENABLE_COMMAND_CENTER',
        defaultValue: true,
      ),
    );
  }
}

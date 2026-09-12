class AppConfig {
  static const String appEnvironment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'prod',
  );

  static String get baseUrl {
    final override = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: '',
    );

    if (override.isNotEmpty) {
      return override;
    }

    switch (appEnvironment) {
      case 'dev':
        return 'https://doc-appoint-backend-meb4.onrender.com';
      case 'staging':
        return 'https://doc-appoint-backend-meb4.onrender.com';
      case 'prod':
      default:
        return 'https://doc-appoint-backend-meb4.onrender.com';
    }
  }

  static const Duration requestTimeout = Duration(seconds: 12);
}

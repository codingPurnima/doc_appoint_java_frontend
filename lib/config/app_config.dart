class AppConfig {
  static const String appEnvironment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'prod',
  );

  static const String _defaultLocalUrl =
      'https://docappointjava-production.up.railway.app';

  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL', defaultValue: '');

    if (override.isNotEmpty) {
      return override.endsWith('/')
          ? override.substring(0, override.length - 1)
          : override;
    }

    return _defaultLocalUrl;
  }

  static const Duration requestTimeout = Duration(seconds: 12);
}

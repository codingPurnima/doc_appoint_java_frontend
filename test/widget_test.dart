import 'package:docappoint/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppConfig baseUrl is configured and formatted properly', () {
    expect(AppConfig.baseUrl, isNotEmpty);
    expect(AppConfig.baseUrl.endsWith('/'), isFalse);
  });

  test('AppConfig requestTimeout is configured', () {
    expect(AppConfig.requestTimeout.inSeconds, greaterThan(0));
  });
}

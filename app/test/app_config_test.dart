import 'package:flutter_test/flutter_test.dart';
import 'package:trend/core/config/app_config.dart';

void main() {
  test('defaults to the hosted backend in debug and release builds', () {
    expect(
      AppConfig.apiBaseUrl,
      'https://s1103.usc1.mysecurecloudhost.com/backend/api',
    );
    expect(AppConfig.apiHostHeader, 'eduride.co.ke');
  });
}

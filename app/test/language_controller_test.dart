import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trend/features/auth/presentation/controllers/language_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'language controller updates the selected locale and persists it',
    () async {
      final controller = LanguageController();

      await controller.setLocale(const Locale('sw'));

      expect(controller.state.languageCode, 'sw');
    },
  );
}

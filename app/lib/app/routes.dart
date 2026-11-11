import 'package:flutter/material.dart';

import '../features/auth/presentation/language_screen.dart';
import '../features/auth/presentation/login_screen.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const language = '/language';
  static const login = '/login';
  static final pages = <String, WidgetBuilder>{
    language: (_) => const LanguageScreen(),
    login: (_) => const LoginScreen(),
  };
}

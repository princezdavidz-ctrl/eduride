import 'package:flutter/material.dart';

import '../core/config/app_config.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../core/theme/app_theme.dart';
import 'routes.dart';

class TreadApp extends StatelessWidget {
  const TreadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.splash,
      routes: {AppRoutes.splash: (_) => SplashScreen(), ...AppRoutes.pages},
    );
  }
}

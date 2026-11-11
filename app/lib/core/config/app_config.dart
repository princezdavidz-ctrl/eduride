import 'package:flutter/foundation.dart';

abstract final class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://s1103.usc1.mysecurecloudhost.com/backend/api',
  );
  static const apiHostHeader = String.fromEnvironment(
    'API_HOST_HEADER',
    defaultValue: 'eduride.co.ke',
  );

  static const appName = 'Edu Ride';
  static const mapTilerApiKey = String.fromEnvironment('MAPTILER_API_KEY');
  static const mapUserAgentPackageName = 'com.example.trend';

  static String get mapTileUrl {
    if (mapTilerApiKey.isEmpty) {
      return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
    return 'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=$mapTilerApiKey';
  }

  static bool get isProduction =>
      kReleaseMode && !apiBaseUrl.contains('localhost');
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/routes.dart';
import '../../../core/config/app_config.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    Future<bool> Function()? internetCheck,
    Future<String?> Function()? permissionRequester,
  }) : _internetCheck = internetCheck ?? checkInternetConnection,
       _permissionRequester = permissionRequester ?? requestStartupPermissions;

  final Future<bool> Function() _internetCheck;
  final Future<String?> Function() _permissionRequester;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _permissionsRequestedKey = 'startup_permissions_requested';
  static const _minimumSplashDuration = Duration(milliseconds: 1400);

  String _connectionStatus = 'Checking your internet connection...';
  String? _permissionError;

  @override
  void initState() {
    super.initState();
    _startApp();
  }

  Future<void> _startApp() async {
    final minimumDuration = Future<void>.delayed(_minimumSplashDuration);
    final hasInternet = await widget._internetCheck();
    if (!mounted) return;

    setState(() {
      _connectionStatus = hasInternet
          ? 'Internet connection ready'
          : 'No internet connection. Offline demo is available.';
    });

    await minimumDuration;
    if (!mounted) return;

    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;

    final alreadyRequested =
        preferences.getBool(_permissionsRequestedKey) ?? false;
    if (!alreadyRequested) {
      if (mounted) {
        setState(() {
          _connectionStatus = 'Requesting notification and location access...';
        });
      }

      final permissionError = await widget._permissionRequester();
      if (!mounted) return;
      _permissionError = permissionError;
      await preferences.setBool(_permissionsRequestedKey, true);
    }

    if (!mounted) return;
    if (_permissionError != null) {
      setState(() => _connectionStatus = _permissionError!);
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted) return;
    }
    Navigator.of(context).pushReplacementNamed(AppRoutes.language);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F3D86), Color(0xFF1769E0), Color(0xFF4C91F2)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -90,
                right: -70,
                child: _SplashGlow(size: 250),
              ),
              Positioned(
                bottom: 80,
                left: -110,
                child: _SplashGlow(size: 280),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.16),
                                blurRadius: 34,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/images/logo.jpeg',
                              width: 142,
                              height: 142,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          AppConfig.appName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 9),
                        const Text(
                          'Every journey. Safely connected.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFE8F1FF),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 42),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              const SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.6,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                _connectionStatus,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  height: 1.4,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Positioned(
                bottom: 18,
                left: 0,
                right: 0,
                child: Text(
                  'A safer school journey starts here',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFDCEAFF),
                    fontSize: 11,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashGlow extends StatelessWidget {
  const _SplashGlow({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: 0.055),
    ),
  );
}

Future<String?> requestStartupPermissions() async {
  final isMobile =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  if (!isMobile) return null;

  final preferences = await SharedPreferences.getInstance();
  if (preferences.getBool('startup_permissions_requested') ?? false) {
    return null;
  }

  final errors = <String>[];
  for (final (permission, label) in [
    (Permission.notification, 'notification'),
    (Permission.locationWhenInUse, 'location'),
  ]) {
    try {
      await permission.request();
    } on PlatformException catch (error) {
      errors.add('$label permission request failed (${error.code})');
    }
  }

  return errors.isEmpty ? null : errors.join('; ');
}

Future<bool> checkInternetConnection({
  String? apiBaseUrl,
  String? apiHostHeader,
}) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);

  try {
    final apiUri = Uri.parse(apiBaseUrl ?? AppConfig.apiBaseUrl);
    final apiBaseUri = apiUri.path.endsWith('/')
        ? apiUri
        : apiUri.replace(path: '${apiUri.path}/');
    final healthUri = apiBaseUri.resolve('../health');
    final request = await client
        .getUrl(healthUri)
        .timeout(const Duration(seconds: 3));
    final hostHeader = apiHostHeader ?? AppConfig.apiHostHeader;
    if (hostHeader.isNotEmpty) {
      request.headers.set(HttpHeaders.hostHeader, hostHeader);
    }
    final response = await request.close().timeout(const Duration(seconds: 3));
    if (response.statusCode != HttpStatus.ok) return false;
    final responseBody = await response
        .transform(utf8.decoder)
        .join()
        .timeout(const Duration(seconds: 3));
    final payload = jsonDecode(responseBody);
    return payload is Map<String, dynamic> &&
        payload['ok'] == true &&
        payload['service'] == 'tread-backend';
  } on IOException {
    return false;
  } on TimeoutException {
    return false;
  } on FormatException {
    return false;
  } finally {
    client.close(force: true);
  }
}

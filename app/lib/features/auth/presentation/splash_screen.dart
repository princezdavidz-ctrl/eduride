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
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.jpeg',
              width: 220,
              height: 220,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 12),
            const Text(
              AppConfig.appName,
              style: TextStyle(
                color: Color(0xFF1769E0),
                fontSize: 42,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your school journey, made easier',
              style: TextStyle(color: Color(0xFF667085), fontSize: 14),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: 220,
              child: LinearProgressIndicator(
                minHeight: 4,
                borderRadius: BorderRadius.circular(4),
                color: const Color(0xFF1769E0),
                backgroundColor: const Color(0xFFEAF2FF),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _connectionStatus,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF667085), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
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

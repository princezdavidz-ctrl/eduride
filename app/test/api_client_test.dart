import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trend/core/networking/api_client.dart';
import 'package:trend/features/auth/presentation/splash_screen.dart';

void main() {
  test('sends the stored access token as a bearer token', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final authorizationHeader = Completer<String?>();
    final requestHost = Completer<String?>();
    final requestPath = Completer<String>();
    server.listen((request) async {
      authorizationHeader.complete(
        request.headers.value(HttpHeaders.authorizationHeader),
      );
      requestHost.complete(request.headers.value(HttpHeaders.hostHeader));
      requestPath.complete(request.uri.path);
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'ok': true}));
      await request.response.close();
    });

    final client = ApiClient(
      baseUrl: 'http://${server.address.address}:${server.port}/api',
      accessTokenReader: () async => 'test-token',
      hostHeader: 'api.example.test',
    );

    try {
      expect(await client.get('/profile'), {'ok': true});
      expect(await requestHost.future, 'api.example.test');
      expect(await requestPath.future, '/api/profile');
      expect(await authorizationHeader.future, 'Bearer test-token');
    } finally {
      client.close();
      await server.close(force: true);
    }
  });

  test(
    'splash checks the backend health endpoint under the API prefix',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final requestPath = Completer<String>();
      server.listen((request) async {
        requestPath.complete(request.uri.path);
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'ok': true, 'service': 'tread-backend'}));
        await request.response.close();
      });

      try {
        final isAvailable = await checkInternetConnection(
          apiBaseUrl: 'http://${server.address.address}:${server.port}/api',
          apiHostHeader: '',
        );

        expect(isAvailable, isTrue);
        expect(await requestPath.future, '/health');
      } finally {
        await server.close(force: true);
      }
    },
  );
}

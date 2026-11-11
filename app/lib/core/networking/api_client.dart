import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../config/app_config.dart';
import '../errors/app_failure.dart';

typedef AccessTokenReader = Future<String?> Function();

class ApiClient {
  ApiClient({
    HttpClient? httpClient,
    this.accessTokenReader,
    String? baseUrl,
    String? hostHeader,
  }) : _httpClient =
           httpClient ??
           (HttpClient()..connectionTimeout = const Duration(seconds: 15)),
       _baseUrl = _withTrailingSlash(
         Uri.parse(baseUrl ?? AppConfig.apiBaseUrl),
       ),
       _hostHeader = hostHeader ?? AppConfig.apiHostHeader;

  final HttpClient _httpClient;
  final AccessTokenReader? accessTokenReader;
  final Uri _baseUrl;
  final String _hostHeader;

  Future<Map<String, dynamic>> get(String path) => _send('GET', path);

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) => _send('POST', path, body: body);

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) => _send('PATCH', path, body: body);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final requestUri = _baseUrl.resolve(path.replaceFirst(RegExp(r'^/'), ''));
      final request = await _httpClient.openUrl(method, requestUri);
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
      if (_hostHeader.isNotEmpty) {
        request.headers.set(HttpHeaders.hostHeader, _hostHeader);
      }

      final token = await accessTokenReader?.call();
      if (token != null && token.isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      if (body != null) request.write(jsonEncode(body));

      final response = await request.close();
      final responseBody = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 30));
      final decoded = responseBody.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(responseBody);

      if (response.statusCode == HttpStatus.unauthorized) {
        throw const UnauthorizedFailure();
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ServerFailure('Request failed (${response.statusCode}).');
      }
      if (decoded is! Map<String, dynamic>) {
        throw const ServerFailure('The server returned an invalid response.');
      }
      return decoded;
    } on AppFailure {
      rethrow;
    } on IOException {
      throw const NetworkFailure();
    } on TimeoutException {
      throw const NetworkFailure();
    } on FormatException {
      throw const ServerFailure('The server returned invalid data.');
    }
  }

  void close() => _httpClient.close(force: true);

  static Uri _withTrailingSlash(Uri uri) {
    if (uri.path.endsWith('/')) return uri;
    return uri.replace(path: '${uri.path}/');
  }
}

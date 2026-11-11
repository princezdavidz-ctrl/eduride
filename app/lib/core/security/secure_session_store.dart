import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureSessionStore {
  const SecureSessionStore(this._storage);

  final FlutterSecureStorage _storage;
  static const _tokenKey = 'tread_access_token';

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<String?> readAccessToken() => _storage.read(key: _tokenKey);

  Future<bool> isAuthenticated() async =>
      (await readAccessToken()) != null && (await readAccessToken())!.isNotEmpty;

  Future<void> clear() => _storage.delete(key: _tokenKey);
}

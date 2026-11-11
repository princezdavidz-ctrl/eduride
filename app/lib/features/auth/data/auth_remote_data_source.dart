import '../../../core/networking/api_client.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) =>
      _client.post('/auth/login', body: {'email': email, 'password': password});

  Future<Map<String, dynamic>> signUp({
    required String name,
    required String email,
    required String password,
  }) => _client.post(
    '/auth/signup',
    body: {'name': name, 'email': email, 'password': password},
  );

  Future<Map<String, dynamic>> requestPasswordReset(String email) =>
      _client.post('/auth/forgot-password', body: {'email': email});

  Future<Map<String, dynamic>> currentUser() => _client.get('/auth/me');

  Future<void> signOut() async {
    await _client.post('/auth/logout');
  }
}

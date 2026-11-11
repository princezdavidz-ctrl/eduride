import '../../../core/config/app_config.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/security/secure_session_store.dart';
import 'auth_remote_data_source.dart';
import '../domain/entities/auth_session.dart';
import '../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  static const _demoEmail = 'test@gmail.com';
  static const _demoPassword = 'Password123';
  static const _demoToken = 'edu-ride-demo-session';

  AuthRepositoryImpl({
    required this._remoteDataSource,
    required this._sessionStore,
  });

  final AuthRemoteDataSource _remoteDataSource;
  final SecureSessionStore _sessionStore;

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    late final Map<String, dynamic> response;
    try {
      response = await _remoteDataSource.signIn(
        email: email,
        password: password,
      );
    } on NetworkFailure {
      if (!AppConfig.isDemoMode ||
          email.trim().toLowerCase() != _demoEmail ||
          password != _demoPassword) {
        rethrow;
      }

      final session = AuthSession(
        accessToken: _demoToken,
        userId: 'demo-user',
        expiresAt: DateTime.now().add(const Duration(hours: 8)),
        isDemoSession: true,
      );
      await _sessionStore.saveAccessToken(session.accessToken);
      return session;
    }

    final token =
        response['token'] as String? ??
        response['accessToken'] as String? ??
        '';
    if (token.isEmpty) {
      throw const ServerFailure('Authentication response was missing a token.');
    }

    final user = response['user'];
    final session = AuthSession(
      accessToken: token,
      userId: _userId(response, user),
      expiresAt: DateTime.now().add(const Duration(hours: 8)),
    );

    await _sessionStore.saveAccessToken(session.accessToken);
    return session;
  }

  @override
  Future<AuthSession> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _remoteDataSource.signUp(
      name: name,
      email: email,
      password: password,
    );

    final token =
        response['token'] as String? ??
        response['accessToken'] as String? ??
        '';
    if (token.isEmpty) {
      throw const ServerFailure(
        'Account creation response was missing a token.',
      );
    }

    final user = response['user'];
    final session = AuthSession(
      accessToken: token,
      userId: _userId(response, user),
      expiresAt: DateTime.now().add(const Duration(hours: 8)),
    );

    await _sessionStore.saveAccessToken(session.accessToken);
    return session;
  }

  @override
  Future<bool> requestPasswordReset(String email) async {
    final response = await _remoteDataSource.requestPasswordReset(email);
    return response['available'] == true;
  }

  @override
  Future<AuthSession?> restoreSession() async {
    final token = await _sessionStore.readAccessToken();
    if (token == null || token.isEmpty) return null;
    if (token == _demoToken) {
      if (!AppConfig.isDemoMode) return null;
      return AuthSession(
        accessToken: token,
        userId: 'demo-user',
        expiresAt: DateTime.now().add(const Duration(hours: 8)),
        isDemoSession: true,
      );
    }

    try {
      final response = await _remoteDataSource.currentUser();
      final user = response['user'];
      if (user is! Map<String, dynamic>) {
        throw const ServerFailure(
          'Authentication response was missing the current user.',
        );
      }
      return AuthSession(
        accessToken: token,
        userId: _userId(response, user),
        expiresAt: DateTime.now().add(const Duration(hours: 8)),
      );
    } on UnauthorizedFailure {
      await _sessionStore.clear();
      return null;
    } on NetworkFailure {
      return AuthSession(
        accessToken: token,
        userId: 'offline-user',
        expiresAt: DateTime.now().add(const Duration(hours: 8)),
      );
    }
  }

  @override
  Future<void> signOut() async {
    final token = await _sessionStore.readAccessToken();
    if (token == null || token.isEmpty) return _sessionStore.clear();

    try {
      if (token != _demoToken) await _remoteDataSource.signOut();
    } on NetworkFailure {
      // Local sign-out must remain available when the device is offline.
    } on UnauthorizedFailure {
      // The server session is already invalid.
    } finally {
      await _sessionStore.clear();
    }
  }

  String _userId(Map<String, dynamic> response, Object? user) {
    if (user is Map<String, dynamic> && user['id'] != null) {
      return user['id'].toString();
    }
    return (response['userId'] ?? response['id'] ?? 'anonymous').toString();
  }
}

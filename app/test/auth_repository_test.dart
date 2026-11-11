import 'package:flutter_test/flutter_test.dart';
import 'package:trend/core/errors/app_failure.dart';
import 'package:trend/core/security/secure_session_store.dart';
import 'package:trend/features/auth/data/auth_remote_data_source.dart';
import 'package:trend/features/auth/data/auth_repository_impl.dart';

class _FakeSessionStore implements SecureSessionStore {
  String? token;

  @override
  Future<void> saveAccessToken(String value) async {
    token = value;
  }

  @override
  Future<String?> readAccessToken() async => token;

  @override
  Future<bool> isAuthenticated() async => token?.isNotEmpty ?? false;

  @override
  Future<void> clear() async {
    token = null;
  }
}

class _FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  _FakeAuthRemoteDataSource({this.signInFailure});

  final Object? signInFailure;
  var signInCalls = 0;

  @override
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    signInCalls++;
    if (signInFailure case final error?) throw error;
    return {
      'token': 'server-token',
      'user': {'id': 'server-user', 'email': email},
    };
  }

  @override
  Future<Map<String, dynamic>> signUp({
    required String name,
    required String email,
    required String password,
  }) async => {};

  @override
  Future<Map<String, dynamic>> requestPasswordReset(String email) async => {};

  @override
  Future<Map<String, dynamic>> currentUser() async => {};

  @override
  Future<void> signOut() async {}
}

void main() {
  test('demo credentials authenticate against the backend first', () async {
    final remote = _FakeAuthRemoteDataSource();
    final store = _FakeSessionStore();
    final repository = AuthRepositoryImpl(
      remoteDataSource: remote,
      sessionStore: store,
    );

    final session = await repository.signIn(
      email: 'test@gmail.com',
      password: 'Password123',
    );

    expect(remote.signInCalls, 1);
    expect(session.isDemoSession, isFalse);
    expect(session.accessToken, 'server-token');
    expect(session.userId, 'server-user');
    expect(store.token, 'server-token');
  });

  test(
    'demo credentials fall back only when the backend is unreachable',
    () async {
      final remote = _FakeAuthRemoteDataSource(
        signInFailure: const NetworkFailure(),
      );
      final store = _FakeSessionStore();
      final repository = AuthRepositoryImpl(
        remoteDataSource: remote,
        sessionStore: store,
      );

      final session = await repository.signIn(
        email: 'test@gmail.com',
        password: 'Password123',
      );

      expect(remote.signInCalls, 1);
      expect(session.isDemoSession, isTrue);
      expect(store.token, 'edu-ride-demo-session');
    },
  );

  test(
    'invalid backend demo credentials do not silently become offline login',
    () async {
      final remote = _FakeAuthRemoteDataSource(
        signInFailure: const UnauthorizedFailure(),
      );
      final store = _FakeSessionStore();
      final repository = AuthRepositoryImpl(
        remoteDataSource: remote,
        sessionStore: store,
      );

      await expectLater(
        repository.signIn(email: 'test@gmail.com', password: 'Password123'),
        throwsA(isA<UnauthorizedFailure>()),
      );

      expect(remote.signInCalls, 1);
      expect(store.token, isNull);
    },
  );
}

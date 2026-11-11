import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trend/features/auth/domain/entities/auth_session.dart';
import 'package:trend/features/auth/domain/repositories/auth_repository.dart';
import 'package:trend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:trend/features/auth/presentation/providers/auth_provider.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.passwordResetAvailable = true});

  final bool passwordResetAvailable;

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    return AuthSession(
      accessToken: 'token-123',
      userId: 'user-1',
      expiresAt: DateTime.now().add(const Duration(hours: 2)),
    );
  }

  @override
  Future<AuthSession> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    return AuthSession(
      accessToken: 'token-456',
      userId: 'user-2',
      expiresAt: DateTime.now().add(const Duration(hours: 2)),
    );
  }

  @override
  Future<bool> requestPasswordReset(String email) async =>
      passwordResetAvailable;

  @override
  Future<AuthSession?> restoreSession() async => AuthSession(
    accessToken: 'token-restored',
    userId: 'user-restored',
    expiresAt: DateTime.now().add(const Duration(hours: 2)),
  );

  @override
  Future<void> signOut() async {}
}

void main() {
  test('auth controller signs in and stores the session', () async {
    final controller = AuthController(_FakeAuthRepository());

    final session = await controller.signIn(
      email: 'user@example.com',
      password: 'password123',
    );

    expect(session, isNotNull);
    expect(session!.accessToken, 'token-123');
    expect(controller.state.session, isNotNull);
  });

  test('auth controller reports when password reset is unavailable', () async {
    final controller = AuthController(
      _FakeAuthRepository(passwordResetAvailable: false),
    );

    final available = await controller.requestPasswordReset(
      email: 'user@example.com',
    );

    expect(available, isFalse);
    expect(controller.state.isSubmitting, isFalse);
    expect(controller.state.errorMessage, isNull);
  });

  test(
    'auth controller provider exposes a working controller instance',
    () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider);

      expect(controller, isNotNull);
      expect(controller.state.session, isNull);

      final session = await controller.signIn(
        email: 'user@example.com',
        password: 'password123',
      );

      expect(session, isNotNull);
      expect(session!.accessToken, 'token-123');
    },
  );
}

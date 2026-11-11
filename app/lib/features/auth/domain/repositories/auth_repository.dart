import '../entities/auth_session.dart';

abstract interface class AuthRepository {
  Future<AuthSession> signIn({required String email, required String password});

  Future<AuthSession> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<bool> requestPasswordReset(String email);

  Future<AuthSession?> restoreSession();

  Future<void> signOut();
}

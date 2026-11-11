import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_failure.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthControllerState {
  const AuthControllerState({
    this.session,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final AuthSession? session;
  final bool isSubmitting;
  final String? errorMessage;

  AuthControllerState copyWith({
    AuthSession? session,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthControllerState(
      session: session ?? this.session,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class AuthController extends ChangeNotifier {
  AuthController(this._repository);

  final AuthRepository _repository;
  var state = const AuthControllerState();

  Future<AuthSession?> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    notifyListeners();

    try {
      final session = await _repository.signIn(
        email: email,
        password: password,
      );
      state = state.copyWith(
        session: session,
        isSubmitting: false,
        clearError: true,
      );
      notifyListeners();
      return session;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: error is AppFailure ? error.message : error.toString(),
      );
      notifyListeners();
      return null;
    }
  }

  Future<AuthSession?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    notifyListeners();

    try {
      final session = await _repository.signUp(
        name: name,
        email: email,
        password: password,
      );
      state = state.copyWith(
        session: session,
        isSubmitting: false,
        clearError: true,
      );
      notifyListeners();
      return session;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: error is AppFailure ? error.message : error.toString(),
      );
      notifyListeners();
      return null;
    }
  }

  Future<bool?> requestPasswordReset({required String email}) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    notifyListeners();

    try {
      final available = await _repository.requestPasswordReset(email);
      state = state.copyWith(isSubmitting: false, clearError: true);
      notifyListeners();
      return available;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: error is AppFailure ? error.message : error.toString(),
      );
      notifyListeners();
      return null;
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AuthControllerState();
    notifyListeners();
  }
}

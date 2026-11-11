sealed class AppFailure implements Exception {
  const AppFailure(this.message);

  final String message;
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure([
    super.message = 'Unable to connect. Please try again.',
  ]);
}

final class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure([super.message = 'Your session has expired.']);
}

final class ServerFailure extends AppFailure {
  const ServerFailure([super.message = 'Something went wrong on our side.']);
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message);
}

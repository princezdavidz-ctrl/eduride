import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/networking/api_client.dart';
import '../../../../core/security/secure_session_store.dart';
import '../../data/auth_remote_data_source.dart';
import '../../data/auth_repository_impl.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../controllers/auth_controller.dart';

final secureSessionStoreProvider = Provider<SecureSessionStore>(
  (_) => const SecureSessionStore(FlutterSecureStorage()),
);

final authApiClientProvider = Provider<ApiClient>((ref) {
  final sessionStore = ref.read(secureSessionStoreProvider);

  return ApiClient(accessTokenReader: () => sessionStore.readAccessToken());
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final apiClient = ref.read(authApiClientProvider);
  return AuthRemoteDataSource(apiClient);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.read(authRemoteDataSourceProvider);
  final sessionStore = ref.read(secureSessionStoreProvider);

  return AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    sessionStore: sessionStore,
  );
});

final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  final repository = ref.read(authRepositoryProvider);
  return AuthController(repository);
});

final authSessionProvider = FutureProvider<AuthSession?>((ref) async {
  return ref.read(authRepositoryProvider).restoreSession();
});

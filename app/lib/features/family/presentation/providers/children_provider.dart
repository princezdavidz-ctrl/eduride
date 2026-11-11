import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/networking/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/children_remote_data_source.dart';
import '../../data/children_repository_impl.dart';
import '../../domain/repositories/children_repository.dart';
import '../controllers/children_controller.dart';

final childrenRemoteDataSourceProvider = Provider<ChildrenRemoteDataSource>((
  ref,
) {
  return ChildrenRemoteDataSource(ref.read(childrenApiClientProvider));
});

final childrenApiClientProvider = Provider<ApiClient>((ref) {
  final sessionStore = ref.read(secureSessionStoreProvider);
  return ApiClient(accessTokenReader: () => sessionStore.readAccessToken());
});

final childrenRepositoryProvider = Provider<ChildrenRepository>((ref) {
  return ChildrenRepositoryImpl(ref.read(childrenRemoteDataSourceProvider));
});

final childrenControllerProvider = ChangeNotifierProvider<ChildrenController>((
  ref,
) {
  return ChildrenController(ref.read(childrenRepositoryProvider));
});

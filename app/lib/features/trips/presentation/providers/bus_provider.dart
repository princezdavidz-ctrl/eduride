import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/networking/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/bus_remote_data_source.dart';
import '../../data/bus_repository_impl.dart';
import '../../domain/entities/bus.dart';
import '../../domain/repositories/bus_repository.dart';

final busApiClientProvider = Provider<ApiClient>((ref) {
  final sessionStore = ref.read(secureSessionStoreProvider);
  return ApiClient(accessTokenReader: () => sessionStore.readAccessToken());
});

final busRepositoryProvider = Provider<BusRepository>((ref) {
  return BusRepositoryImpl(BusRemoteDataSource(ref.read(busApiClientProvider)));
});

final busesProvider = FutureProvider<List<Bus>>((ref) {
  return ref.read(busRepositoryProvider).fetchBuses();
});

import '../domain/entities/bus.dart';
import '../domain/repositories/bus_repository.dart';
import 'bus_remote_data_source.dart';

class BusRepositoryImpl implements BusRepository {
  const BusRepositoryImpl(this._remoteDataSource);

  final BusRemoteDataSource _remoteDataSource;

  @override
  Future<List<Bus>> fetchBuses() async {
    final response = await _remoteDataSource.fetchBuses();
    return response.map(_toBus).toList();
  }

  Bus _toBus(Map<String, dynamic> data) {
    return Bus(
      id: (data['id'] ?? '').toString(),
      route: (data['route'] ?? '').toString(),
      status: (data['status'] ?? 'unknown').toString(),
      school: (data['school'] ?? '').toString(),
      latitude: _asDouble(data['latitude']),
      longitude: _asDouble(data['longitude']),
      etaMinutes: _asInt(data['etaMinutes']),
    );
  }

  double _asDouble(Object? value) => value is num ? value.toDouble() : 0;

  int _asInt(Object? value) => value is num ? value.toInt() : 0;
}

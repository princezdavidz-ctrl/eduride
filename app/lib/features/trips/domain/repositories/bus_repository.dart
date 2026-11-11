import '../entities/bus.dart';

abstract interface class BusRepository {
  Future<List<Bus>> fetchBuses();
}

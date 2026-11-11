import '../../../../core/networking/api_client.dart';

class BusRemoteDataSource {
  const BusRemoteDataSource(this._client);

  final ApiClient _client;

  Future<List<Map<String, dynamic>>> fetchBuses() async {
    final response = await _client.get('/buses');
    final data = response['buses'];
    if (data is! List) return const [];
    return data.whereType<Map<String, dynamic>>().toList();
  }
}

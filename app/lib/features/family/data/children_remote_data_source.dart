import '../../../core/networking/api_client.dart';

class ChildrenRemoteDataSource {
  const ChildrenRemoteDataSource(this._client);

  final ApiClient _client;

  Future<List<Map<String, dynamic>>> fetchChildren() async {
    final response = await _client.get('/children');
    final data = response['children'];
    if (data is! List) return const [];
    return data.whereType<Map<String, dynamic>>().toList();
  }

  Future<Map<String, dynamic>> addChild({
    required String name,
    required String school,
  }) async {
    final response = await _client.post(
      '/children',
      body: {'name': name, 'school': school},
    );
    final child = response['child'];
    if (child is! Map<String, dynamic>) {
      throw const FormatException('The server returned an invalid child.');
    }
    return child;
  }

  Future<Map<String, dynamic>> changeSchool({
    required String childId,
    required String school,
  }) async {
    final response = await _client.patch(
      '/children/${Uri.encodeComponent(childId)}',
      body: {'school': school},
    );
    final child = response['child'];
    if (child is! Map<String, dynamic>) {
      throw const FormatException('The server returned an invalid child.');
    }
    return child;
  }
}

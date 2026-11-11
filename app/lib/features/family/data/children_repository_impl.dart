import '../domain/entities/child.dart';
import '../domain/repositories/children_repository.dart';
import 'children_remote_data_source.dart';

class ChildrenRepositoryImpl implements ChildrenRepository {
  const ChildrenRepositoryImpl(this._remoteDataSource);

  final ChildrenRemoteDataSource _remoteDataSource;

  @override
  Future<List<Child>> fetchChildren() async {
    final response = await _remoteDataSource.fetchChildren();
    return response.map(_toChild).toList();
  }

  @override
  Future<Child> addChild({required String name, required String school}) async {
    final response = await _remoteDataSource.addChild(
      name: name,
      school: school,
    );
    return _toChild(response);
  }

  @override
  Future<Child> changeSchool({
    required String childId,
    required String school,
  }) async {
    final response = await _remoteDataSource.changeSchool(
      childId: childId,
      school: school,
    );
    return _toChild(response);
  }

  Child _toChild(Map<String, dynamic> data) {
    final nameParts = (data['name'] ?? '').toString().trim().split(
      RegExp(r'\s+'),
    );
    final firstName = nameParts.isEmpty || nameParts.first.isEmpty
        ? 'Child'
        : nameParts.first;
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    return Child(
      id: (data['id'] ?? '').toString(),
      firstName: firstName,
      lastName: lastName,
      schoolName: (data['school'] ?? '').toString(),
    );
  }
}

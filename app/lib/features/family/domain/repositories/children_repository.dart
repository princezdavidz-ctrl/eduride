import '../entities/child.dart';

abstract interface class ChildrenRepository {
  Future<List<Child>> fetchChildren();

  Future<Child> addChild({required String name, required String school});

  Future<Child> changeSchool({required String childId, required String school});
}

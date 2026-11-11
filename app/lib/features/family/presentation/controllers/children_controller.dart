import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_failure.dart';
import '../../domain/entities/child.dart';
import '../../domain/repositories/children_repository.dart';

class ChildrenController extends ChangeNotifier {
  ChildrenController(this._repository);

  final ChildrenRepository _repository;
  List<Child> children = const [];
  bool isLoading = false;
  bool isSubmitting = false;
  String? errorMessage;

  Future<void> loadChildren() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      children = await _repository.fetchChildren();
    } catch (error) {
      errorMessage = _messageFor(error);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addChild({required String name, required String school}) async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      final child = await _repository.addChild(name: name, school: school);
      children = [...children, child];
      return true;
    } catch (error) {
      errorMessage = _messageFor(error);
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> changeSchool({
    required String childId,
    required String school,
  }) async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      final updatedChild = await _repository.changeSchool(
        childId: childId,
        school: school,
      );
      children = [
        for (final child in children)
          if (child.id == childId) updatedChild else child,
      ];
      return true;
    } catch (error) {
      errorMessage = _messageFor(error);
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  String _messageFor(Object error) {
    return error is AppFailure
        ? error.message
        : 'Something went wrong. Please try again.';
  }
}

import 'package:flutter/foundation.dart';

import '../models/course_model.dart';
import '../services/course_api_service.dart';

/// Lifecycle of a network-backed view: loading → loaded (success) or error.
enum CourseLoadState { idle, loading, loaded, error }

/// Owns the list of courses shown in the UI and brokers all CRUD calls
/// through [CourseApiService]. Screens read state via [CourseScope] and
/// invoke mutation methods directly — they never touch `http`.
class CourseController extends ChangeNotifier {
  CourseController({CourseApiService? service})
      : _service = service ?? CourseApiService();

  final CourseApiService _service;

  CourseLoadState _state = CourseLoadState.idle;
  CourseLoadState get state => _state;

  List<CourseModel> _courses = const [];
  List<CourseModel> get courses => List.unmodifiable(_courses);

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // -- Read ----------------------------------------------------------------

  Future<void> loadCourses() async {
    _setState(CourseLoadState.loading);
    try {
      _courses = await _service.fetchCourses();
      _errorMessage = null;
      _setState(CourseLoadState.loaded);
    } on CourseApiException catch (e) {
      _failWith(e.message);
    } catch (e) {
      _failWith('Unexpected error: $e');
    }
  }

  // -- Create --------------------------------------------------------------

  /// Returns `null` on success or a user-facing error message on failure.
  Future<String?> addCourse({
    required String title,
    required String description,
  }) async {
    try {
      final created = await _service.createCourse(
        CourseModel(title: title, description: description),
      );
      // JSONPlaceholder always returns id=101 for new resources; assign a
      // locally-unique id so the UI can distinguish multiple added items.
      final localId = created.id ?? _nextLocalId();
      _courses = [
        created.copyWith(id: localId),
        ..._courses,
      ];
      notifyListeners();
      return null;
    } on CourseApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Unexpected error: $e';
    }
  }

  // -- Update --------------------------------------------------------------

  Future<String?> updateCourse(CourseModel course) async {
    if (course.id == null) {
      return 'Cannot update a course without an id.';
    }
    try {
      // JSONPlaceholder echoes the payload back; trust the local edit so
      // the UI updates even for ids the fake API does not recognise.
      await _service.updateCourse(course);
      _courses = _courses
          .map((c) => c.id == course.id ? course : c)
          .toList(growable: false);
      notifyListeners();
      return null;
    } on CourseApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Unexpected error: $e';
    }
  }

  // -- Delete --------------------------------------------------------------

  Future<String?> deleteCourse(int id) async {
    try {
      await _service.deleteCourse(id);
      _courses =
          _courses.where((c) => c.id != id).toList(growable: false);
      notifyListeners();
      return null;
    } on CourseApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Unexpected error: $e';
    }
  }

  // -- Helpers -------------------------------------------------------------

  CourseModel? courseById(int? id) {
    if (id == null) return null;
    for (final c in _courses) {
      if (c.id == id) return c;
    }
    return null;
  }

  int _nextLocalId() {
    var max = 100;
    for (final c in _courses) {
      final id = c.id;
      if (id != null && id > max) max = id;
    }
    return max + 1;
  }

  void _setState(CourseLoadState newState) {
    _state = newState;
    notifyListeners();
  }

  void _failWith(String message) {
    _errorMessage = message;
    _setState(CourseLoadState.error);
  }
}

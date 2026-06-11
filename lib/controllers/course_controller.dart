import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/course_model.dart';
import '../repositories/course_repository.dart';
import '../services/course_api_service.dart';

/// Lifecycle of a view that owns network-backed data.
enum CourseLoadState { idle, loading, loaded, error }

/// Exposed to the UI via [Provider]. Owns the in-memory courses list,
/// drives all CRUD through [CourseRepository] and implements optimistic
/// update / delete with rollback on failure.
class CourseController extends ChangeNotifier {
  CourseController({required CourseRepository repository})
      : _repository = repository {
    // Auto-refresh when the device transitions from offline → online.
    _connectivitySub = _repository.onConnectivityChange.listen((online) {
      _isOffline = !online;
      if (online && _state == CourseLoadState.loaded) {
        loadCourses();
      } else {
        notifyListeners();
      }
    });
  }

  final CourseRepository _repository;
  StreamSubscription<bool>? _connectivitySub;

  CourseLoadState _state = CourseLoadState.idle;
  CourseLoadState get state => _state;

  List<CourseModel> _courses = const [];
  List<CourseModel> get courses => List.unmodifiable(_courses);

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  CourseDataSource _lastSource = CourseDataSource.network;
  CourseDataSource get lastSource => _lastSource;

  DateTime? _lastUpdated;
  DateTime? get lastUpdated => _lastUpdated;

  bool _isOffline = false;
  bool get isOffline => _isOffline;

  bool _fellBackToCache = false;
  bool get fellBackToCache => _fellBackToCache;

  // -- Read ----------------------------------------------------------------

  Future<void> loadCourses() async {
    _setState(CourseLoadState.loading);
    try {
      final result = await _repository.loadCourses();
      _courses = result.courses;
      _lastSource = result.source;
      _lastUpdated = result.lastUpdated;
      _fellBackToCache = result.fellBackToCache;
      _isOffline = result.source == CourseDataSource.cache;
      _errorMessage = null;
      _setState(CourseLoadState.loaded);
    } catch (e) {
      _failWith('Failed to load courses: $e');
    }
  }

  // -- Create --------------------------------------------------------------

  /// Returns `null` on success or a user-facing error message on failure.
  Future<String?> addCourse({
    required String title,
    required String description,
  }) async {
    final draft = CourseModel(title: title, description: description);
    try {
      final created = await _repository.createCourse(draft);
      // JSONPlaceholder always returns id=101 for new resources; pick the
      // next unused local id so multiple adds remain distinguishable.
      final localId = _isUnusedId(created.id) ? created.id! : _nextLocalId();
      final stored = created.copyWith(id: localId);
      await _repository.cacheUpsert(stored);
      _courses = [stored, ..._courses];
      notifyListeners();
      return null;
    } on CourseApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Unexpected error: $e';
    }
  }

  // -- Update (optimistic) -------------------------------------------------

  Future<String?> updateCourse(CourseModel course) async {
    final id = course.id;
    if (id == null) return 'Cannot update a course without an id.';

    final index = _courses.indexWhere((c) => c.id == id);
    if (index == -1) return 'Course not found in the current list.';

    final previous = _courses[index];

    // Optimistic write — UI updates before the network call returns.
    _courses = List<CourseModel>.from(_courses)..[index] = course;
    notifyListeners();

    try {
      await _repository.updateCourse(course);
      return null;
    } on CourseApiException catch (e) {
      _rollbackAt(index, previous);
      return 'Update failed: ${e.message}';
    } catch (e) {
      _rollbackAt(index, previous);
      return 'Unexpected error: $e';
    }
  }

  // -- Delete (optimistic) -------------------------------------------------

  Future<String?> deleteCourse(int id) async {
    final index = _courses.indexWhere((c) => c.id == id);
    if (index == -1) return 'Course not found in the current list.';

    final removed = _courses[index];

    // Optimistic remove.
    _courses = List<CourseModel>.from(_courses)..removeAt(index);
    notifyListeners();

    try {
      await _repository.deleteCourse(id);
      return null;
    } on CourseApiException catch (e) {
      _rollbackInsert(index, removed);
      return 'Delete failed: ${e.message}';
    } catch (e) {
      _rollbackInsert(index, removed);
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

  bool _isUnusedId(int? id) {
    if (id == null) return false;
    return !_courses.any((c) => c.id == id);
  }

  int _nextLocalId() {
    var max = 100;
    for (final c in _courses) {
      final id = c.id;
      if (id != null && id > max) max = id;
    }
    return max + 1;
  }

  void _rollbackAt(int index, CourseModel previous) {
    final list = List<CourseModel>.from(_courses);
    if (index < list.length) {
      list[index] = previous;
    } else {
      list.add(previous);
    }
    _courses = list;
    notifyListeners();
  }

  void _rollbackInsert(int index, CourseModel removed) {
    final list = List<CourseModel>.from(_courses);
    final clamped = index.clamp(0, list.length);
    list.insert(clamped, removed);
    _courses = list;
    notifyListeners();
  }

  void _setState(CourseLoadState newState) {
    _state = newState;
    notifyListeners();
  }

  void _failWith(String message) {
    _errorMessage = message;
    _setState(CourseLoadState.error);
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }
}

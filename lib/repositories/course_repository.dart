import '../models/course_model.dart';
import '../services/connectivity_service.dart';
import '../services/course_api_service.dart';
import '../services/course_local_storage.dart';

/// Source of the data returned by [CourseRepository.loadCourses].
enum CourseDataSource { network, cache }

class CourseLoadResult {
  const CourseLoadResult({
    required this.courses,
    required this.source,
    this.lastUpdated,
    this.fellBackToCache = false,
  });

  final List<CourseModel> courses;
  final CourseDataSource source;
  final DateTime? lastUpdated;

  /// `true` if the network was attempted and failed, so [courses] are from
  /// the cache. UI uses this to show a "you're offline" hint.
  final bool fellBackToCache;
}

/// Single source of truth for course data.
///
/// Sits between [CourseController] (state-management layer) and the raw
/// [CourseApiService] / [CourseLocalStorage]. It is the only class that
/// decides whether a request goes to the network, the cache, or both.
class CourseRepository {
  CourseRepository({
    required CourseApiService api,
    required CourseLocalStorage local,
    required ConnectivityService connectivity,
  })  : _api = api,
        _local = local,
        _connectivity = connectivity;

  final CourseApiService _api;
  final CourseLocalStorage _local;
  final ConnectivityService _connectivity;

  Stream<bool> get onConnectivityChange => _connectivity.onStatusChange;

  Future<bool> isOnline() => _connectivity.isOnline();

  // -- Read ----------------------------------------------------------------

  /// Loads the course list. When online we fetch the API and refresh the
  /// cache; when offline (or the network fails) we return whatever's in the
  /// cache.
  Future<CourseLoadResult> loadCourses() async {
    final online = await _connectivity.isOnline();

    if (!online) {
      return CourseLoadResult(
        courses: _local.readAll(),
        source: CourseDataSource.cache,
        lastUpdated: _local.lastUpdated,
      );
    }

    try {
      final fresh = await _api.fetchCourses();
      await _local.replaceAll(fresh);
      return CourseLoadResult(
        courses: fresh,
        source: CourseDataSource.network,
        lastUpdated: _local.lastUpdated,
      );
    } on CourseApiException {
      return CourseLoadResult(
        courses: _local.readAll(),
        source: CourseDataSource.cache,
        lastUpdated: _local.lastUpdated,
        fellBackToCache: true,
      );
    }
  }

  // -- Mutations -----------------------------------------------------------

  Future<CourseModel> createCourse(CourseModel draft) async {
    final created = await _api.createCourse(draft);
    await _local.upsert(created);
    return created;
  }

  Future<CourseModel> updateCourse(CourseModel course) async {
    final updated = await _api.updateCourse(course);
    // JSONPlaceholder echoes payload; trust the caller's edit so the cache
    // reflects what the user actually typed.
    await _local.upsert(course);
    return updated;
  }

  Future<void> deleteCourse(int id) async {
    await _api.deleteCourse(id);
    await _local.remove(id);
  }

  // -- Cache helpers -------------------------------------------------------

  /// Used by optimistic update / delete flows. Lets the controller persist
  /// (or roll back) a mutation in the cache after a UI-first edit.
  Future<void> cacheUpsert(CourseModel course) => _local.upsert(course);
  Future<void> cacheRemove(int id) => _local.remove(id);
}

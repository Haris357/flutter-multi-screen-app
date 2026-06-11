import 'package:hive_flutter/hive_flutter.dart';

import '../models/course_model.dart';

/// Hive-backed cache for the courses list.
///
/// Stores each course as a plain `Map<String, dynamic>` (no Hive code-gen
/// needed) keyed by its id. A separate `_metaBox` keeps a single key —
/// `lastUpdated` — so the UI can show "last synced" hints.
class CourseLocalStorage {
  CourseLocalStorage._(this._coursesBox, this._metaBox);

  static const String _coursesBoxName = 'courses_cache';
  static const String _metaBoxName = 'courses_meta';
  static const String _lastUpdatedKey = 'lastUpdated';

  final Box<Map> _coursesBox;
  final Box _metaBox;

  /// Opens (or returns) the Hive boxes used by the cache.
  ///
  /// Must be called after `Hive.initFlutter()` in `main.dart`.
  static Future<CourseLocalStorage> open() async {
    final coursesBox = await Hive.openBox<Map>(_coursesBoxName);
    final metaBox = await Hive.openBox(_metaBoxName);
    return CourseLocalStorage._(coursesBox, metaBox);
  }

  // -- Read ----------------------------------------------------------------

  List<CourseModel> readAll() {
    final entries = _coursesBox.values
        .map((m) => CourseModel.fromJson(Map<String, dynamic>.from(m)))
        .toList();
    // Higher id first (newer courses appear at the top of the list).
    entries.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
    return entries;
  }

  DateTime? get lastUpdated {
    final raw = _metaBox.get(_lastUpdatedKey);
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  // -- Write ---------------------------------------------------------------

  /// Replaces the entire cache with [courses] and updates the timestamp.
  Future<void> replaceAll(List<CourseModel> courses) async {
    await _coursesBox.clear();
    final entries = <dynamic, Map>{
      for (final c in courses)
        if (c.id != null) c.id!: c.toJson(),
    };
    await _coursesBox.putAll(entries);
    await _metaBox.put(_lastUpdatedKey, DateTime.now().toIso8601String());
  }

  Future<void> upsert(CourseModel course) async {
    final id = course.id;
    if (id == null) return;
    await _coursesBox.put(id, course.toJson());
  }

  Future<void> remove(int id) => _coursesBox.delete(id);

  Future<void> clear() async {
    await _coursesBox.clear();
    await _metaBox.delete(_lastUpdatedKey);
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/course_model.dart';

/// Thrown when the REST API returns a non-2xx response or the request fails.
class CourseApiException implements Exception {
  CourseApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'CourseApiException: $message';
}

/// Thin wrapper around the JSONPlaceholder `/posts` endpoint.
///
/// Treats each "post" as a course (see [CourseModel] for the field mapping).
/// All UI code talks to this service through [CourseController] — it never
/// imports `package:http` directly.
class CourseApiService {
  CourseApiService({http.Client? client, Duration? timeout})
      : _client = client ?? http.Client(),
        _timeout = timeout ?? const Duration(seconds: 15);

  static const String _baseUrl = 'https://jsonplaceholder.typicode.com';
  static const String _resource = '/posts';

  final http.Client _client;
  final Duration _timeout;

  Uri _uri([Object? id]) =>
      Uri.parse('$_baseUrl$_resource${id == null ? '' : '/$id'}');

  static const _jsonHeaders = {
    'Content-Type': 'application/json; charset=UTF-8',
  };

  // -- Read ----------------------------------------------------------------

  Future<List<CourseModel>> fetchCourses() async {
    final response = await _send(() => _client.get(_uri()));
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((e) => CourseModel.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<CourseModel> fetchCourse(int id) async {
    final response = await _send(() => _client.get(_uri(id)));
    return CourseModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  // -- Create --------------------------------------------------------------

  Future<CourseModel> createCourse(CourseModel course) async {
    final response = await _send(
      () => _client.post(
        _uri(),
        headers: _jsonHeaders,
        body: jsonEncode(course.toJson()..remove('id')),
      ),
    );
    return CourseModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  // -- Update --------------------------------------------------------------

  Future<CourseModel> updateCourse(CourseModel course) async {
    final id = course.id;
    if (id == null) {
      throw CourseApiException('Cannot update a course without an id.');
    }
    final response = await _send(
      () => _client.put(
        _uri(id),
        headers: _jsonHeaders,
        body: jsonEncode(course.toJson()),
      ),
    );
    return CourseModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  // -- Delete --------------------------------------------------------------

  Future<void> deleteCourse(int id) async {
    await _send(() => _client.delete(_uri(id)));
  }

  // -- Internals -----------------------------------------------------------

  Future<http.Response> _send(
    Future<http.Response> Function() request,
  ) async {
    http.Response response;
    try {
      response = await request().timeout(_timeout);
    } on TimeoutException {
      throw CourseApiException('Request timed out. Check your connection.');
    } catch (e) {
      throw CourseApiException('Network error: $e');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CourseApiException(
        'Server returned ${response.statusCode}.',
        statusCode: response.statusCode,
      );
    }
    return response;
  }

  void dispose() => _client.close();
}

/// Immutable representation of a course.
///
/// Backed by the JSONPlaceholder `/posts` endpoint:
///   * `id`     → server-assigned course id
///   * `title`  → course title
///   * `body`   → course description
///   * `userId` → owning user (defaults to `1` for this demo)
class CourseModel {
  const CourseModel({
    this.id,
    required this.title,
    required this.description,
    this.userId = 1,
  });

  /// `null` for courses that have not yet been persisted on the server.
  final int? id;
  final String title;
  final String description;
  final int userId;

  CourseModel copyWith({
    int? id,
    String? title,
    String? description,
    int? userId,
  }) {
    return CourseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      userId: userId ?? this.userId,
    );
  }

  /// Body sent on POST / PUT / PATCH requests.
  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'title': title,
        'body': description,
        'userId': userId,
      };

  factory CourseModel.fromJson(Map<String, dynamic> json) => CourseModel(
        id: (json['id'] as num?)?.toInt(),
        title: (json['title'] ?? '') as String,
        description: (json['body'] ?? '') as String,
        userId: (json['userId'] as num?)?.toInt() ?? 1,
      );
}

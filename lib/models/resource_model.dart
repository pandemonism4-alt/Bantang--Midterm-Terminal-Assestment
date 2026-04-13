class ResourceModel {
  final int id;
  final int userId;
  final String title;
  final bool completed;

  const ResourceModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.completed,
  });

  /// Parses a single JSON map into a [ResourceModel].
  factory ResourceModel.fromJson(Map<String, dynamic> json) {
    return ResourceModel(
      id: json['id'] as int,
      userId: json['userId'] as int,
      title: json['title'] as String,
      completed: json['completed'] as bool,
    );
  }

  /// Parses a JSON list into a list of [ResourceModel]s.
  static List<ResourceModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((item) => ResourceModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  String toString() =>
      'ResourceModel(id: $id, title: $title, completed: $completed)';
}
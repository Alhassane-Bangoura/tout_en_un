class ActivityModel {
  final String id;
  final String title;
  final String type;
  final String? resultSummary;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  ActivityModel({
    required this.id,
    required this.title,
    required this.type,
    this.resultSummary,
    this.metadata,
    required this.createdAt,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'] as String,
      title: json['title'] as String,
      type: json['type'] as String,
      resultSummary: json['result_summary'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'result_summary': resultSummary,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ScreenModel {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime lastModified;
  final String content; // JSON string of components

  ScreenModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.lastModified,
    this.content = '[]',
  });

  factory ScreenModel.fromJson(Map<String, dynamic> json) {
    return ScreenModel(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastModified: DateTime.parse(json['lastModified'] as String),
      content: json['content'] as String? ?? '[]',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
      'content': content,
    };
  }

  ScreenModel copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? lastModified,
    String? content,
  }) {
    return ScreenModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      content: content ?? this.content,
    );
  }
}

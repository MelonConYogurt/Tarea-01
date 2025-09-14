class Note {
  final int? id;
  final String? remoteKey;
  final String userId;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Note({this.id, this.remoteKey, required this.userId, required this.title, required this.content, required this.createdAt, this.updatedAt});


  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as int?,
      remoteKey: json['remoteKey'] as String?,
      userId: (json['userId'] ?? '') as String,
      title: json['title'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
  'userId': userId,
  'remoteKey': remoteKey,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

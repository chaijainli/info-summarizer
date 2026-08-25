class InfoRecord {
  final int? id;
  final String title;
  final String content;
  final String summary;
  final String category;
  final String createdAt;
  final String updatedAt;

  InfoRecord({
    this.id,
    required this.title,
    required this.content,
    required this.summary,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'summary': summary,
      'category': category,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory InfoRecord.fromMap(Map<String, dynamic> map) {
    return InfoRecord(
      id: map['id'],
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      summary: map['summary'] ?? '',
      category: map['category'] ?? '其他',
      createdAt: map['created_at'] ?? '',
      updatedAt: map['updated_at'] ?? '',
    );
  }
}
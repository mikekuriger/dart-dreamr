class Dream {
  final int id;
  final int userId;
  final String text;
  final String analysis;
  final String summary;
  final String tone;
  final bool hidden;
  final String? imageFile;
  final DateTime createdAt;

  Dream({
    required this.id,
    required this.userId,
    required this.text,
    required this.analysis,
    required this.summary,
    required this.tone,
    required this.hidden,
    required this.createdAt,
    this.imageFile,
  });

  factory Dream.fromJson(Map<String, dynamic> json) {
    return Dream(
      id: json['id'],
      userId: json['user_id'],
      text: json['text'] ?? '',
      analysis: json['analysis'] ?? '',
      summary: json['summary'] ?? '',
      tone: json['tone'] ?? '',
      hidden: json['hidden'] ?? false,
      imageFile: json['image_file'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}



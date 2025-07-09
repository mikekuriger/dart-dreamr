import 'package:dreamr/constants.dart';

class Dream {
  final int id;
  final int userId;
  final String text;
  final String analysis;
  final String summary;
  final String tone;
  final String imagePrompt;
  final bool hidden;
  final DateTime createdAt;
  final String? imageFile;
  final String? imageTile;

  Dream({
    required this.id,
    required this.userId,
    required this.text,
    required this.analysis,
    required this.summary,
    required this.tone,
    required this.imagePrompt,
    required this.hidden,
    required this.createdAt,
    this.imageFile,
    this.imageTile,
  });

  factory Dream.fromJson(Map<String, dynamic> json) {
    return Dream(
      id: json['id'] ?? 0,
      userId: int.tryParse(json['user_id'].toString()) ?? 0,
      text: json['text'] ?? '',
      analysis: json['analysis'] ?? '',
      summary: json['summary'] ?? '',
      tone: json['tone'] ?? '',
      imagePrompt: json['image_prompt'] ?? '',
      hidden: json['hidden'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      imageFile: json['image_file'] != null
        ? '${AppConfig.baseUrl}${json['image_file']}'
        : null,
      imageTile: json['image_tile'] != null
        ? '${AppConfig.baseUrl}${json['image_tile']}'
        : null,
    );
  }
}



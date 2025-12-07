import 'chapter.dart';

class Thesis {
  final String id;
  final String topic;
  final List<Chapter> chapters;
  final String writingStyle;
  final int targetLength;
  final String format;
  final List<String> references;

  Thesis({
    required this.id,
    required this.topic,
    required this.chapters,
    required this.writingStyle,
    required this.targetLength,
    required this.format,
    this.references = const [],
  });

  factory Thesis.fromJson(Map<String, dynamic> json) {
    List<Chapter> chaptersList = [];

    // Handle both List and Map chapter structures
    final chaptersData = json['chapters'];
    if (chaptersData is List) {
      // Old format: chapters is a List
      chaptersList = chaptersData
          .map((chapter) => Chapter.fromJson(chapter as Map<String, dynamic>))
          .toList();
    } else if (chaptersData is Map<String, dynamic>) {
      // New format: chapters is a Map with numeric keys
      final sortedKeys = chaptersData.keys
          .where((key) => int.tryParse(key) != null)
          .toList()
        ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

      chaptersList = sortedKeys
          .map((key) =>
              Chapter.fromJson(chaptersData[key] as Map<String, dynamic>))
          .toList();
    }

    return Thesis(
      id: json['id'] as String,
      topic: json['topic'] as String,
      chapters: chaptersList,
      writingStyle: json['writingStyle'] as String,
      targetLength: json['targetLength'] as int,
      format: json['format'] as String,
      references: (json['references'] as List?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'topic': topic,
        'chapters': chapters.map((c) => c.toJson()).toList(),
        'writingStyle': writingStyle,
        'targetLength': targetLength,
        'format': format,
        'references': references,
      };

  Thesis copyWith({
    String? id,
    String? topic,
    List<Chapter>? chapters,
    String? writingStyle,
    int? targetLength,
    String? format,
    List<String>? references,
  }) {
    return Thesis(
      id: id ?? this.id,
      topic: topic ?? this.topic,
      chapters: chapters ?? this.chapters,
      writingStyle: writingStyle ?? this.writingStyle,
      targetLength: targetLength ?? this.targetLength,
      format: format ?? this.format,
      references: references ?? this.references,
    );
  }
}

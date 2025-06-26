class Chapter {
  final String title;
  final String content;
  final List<String> subheadings;
  final Map<String, String> subheadingContents;

  Chapter({
    required this.title,
    required this.content,
    required this.subheadings,
    Map<String, String>? subheadingContents,
  }) : subheadingContents = subheadingContents ?? {};

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      title: json['title'] as String,
      content: json['content'] as String,
      subheadings: List<String>.from(json['subheadings'] as List),
      subheadingContents: Map<String, String>.from(json['subheadingContents'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'content': content,
    'subheadings': subheadings,
    'subheadingContents': subheadingContents,
  };

  Chapter copyWith({
    String? title,
    String? content,
    List<String>? subheadings,
    Map<String, String>? subheadingContents,
  }) {
    return Chapter(
      title: title ?? this.title,
      content: content ?? this.content,
      subheadings: subheadings ?? this.subheadings,
      subheadingContents: subheadingContents ?? this.subheadingContents,
    );
  }
}

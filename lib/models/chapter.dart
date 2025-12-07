class Chapter {
  final String title;
  final String content;
  final List<String> subheadings;
  final Map<String, String> subheadingContents;

  // New fields for tables and graphs (chapter-level - for backward compatibility)
  final Map<String, dynamic>? tableData;
  final Map<String, dynamic>? graphData;
  final String? tableCaption;
  final String? graphCaption;

  // New fields for subheading-level tables and graphs
  final Map<String, Map<String, dynamic>>? subheadingTables;
  final Map<String, Map<String, dynamic>>? subheadingGraphs;
  final Map<String, String>? subheadingTableCaptions;
  final Map<String, String>? subheadingGraphCaptions;

  Chapter({
    required this.title,
    required this.content,
    required this.subheadings,
    Map<String, String>? subheadingContents,
    this.tableData,
    this.graphData,
    this.tableCaption,
    this.graphCaption,
    this.subheadingTables,
    this.subheadingGraphs,
    this.subheadingTableCaptions,
    this.subheadingGraphCaptions,
  }) : subheadingContents = subheadingContents ?? {};

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      title: json['title'] as String,
      content: json['content'] as String,
      subheadings: List<String>.from(json['subheadings'] as List),
      subheadingContents:
          Map<String, String>.from(json['subheadingContents'] ?? {}),
      tableData: json['tableData'] as Map<String, dynamic>?,
      graphData: json['graphData'] as Map<String, dynamic>?,
      tableCaption: json['tableCaption'] as String?,
      graphCaption: json['graphCaption'] as String?,
      subheadingTables: json['subheadingTables'] != null
          ? Map<String, Map<String, dynamic>>.from(
              (json['subheadingTables'] as Map).map((key, value) =>
                  MapEntry(key.toString(), Map<String, dynamic>.from(value))))
          : null,
      subheadingGraphs: json['subheadingGraphs'] != null
          ? Map<String, Map<String, dynamic>>.from(
              (json['subheadingGraphs'] as Map).map((key, value) =>
                  MapEntry(key.toString(), Map<String, dynamic>.from(value))))
          : null,
      subheadingTableCaptions: json['subheadingTableCaptions'] != null
          ? Map<String, String>.from(json['subheadingTableCaptions'])
          : null,
      subheadingGraphCaptions: json['subheadingGraphCaptions'] != null
          ? Map<String, String>.from(json['subheadingGraphCaptions'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
        'subheadings': subheadings,
        'subheadingContents': subheadingContents,
        'tableData': tableData,
        'graphData': graphData,
        'tableCaption': tableCaption,
        'graphCaption': graphCaption,
        'subheadingTables': subheadingTables,
        'subheadingGraphs': subheadingGraphs,
        'subheadingTableCaptions': subheadingTableCaptions,
        'subheadingGraphCaptions': subheadingGraphCaptions,
      };

  Chapter copyWith({
    String? title,
    String? content,
    List<String>? subheadings,
    Map<String, String>? subheadingContents,
    Map<String, dynamic>? tableData,
    Map<String, dynamic>? graphData,
    String? tableCaption,
    String? graphCaption,
    Map<String, Map<String, dynamic>>? subheadingTables,
    Map<String, Map<String, dynamic>>? subheadingGraphs,
    Map<String, String>? subheadingTableCaptions,
    Map<String, String>? subheadingGraphCaptions,
  }) {
    return Chapter(
      title: title ?? this.title,
      content: content ?? this.content,
      subheadings: subheadings ?? this.subheadings,
      subheadingContents: subheadingContents ?? this.subheadingContents,
      tableData: tableData ?? this.tableData,
      graphData: graphData ?? this.graphData,
      tableCaption: tableCaption ?? this.tableCaption,
      graphCaption: graphCaption ?? this.graphCaption,
      subheadingTables: subheadingTables ?? this.subheadingTables,
      subheadingGraphs: subheadingGraphs ?? this.subheadingGraphs,
      subheadingTableCaptions:
          subheadingTableCaptions ?? this.subheadingTableCaptions,
      subheadingGraphCaptions:
          subheadingGraphCaptions ?? this.subheadingGraphCaptions,
    );
  }
}

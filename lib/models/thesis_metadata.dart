class ThesisMetadata {
  final String id;
  final String userId;
  final String title;
  final String topic;
  final String studyLevel;
  final String language;
  final String? subject;
  final String? institution;
  final int? pages;
  final List<String> chapters;
  final Map<String, dynamic> settings;
  final double progressPercentage;
  final String status; // 'draft', 'in_progress', 'completed', 'exported'
  final DateTime createdAt;
  final DateTime lastUpdated;
  final DateTime? completedAt;
  final int wordCount;
  final bool isSaved;

  ThesisMetadata({
    required this.id,
    required this.userId,
    required this.title,
    required this.topic,
    required this.studyLevel,
    required this.language,
    this.subject,
    this.institution,
    this.pages,
    this.chapters = const [],
    this.settings = const {},
    this.progressPercentage = 0.0,
    this.status = 'draft',
    required this.createdAt,
    required this.lastUpdated,
    this.completedAt,
    this.wordCount = 0,
    this.isSaved = false,
  });

  factory ThesisMetadata.fromFirestore(Map<String, dynamic> data, String id) {
    return ThesisMetadata(
      id: id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      topic: data['topic'] ?? '',
      studyLevel: data['studyLevel'] ?? '',
      language: data['language'] ?? '',
      subject: data['subject'],
      institution: data['institution'],
      pages: data['pages']?.toInt(),
      chapters: List<String>.from(data['chapters'] ?? []),
      settings: Map<String, dynamic>.from(data['settings'] ?? {}),
      progressPercentage: (data['progressPercentage'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'draft',
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      lastUpdated: data['lastUpdated']?.toDate() ?? DateTime.now(),
      completedAt: data['completedAt']?.toDate(),
      wordCount: data['wordCount']?.toInt() ?? 0,
      isSaved: data['isSaved'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'topic': topic,
      'studyLevel': studyLevel,
      'language': language,
      'subject': subject,
      'institution': institution,
      'pages': pages,
      'chapters': chapters,
      'settings': settings,
      'progressPercentage': progressPercentage,
      'status': status,
      'createdAt': createdAt,
      'lastUpdated': lastUpdated,
      'completedAt': completedAt,
      'wordCount': wordCount,
      'isSaved': isSaved,
    };
  }

  ThesisMetadata copyWith({
    String? id,
    String? userId,
    String? title,
    String? topic,
    String? studyLevel,
    String? language,
    String? subject,
    String? institution,
    int? pages,
    List<String>? chapters,
    Map<String, dynamic>? settings,
    double? progressPercentage,
    String? status,
    DateTime? createdAt,
    DateTime? lastUpdated,
    DateTime? completedAt,
    int? wordCount,
    bool? isSaved,
  }) {
    return ThesisMetadata(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      topic: topic ?? this.topic,
      studyLevel: studyLevel ?? this.studyLevel,
      language: language ?? this.language,
      subject: subject ?? this.subject,
      institution: institution ?? this.institution,
      pages: pages ?? this.pages,
      chapters: chapters ?? this.chapters,
      settings: settings ?? this.settings,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      completedAt: completedAt ?? this.completedAt,
      wordCount: wordCount ?? this.wordCount,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  // Helper getters
  bool get isCompleted => status == 'completed';
  bool get isInProgress => status == 'in_progress';
  bool get isDraft => status == 'draft';

  String get statusDisplay {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'in_progress':
        return 'In Progress';
      case 'exported':
        return 'Exported';
      default:
        return 'Draft';
    }
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${lastUpdated.day}/${lastUpdated.month}/${lastUpdated.year}';
    }
  }

  String get estimatedReadTime {
    if (wordCount == 0) return '0 min';
    final minutes = (wordCount / 200).ceil(); // Average reading speed
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = (minutes / 60).floor();
      final remainingMinutes = minutes % 60;
      return remainingMinutes > 0
          ? '${hours}h ${remainingMinutes}m'
          : '${hours}h';
    }
  }

  double get completionScore {
    double score = 0.0;

    // Progress weight (50%)
    score += progressPercentage * 0.5;

    // Chapter completion weight (30%)
    if (chapters.isNotEmpty) {
      score += (chapters.length / 8.0).clamp(0.0, 1.0) * 30.0;
    }

    // Word count weight (20%)
    if (wordCount > 0) {
      final targetWords = (pages ?? 50) * 250; // Rough estimate
      score += (wordCount / targetWords).clamp(0.0, 1.0) * 20.0;
    }

    return score.clamp(0.0, 100.0);
  }
}

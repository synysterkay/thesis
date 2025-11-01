import 'package:cloud_firestore/cloud_firestore.dart';

class HumanizedThesis {
  final String id;
  final String userId;
  final String originalFileName;
  final String humanizedFileName;
  final DateTime createdAt;
  final int originalWordCount;
  final int humanizedWordCount;
  final int processingTimeSeconds;
  final String status; // 'processing', 'completed', 'failed'
  final String? downloadUrl;
  final Map<String, dynamic>? metadata;

  HumanizedThesis({
    required this.id,
    required this.userId,
    required this.originalFileName,
    required this.humanizedFileName,
    required this.createdAt,
    required this.originalWordCount,
    required this.humanizedWordCount,
    required this.processingTimeSeconds,
    required this.status,
    this.downloadUrl,
    this.metadata,
  });

  // Create from Firestore document
  factory HumanizedThesis.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HumanizedThesis(
      id: doc.id,
      userId: data['userId'] ?? '',
      originalFileName: data['originalFileName'] ?? '',
      humanizedFileName: data['humanizedFileName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      originalWordCount: data['originalWordCount'] ?? 0,
      humanizedWordCount: data['humanizedWordCount'] ?? 0,
      processingTimeSeconds: data['processingTimeSeconds'] ?? 0,
      status: data['status'] ?? 'completed',
      downloadUrl: data['downloadUrl'],
      metadata: data['metadata'],
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'originalFileName': originalFileName,
      'humanizedFileName': humanizedFileName,
      'createdAt': Timestamp.fromDate(createdAt),
      'originalWordCount': originalWordCount,
      'humanizedWordCount': humanizedWordCount,
      'processingTimeSeconds': processingTimeSeconds,
      'status': status,
      'downloadUrl': downloadUrl,
      'metadata': metadata,
    };
  }

  // Copy with method for updates
  HumanizedThesis copyWith({
    String? id,
    String? userId,
    String? originalFileName,
    String? humanizedFileName,
    DateTime? createdAt,
    int? originalWordCount,
    int? humanizedWordCount,
    int? processingTimeSeconds,
    String? status,
    String? downloadUrl,
    Map<String, dynamic>? metadata,
  }) {
    return HumanizedThesis(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      originalFileName: originalFileName ?? this.originalFileName,
      humanizedFileName: humanizedFileName ?? this.humanizedFileName,
      createdAt: createdAt ?? this.createdAt,
      originalWordCount: originalWordCount ?? this.originalWordCount,
      humanizedWordCount: humanizedWordCount ?? this.humanizedWordCount,
      processingTimeSeconds:
          processingTimeSeconds ?? this.processingTimeSeconds,
      status: status ?? this.status,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'HumanizedThesis(id: $id, originalFileName: $originalFileName, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HumanizedThesis && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

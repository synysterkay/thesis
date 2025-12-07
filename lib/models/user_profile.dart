class UserProfile {
  final String id;
  final String email;
  final String name;
  final String studyLevel;
  final String language;
  final String? institution;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final Map<String, dynamic> preferences;

  UserProfile({
    required this.id,
    required this.email,
    required this.name,
    required this.studyLevel,
    required this.language,
    this.institution,
    this.avatarUrl,
    required this.createdAt,
    required this.lastUpdated,
    this.preferences = const {},
  });

  factory UserProfile.fromFirestore(Map<String, dynamic> data, String id) {
    return UserProfile(
      id: id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      studyLevel: data['studyLevel'] ?? 'Undergraduate',
      language: data['language'] ?? 'English',
      institution: data['institution'],
      avatarUrl: data['avatarUrl'],
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      lastUpdated: data['lastUpdated']?.toDate() ?? DateTime.now(),
      preferences: Map<String, dynamic>.from(data['preferences'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'studyLevel': studyLevel,
      'language': language,
      'institution': institution,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt,
      'lastUpdated': lastUpdated,
      'preferences': preferences,
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? name,
    String? studyLevel,
    String? language,
    String? institution,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? lastUpdated,
    Map<String, dynamic>? preferences,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      studyLevel: studyLevel ?? this.studyLevel,
      language: language ?? this.language,
      institution: institution ?? this.institution,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      preferences: preferences ?? this.preferences,
    );
  }

  // Helper getters
  String get displayName => name.isNotEmpty ? name : email.split('@').first;

  String get initials {
    if (name.isNotEmpty) {
      final parts = name.split(' ');
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      } else {
        return parts.first.substring(0, 1).toUpperCase();
      }
    }
    return email.substring(0, 1).toUpperCase();
  }
}

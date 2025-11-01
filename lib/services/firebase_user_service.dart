import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_profile.dart';
import '../models/thesis_metadata.dart';
import '../models/thesis.dart';
import '../models/chapter.dart';

class FirebaseUserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseUserService _instance = FirebaseUserService._internal();

  FirebaseUserService._internal();

  static FirebaseUserService get instance => _instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // User Profile Methods

  /// Get current user's profile
  Future<UserProfile?> getUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        return UserProfile.fromFirestore(doc.data()!, user.uid);
      } else {
        // Create default profile if doesn't exist
        final defaultProfile = UserProfile(
          id: user.uid,
          email: user.email ?? '',
          name: user.displayName ?? '',
          studyLevel: 'Undergraduate',
          language: 'English',
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );
        await updateUserProfile(defaultProfile);
        return defaultProfile;
      }
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore.collection('users').doc(user.uid).set({
        ...profile.toFirestore(),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  /// Delete user account and all associated data
  Future<void> deleteUserAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Delete user data from Firestore
      await _deleteUserData(user.uid);

      // Delete Firebase Auth account
      await user.delete();
    } catch (e) {
      print('Error deleting user account: $e');
      rethrow;
    }
  }

  /// Delete all user data from Firestore
  Future<void> _deleteUserData(String userId) async {
    final batch = _firestore.batch();

    // Delete user profile
    batch.delete(_firestore.collection('users').doc(userId));

    // Delete user's theses
    final thesesQuery = await _firestore
        .collection('theses')
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in thesesQuery.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // Thesis History Methods

  /// Save thesis metadata to Firebase
  Future<void> saveThesisMetadata(ThesisMetadata metadata) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore.collection('theses').doc(metadata.id).set({
        ...metadata.toFirestore(),
        'userId': user.uid,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving thesis metadata: $e');
      rethrow;
    }
  }

  /// Generate a sequential thesis name like "Thesis 1", "Thesis 2", etc.
  Future<String> _generateSequentialThesisName(String userId) async {
    try {
      final existingTheses = await getUserTheses(userId);

      // Extract numbers from existing thesis names
      Set<int> usedNumbers = {};

      for (final thesis in existingTheses) {
        final title = thesis.title.toLowerCase();
        if (title.startsWith('thesis ')) {
          final numberPart = title.substring(7).trim();
          final number = int.tryParse(numberPart);
          if (number != null) {
            usedNumbers.add(number);
          }
        }
      }

      // Find the next available number
      int nextNumber = 1;
      while (usedNumbers.contains(nextNumber)) {
        nextNumber++;
      }

      return 'Thesis $nextNumber';
    } catch (e) {
      print('Error generating sequential thesis name: $e');
      return 'Thesis 1'; // Fallback
    }
  }

  /// Generate a proper title from topic
  String _generateTitleFromTopic(String topic) {
    if (topic.isEmpty) return 'Untitled Thesis';

    // Clean up the topic and make it title-like
    String title = topic.trim();

    // If it's already well-formatted (starts with capital, reasonable length), use it
    if (title.length <= 100 && title[0] == title[0].toUpperCase()) {
      return title;
    }

    // Otherwise, clean it up
    title = title.split(' ').map((word) {
      if (word.isEmpty) return word;
      // Capitalize first letter of each significant word
      if (word.toLowerCase() == 'of' ||
          word.toLowerCase() == 'the' ||
          word.toLowerCase() == 'and' ||
          word.toLowerCase() == 'in' ||
          word.toLowerCase() == 'on' ||
          word.toLowerCase() == 'for' ||
          word.toLowerCase() == 'with') {
        return word.toLowerCase();
      }
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');

    // Ensure it starts with capital letter
    if (title.isNotEmpty) {
      title = title[0].toUpperCase() + title.substring(1);
    }

    return title.length > 100 ? title.substring(0, 97) + '...' : title;
  }

  /// Save complete thesis data (simplified version)
  Future<void> saveThesis(
      String thesisId, Map<String, dynamic> thesisData, String userId) async {
    try {
      final topic = thesisData['topic'] ?? '';
      final generatedTitle = await _generateSequentialThesisName(userId);

      // Save thesis metadata
      final metadata = ThesisMetadata(
        id: thesisId,
        userId: userId,
        title: generatedTitle,
        topic: topic,
        studyLevel: 'Undergraduate', // Default for now
        language: 'English', // Default for now
        chapters: (thesisData['chapters'] as List?)
                ?.map((c) => c['title'] ?? '')
                .cast<String>()
                .toList() ??
            [],
        progressPercentage: 50.0, // Default progress
        status: 'in_progress',
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
        wordCount: _calculateWordCountFromData(thesisData),
        isSaved: true,
      );
      await saveThesisMetadata(metadata);

      // Save complete thesis data
      await _firestore.collection('thesis_data').doc(thesisId).set({
        ...thesisData,
        'userId': userId,
        'savedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving thesis: $e');
      rethrow;
    }
  }

  /// Calculate word count from thesis data
  int _calculateWordCountFromData(Map<String, dynamic> thesisData) {
    int wordCount = 0;
    if (thesisData['chapters'] is List) {
      for (var chapter in thesisData['chapters']) {
        if (chapter is Map && chapter['content'] is String) {
          wordCount += (chapter['content'] as String).split(' ').length;
        }
      }
    }
    return wordCount;
  }

  /// Get user's thesis history
  Stream<List<ThesisMetadata>> getUserThesesStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('theses')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .handleError((error) {
      print('Error in getUserThesesStream: $error');
    }).map((snapshot) {
      try {
        final theses = snapshot.docs
            .map((doc) => ThesisMetadata.fromFirestore(doc.data(), doc.id))
            .toList();

        // Sort manually to avoid Firestore indexing issues
        theses.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));

        return theses;
      } catch (e) {
        print('Error parsing thesis metadata: $e');
        return <ThesisMetadata>[];
      }
    });
  }

  /// Get user theses
  Future<List<ThesisMetadata>> getUserTheses(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('theses')
          .where('userId', isEqualTo: userId)
          .get();

      final theses = querySnapshot.docs
          .map((doc) => ThesisMetadata.fromFirestore(doc.data(), doc.id))
          .toList();

      // Sort manually to avoid Firestore indexing issues
      theses.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));

      // Check for theses with empty titles and fix them
      await _migrateEmptyTitles(theses);

      return theses;
    } catch (e) {
      print('Error getting user theses: $e');
      return [];
    }
  }

  /// Migrate theses with empty titles
  Future<void> _migrateEmptyTitles(List<ThesisMetadata> theses) async {
    for (final thesis in theses) {
      if (thesis.title.isEmpty && thesis.topic.isNotEmpty) {
        try {
          final newTitle = _generateTitleFromTopic(thesis.topic);
          final updatedMetadata = thesis.copyWith(
            title: newTitle,
            lastUpdated: DateTime.now(),
          );
          await saveThesisMetadata(updatedMetadata);
          print('✅ Updated title for thesis ${thesis.id}: "$newTitle"');
        } catch (e) {
          print('⚠️ Failed to update title for thesis ${thesis.id}: $e');
        }
      }
    }
  }

  /// Get complete thesis data
  Future<Thesis?> getThesis(String thesisId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // First try Firebase
      final doc =
          await _firestore.collection('thesis_data').doc(thesisId).get();

      if (doc.exists) {
        final data = doc.data()!;
        // Verify ownership
        if (data['userId'] != user.uid) {
          throw Exception('Access denied');
        }

        // DEBUG: Print the raw Firebase data to understand the structure
        print('DEBUG Firebase data keys: ${data.keys.toList()}');
        if (data.containsKey('chapters')) {
          final chaptersData = data['chapters'];
          print('DEBUG Firebase chapters type: ${chaptersData.runtimeType}');

          if (chaptersData is List) {
            final chapters = chaptersData;
            print('DEBUG Firebase chapters count: ${chapters.length}');
            for (int i = 0; i < chapters.length; i++) {
              final chapter = chapters[i] as Map<String, dynamic>;
              print('DEBUG Firebase chapter $i keys: ${chapter.keys.toList()}');
              if (chapter.containsKey('subheadingContents')) {
                final subheadingContents = chapter['subheadingContents'] as Map;
                print(
                    'DEBUG Firebase chapter $i subheadingContents keys: ${subheadingContents.keys.toList()}');
                print(
                    'DEBUG Firebase chapter $i subheadingContents values lengths: ${subheadingContents.values.map((v) => v.toString().length).toList()}');
              }
            }
          } else {
            print(
                'DEBUG Firebase chapters is not a List, it is: ${chaptersData.runtimeType}');
            print('DEBUG Firebase chapters content: $chaptersData');
          }
        }

        final firebaseThesis = Thesis.fromJson(data);

        // Check if Firebase thesis has content, if not, try to merge with local
        final hasFirebaseContent = _thesisHasContent(firebaseThesis);

        if (!hasFirebaseContent) {
          print(
              'DEBUG: Firebase thesis has no content, checking local storage for content...');
          final localThesis = await _getThesisFromLocal(thesisId);

          if (localThesis != null && _thesisHasContent(localThesis)) {
            print(
                'DEBUG: Found content in local storage, merging with Firebase structure...');
            final mergedThesis =
                _mergeThesisContent(firebaseThesis, localThesis);

            // Save merged thesis back to local storage
            await _saveThesisLocally(thesisId, mergedThesis);

            return mergedThesis;
          }
        }

        // Save to local storage as backup
        await _saveThesisLocally(thesisId, firebaseThesis);

        return firebaseThesis;
      } else {
        // If not found in Firebase, try local storage
        print(
            'DEBUG: thesis_data not found in Firebase for $thesisId, checking local storage...');
        return await _getThesisFromLocal(thesisId);
      }
    } catch (e) {
      print('Error getting thesis: $e');
      // Try local storage as last resort
      return await _getThesisFromLocal(thesisId);
    }
  }

  /// Delete thesis
  Future<void> deleteThesis(String thesisId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final batch = _firestore.batch();

      // Delete metadata
      batch.delete(_firestore.collection('theses').doc(thesisId));

      // Delete thesis data
      batch.delete(_firestore.collection('thesis_data').doc(thesisId));

      await batch.commit();
    } catch (e) {
      print('Error deleting thesis: $e');
      rethrow;
    }
  }

  /// Update thesis metadata (progress, status, etc.)
  Future<void> updateThesisMetadata(
      String thesisId, Map<String, dynamic> updates) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      print(
          'DEBUG: Updating thesis metadata for $thesisId with updates: $updates');

      // Use set with merge to create document if it doesn't exist
      await _firestore.collection('theses').doc(thesisId).set({
        'userId': user.uid,
        'id': thesisId,
        ...updates,
        'lastModified': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('DEBUG: ✅ Thesis metadata updated successfully for $thesisId');
    } catch (e) {
      print('DEBUG: ❌ Error updating thesis metadata for $thesisId: $e');
      rethrow;
    }
  }

  /// Get user statistics
  Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final thesesSnapshot = await _firestore
          .collection('theses')
          .where('userId', isEqualTo: user.uid)
          .get();

      int totalTheses = thesesSnapshot.docs.length;
      int completedTheses = 0;
      int totalWordCount = 0;

      for (final doc in thesesSnapshot.docs) {
        final data = doc.data();
        if (data['status'] == 'completed') {
          completedTheses++;
        }
        totalWordCount += (data['wordCount'] as int? ?? 0);
      }

      return {
        'totalTheses': totalTheses,
        'completedTheses': completedTheses,
        'inProgressTheses': totalTheses - completedTheses,
        'totalWordCount': totalWordCount,
        'averageWordCount': totalTheses > 0 ? totalWordCount / totalTheses : 0,
      };
    } catch (e) {
      print('Error getting user statistics: $e');
      return {};
    }
  }

  // Local Storage Methods

  /// Save thesis to local storage as backup
  Future<void> _saveThesisLocally(String thesisId, Thesis thesis) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final thesisJson = jsonEncode(thesis.toJson());
      await prefs.setString('thesis_$thesisId', thesisJson);
      print('✅ Thesis saved locally: $thesisId');
    } catch (e) {
      print('⚠️ Failed to save thesis locally: $e');
    }
  }

  /// Get thesis from local storage
  Future<Thesis?> _getThesisFromLocal(String thesisId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final thesisJson = prefs.getString('thesis_$thesisId');

      if (thesisJson != null) {
        final thesisData = jsonDecode(thesisJson) as Map<String, dynamic>;
        print('✅ Thesis found in local storage: $thesisId');
        return Thesis.fromJson(thesisData);
      }

      print('❌ Thesis not found in local storage: $thesisId');
      return null;
    } catch (e) {
      print('⚠️ Failed to get thesis from local storage: $e');
      return null;
    }
  }

  /// Rename thesis
  Future<void> renameThesis(String thesisId, String newTitle) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Update thesis metadata
      await updateThesisMetadata(thesisId, {
        'title': newTitle,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      print('✅ Thesis renamed: $thesisId -> "$newTitle"');
    } catch (e) {
      print('❌ Error renaming thesis: $e');
      rethrow;
    }
  }

  /// Save thesis to both Firebase and local storage
  Future<void> saveThesisWithBackup(Thesis thesis) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Generate sequential title if not already set
      String thesisTitle = thesis.topic;
      if (thesisTitle.isEmpty || thesisTitle == 'Untitled Thesis') {
        thesisTitle = await _generateSequentialThesisName(user.uid);
      }

      // Create or update thesis metadata
      final metadata = ThesisMetadata(
        id: thesis.id,
        userId: user.uid,
        title: thesisTitle,
        topic: thesis.topic,
        studyLevel: 'Undergraduate', // Default
        language: 'English', // Default
        chapters: thesis.chapters.map((c) => c.title).toList(),
        progressPercentage: 0.0,
        status: 'draft',
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
        wordCount: _calculateWordCountFromThesis(thesis),
        isSaved: true,
      );

      await saveThesisMetadata(metadata);

      // Save to Firebase
      await _firestore.collection('thesis_data').doc(thesis.id).set({
        ...thesis.toJson(),
        'userId': user.uid,
        'title': thesisTitle,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Save to local storage as backup
      await _saveThesisLocally(thesis.id, thesis);

      print(
          '✅ Thesis saved to both Firebase and local storage: ${thesis.id} - "$thesisTitle"');
    } catch (e) {
      print('❌ Error saving thesis with backup: $e');
      rethrow;
    }
  }

  /// Calculate word count from thesis object
  int _calculateWordCountFromThesis(Thesis thesis) {
    int wordCount = 0;
    for (var chapter in thesis.chapters) {
      if (chapter.content.isNotEmpty) {
        wordCount += chapter.content.split(' ').length;
      }
      for (var content in chapter.subheadingContents.values) {
        if (content.isNotEmpty) {
          wordCount += content.split(' ').length;
        }
      }
    }
    return wordCount;
  }

  /// Clear local thesis storage
  Future<void> clearLocalThesisStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('thesis_'));

      for (final key in keys) {
        await prefs.remove(key);
      }

      print('✅ Local thesis storage cleared');
    } catch (e) {
      print('⚠️ Failed to clear local thesis storage: $e');
    }
  }

  /// Check if a thesis has any generated content
  bool _thesisHasContent(Thesis thesis) {
    for (final chapter in thesis.chapters) {
      // Check if chapter has main content
      if (chapter.content.isNotEmpty) {
        return true;
      }

      // Check if chapter has any subheading content
      for (final content in chapter.subheadingContents.values) {
        if (content.isNotEmpty) {
          return true;
        }
      }
    }
    return false;
  }

  /// Merge content from local thesis into Firebase thesis structure
  Thesis _mergeThesisContent(Thesis firebaseThesis, Thesis localThesis) {
    final updatedChapters = <Chapter>[];

    for (int i = 0; i < firebaseThesis.chapters.length; i++) {
      final firebaseChapter = firebaseThesis.chapters[i];

      // Try to find corresponding chapter in local thesis
      Chapter? localChapter;
      if (i < localThesis.chapters.length) {
        localChapter = localThesis.chapters[i];
      }

      if (localChapter != null) {
        // Merge the content, preferring local content if it exists
        final mergedChapter = firebaseChapter.copyWith(
            content: localChapter.content.isNotEmpty
                ? localChapter.content
                : firebaseChapter.content,
            subheadingContents: {
              ...firebaseChapter.subheadingContents,
              ...localChapter
                  .subheadingContents, // Local content takes precedence
            });
        updatedChapters.add(mergedChapter);
      } else {
        updatedChapters.add(firebaseChapter);
      }
    }

    return firebaseThesis.copyWith(chapters: updatedChapters);
  }
}

// Global service instance
final firebaseUserService = FirebaseUserService.instance;

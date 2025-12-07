import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/thesis.dart';
import '../services/deepseek_service.dart';
import '../services/firebase_user_service.dart';
import '../services/local_notification_service.dart';
import '../services/onesignal_service.dart';

/// Service for handling thesis generation in the background
class BackgroundGenerationService {
  static final BackgroundGenerationService _instance =
      BackgroundGenerationService._internal();
  static BackgroundGenerationService get instance => _instance;
  BackgroundGenerationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DeepSeekService _deepseekService = DeepSeekService();
  final Map<String, StreamSubscription> _activeGenerations = {};
  final Random _random = Random();

  // Track visual counts per chapter for professional distribution
  final Map<String, Map<String, int>> _chapterVisualCounts = {};

  // Maximum visuals per chapter for professional appearance
  static const int _maxTablesPerChapter = 2;
  static const int _maxGraphsPerChapter = 2;

  /// Determines if a chapter should contain tables or graphs
  bool _shouldChapterHaveVisuals(String chapterTitle) {
    final title = chapterTitle.toLowerCase().trim();
    return !(title.contains('introduction') ||
        title.contains('conclusion') ||
        title.contains('references') ||
        title.contains('bibliography') ||
        title.contains('abstract') ||
        title.contains('acknowledgment') ||
        title.contains('preface') ||
        title.contains('foreword'));
  }

  /// Initialize visual counts for a chapter
  void _initializeChapterVisualCounts(String chapterKey) {
    if (!_chapterVisualCounts.containsKey(chapterKey)) {
      _chapterVisualCounts[chapterKey] = {
        'tables': 0,
        'graphs': 0,
      };
    }
  }

  /// Check if we can add more tables to this chapter
  bool _canAddTableToChapter(String chapterKey) {
    _initializeChapterVisualCounts(chapterKey);
    return _chapterVisualCounts[chapterKey]!['tables']! < _maxTablesPerChapter;
  }

  /// Check if we can add more graphs to this chapter
  bool _canAddGraphToChapter(String chapterKey) {
    _initializeChapterVisualCounts(chapterKey);
    return _chapterVisualCounts[chapterKey]!['graphs']! < _maxGraphsPerChapter;
  }

  /// Increment table count for a chapter
  void _incrementTableCount(String chapterKey) {
    _initializeChapterVisualCounts(chapterKey);
    _chapterVisualCounts[chapterKey]!['tables'] =
        _chapterVisualCounts[chapterKey]!['tables']! + 1;
  }

  /// Increment graph count for a chapter
  void _incrementGraphCount(String chapterKey) {
    _initializeChapterVisualCounts(chapterKey);
    _chapterVisualCounts[chapterKey]!['graphs'] =
        _chapterVisualCounts[chapterKey]!['graphs']! + 1;
  }

  /// Clean up orphaned generation jobs on service initialization
  Future<void> cleanupOrphanedJobs() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      print('DEBUG: Cleaning up orphaned generation jobs...');

      // Find jobs that are stuck in processing or queued state for more than 1 hour
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));

      final querySnapshot = await _firestore
          .collection('generation_jobs')
          .where('userId', isEqualTo: user.uid)
          .where('status', whereIn: ['queued', 'processing']).get();

      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          final startedAt = (data['startedAt'] as Timestamp?)?.toDate();

          if (startedAt != null && startedAt.isBefore(oneHourAgo)) {
            print('DEBUG: Cleaning up orphaned job: ${doc.id}');

            // Mark as failed due to timeout
            await doc.reference.set({
              'status': 'failed',
              'error': 'Job orphaned - cleaned up on app restart',
              'failedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }
        } catch (e) {
          print('Warning: Failed to cleanup job ${doc.id}: $e');
          // Continue with other jobs
        }
      }

      print('DEBUG: Orphaned job cleanup completed');
    } catch (e) {
      print('Warning: Orphaned job cleanup failed: $e');
      // Don't throw - this is just cleanup
    }
  }

  /// Start background generation for a thesis
  Future<String> startBackgroundGeneration(Thesis thesis) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    print('DEBUG: Starting background generation for user: ${user.uid}');
    print('DEBUG: Thesis ID: ${thesis.id}');

    try {
      // Create generation job in Firestore
      final generationJob = await _firestore.collection('generation_jobs').add({
        'userId': user.uid,
        'thesisId': thesis.id,
        'status': 'queued',
        'progress': 0.0,
        'currentStep': 'Preparing generation...',
        'totalSections': _calculateTotalSections(thesis),
        'completedSections': 0,
        'startedAt': FieldValue.serverTimestamp(),
        'estimatedDuration': _estimateGenerationTime(thesis),
        'queuePosition': 1, // Simplified for now
      });

      print(
          'DEBUG: Generation job created successfully with ID: ${generationJob.id}');

      // Save initial thesis structure to both Firebase and local storage
      try {
        await FirebaseUserService.instance.saveThesisWithBackup(thesis);
        print(
            'DEBUG: Initial thesis structure saved to Firebase and local storage');
      } catch (e) {
        print('WARNING: Failed to save initial thesis structure: $e');
      }

      // Optionally update thesis metadata to show it's being generated
      try {
        await FirebaseUserService.instance.updateThesisMetadata(thesis.id, {
          'status': 'generating',
          'generationJobId': generationJob.id,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        print('DEBUG: Thesis metadata updated successfully');
      } catch (e) {
        print(
            'WARNING: Failed to update thesis metadata (continuing anyway): $e');
        // Continue with generation even if metadata update fails
      }

      // Start the generation process
      _processGenerationJob(generationJob.id, thesis);

      return generationJob.id;
    } catch (e) {
      print('ERROR: Failed to create generation job: $e');
      rethrow;
    }
  }

  /// Process a generation job
  Future<void> _processGenerationJob(String jobId, Thesis thesis) async {
    try {
      // Reset visual counts for this new thesis
      _chapterVisualCounts.clear();
      print('DEBUG: Reset visual counts for new thesis generation');

      // Update job status to processing
      await _safeUpdateJob(jobId, {
        'status': 'processing',
        'startedProcessingAt': FieldValue.serverTimestamp(),
      });

      int totalSections = _calculateTotalSections(thesis);
      int completedSections = 0;
      List<String> failedSections = [];

      // Process each chapter
      for (var i = 0; i < thesis.chapters.length; i++) {
        final chapter = thesis.chapters[i];

        // Skip References chapter
        if (chapter.title.toLowerCase().contains('references')) {
          continue;
        }

        if (_isSpecialChapter(chapter.title)) {
          await _updateJobProgress(
            jobId,
            currentStep: 'Generating ${chapter.title}...',
            progress: (completedSections / totalSections * 100),
            completedSections: completedSections,
          );

          await _generateSpecialChapterContent(chapter, i, thesis);
          completedSections++;

          // Update progress after completing the special chapter
          await _updateJobProgress(
            jobId,
            currentStep: 'Completed: ${chapter.title}',
            progress: (completedSections / totalSections * 100),
            completedSections: completedSections,
          );
        } else {
          // Generate content for each subheading
          for (var sectionIndex = 0;
              sectionIndex < chapter.subheadings.length;
              sectionIndex++) {
            final subheading = chapter.subheadings[sectionIndex];

            await _updateJobProgress(
              jobId,
              currentStep:
                  'Generating Section ${sectionIndex + 1} of ${chapter.subheadings.length}: $subheading',
              progress: (completedSections / totalSections * 100),
              completedSections: completedSections,
            );

            try {
              await _generateSectionContent(thesis, i, subheading);
              completedSections++;

              // Update progress after completing the section
              await _updateJobProgress(
                jobId,
                currentStep: 'Completed: $subheading',
                progress: (completedSections / totalSections * 100),
                completedSections: completedSections,
              );
            } catch (e) {
              print('Error generating section $subheading: $e');
              failedSections.add(subheading);
              completedSections++; // Still count as processed

              // Update progress even for failed sections
              await _updateJobProgress(
                jobId,
                currentStep: 'Failed: $subheading - continuing...',
                progress: (completedSections / totalSections * 100),
                completedSections: completedSections,
              );
            }

            // Add delay to prevent rate limiting
            await Future.delayed(Duration(seconds: 2));
          }
        }
      }

      // Mark job as completed
      await _safeUpdateJob(jobId, {
        'status': 'completed',
        'progress': 100.0,
        'currentStep': 'Generation completed!',
        'completedAt': FieldValue.serverTimestamp(),
        'completedSections': completedSections,
        'failedSections': failedSections,
      });

      print(
          'DEBUG: Updating thesis metadata to completed status for thesis: ${thesis.id}');
      // Update thesis metadata
      await FirebaseUserService.instance.updateThesisMetadata(thesis.id, {
        'status': 'completed',
        'progressPercentage': 100.0,
        'completedAt': FieldValue.serverTimestamp(),
        'generationJobId': null,
      });
      print(
          'DEBUG: ✅ Thesis metadata updated to completed status successfully');

      // Track thesis completion in OneSignal
      try {
        await OneSignalService().trackThesisCompleted(thesis.id);
        print('✅ OneSignal: Thesis completion tracked');
      } catch (e) {
        print('⚠️ Failed to track thesis completion in OneSignal: $e');
      }

      // Send completion notification
      await LocalNotificationService.showThesisGenerationComplete();
    } catch (e) {
      print('Error in generation job $jobId: $e');

      // Mark job as failed
      try {
        await _safeUpdateJob(jobId, {
          'status': 'failed',
          'error': e.toString(),
          'failedAt': FieldValue.serverTimestamp(),
        });
      } catch (updateError) {
        print('Warning: Failed to update failed job status: $updateError');
      }

      // Update thesis metadata
      try {
        await FirebaseUserService.instance.updateThesisMetadata(thesis.id, {
          'status': 'failed',
          'generationJobId': null,
        });
      } catch (metadataError) {
        print('Warning: Failed to update thesis metadata: $metadataError');
      }
    }
  }

  /// Update job progress in Firestore
  Future<void> _updateJobProgress(
    String jobId, {
    required String currentStep,
    required double progress,
    int? completedSections,
  }) async {
    try {
      final updateData = {
        'currentStep': currentStep,
        'progress': progress,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      if (completedSections != null) {
        updateData['completedSections'] = completedSections;
      }

      await _safeUpdateJob(jobId, updateData);
    } catch (e) {
      print('Warning: Failed to update job progress for $jobId: $e');
      // Don't throw error to avoid breaking the generation process
    }
  }

  /// Safely update a job document, creating it if it doesn't exist
  Future<void> _safeUpdateJob(String jobId, Map<String, dynamic> data) async {
    if (jobId.isEmpty) {
      print('Warning: Empty jobId provided to _safeUpdateJob');
      return;
    }

    try {
      final docRef = _firestore.collection('generation_jobs').doc(jobId);

      // Use transaction to ensure atomic update
      await _firestore.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(docRef);

        if (!docSnapshot.exists) {
          print('Warning: Job document $jobId does not exist, skipping update');
          return;
        }

        transaction.set(docRef, data, SetOptions(merge: true));
      });
    } catch (e) {
      if (e.toString().contains('not-found')) {
        print('Info: Job document $jobId was deleted, skipping update');
        return; // Don't throw for deleted documents
      }
      print('Error updating job $jobId: $e');
      // Don't rethrow to prevent crashing the generation process
    }
  }

  /// Generate content for a special chapter (Introduction/Conclusion)
  Future<void> _generateSpecialChapterContent(
      dynamic chapter, int chapterIndex, Thesis thesis) async {
    final content = await _deepseekService.generateChapterContent(
      thesis.topic,
      chapter.title,
      thesis.writingStyle,
    );

    if (content.isNotEmpty) {
      // Update the thesis with generated content
      await _updateThesisContent(
          thesis.id, chapterIndex, chapter.title, content);
    }
  }

  /// Generate content for a section
  Future<void> _generateSectionContent(
      Thesis thesis, int chapterIndex, String subheading) async {
    print('DEBUG: Starting content generation for subheading: "$subheading"');

    final content = await _deepseekService.generateChapterContent(
      thesis.topic,
      subheading,
      thesis.writingStyle,
    );

    print(
        'DEBUG: Generated content for "$subheading" - Length: ${content.length}');
    if (content.length > 100) {
      print('DEBUG: Content preview: ${content.substring(0, 100)}...');
    } else {
      print('DEBUG: Full content: $content');
    }

    if (content.isNotEmpty) {
      print('DEBUG: Updating Firebase for subheading: "$subheading"');

      // Generate table and graph data for eligible chapters/subheadings
      Map<String, dynamic>? tableData;
      Map<String, dynamic>? graphData;
      String? tableCaption;
      String? graphCaption;

      // Check if this chapter should have visual elements
      final chapterTitle = thesis.chapters[chapterIndex].title;
      final chapterKey = '${thesis.id}_chapter_$chapterIndex';

      if (_shouldChapterHaveVisuals(chapterTitle)) {
        // Check limits before generating - max 2 tables and 2 graphs per chapter
        final canAddTable = _canAddTableToChapter(chapterKey);
        final canAddGraph = _canAddGraphToChapter(chapterKey);

        // Only try to generate if we haven't reached the limits
        final shouldGenerateTable = canAddTable && _random.nextDouble() < 0.6;
        final shouldGenerateGraph = canAddGraph && _random.nextDouble() < 0.7;

        print(
            'DEBUG: Visual generation for "$subheading" - Table: $shouldGenerateTable (can add: $canAddTable), Graph: $shouldGenerateGraph (can add: $canAddGraph)');

        if (shouldGenerateTable) {
          try {
            print('DEBUG: Generating table for subheading "$subheading"...');
            tableData = await _deepseekService.generateTableDataForSubheading(
                thesis.topic, subheading, "General",
                chapterContent: content);
            if (tableData != null && tableData.containsKey('caption')) {
              tableCaption = tableData['caption'] as String?;
              _incrementTableCount(chapterKey); // Track that we added a table
              print('DEBUG: Table generated successfully for "$subheading"');
            }
          } catch (e) {
            print('DEBUG: Failed to generate table for "$subheading": $e');
          }
        }

        if (shouldGenerateGraph) {
          try {
            print('DEBUG: Generating graph for subheading "$subheading"...');
            graphData = await _deepseekService.generateGraphDataForSubheading(
                thesis.topic, subheading, "General",
                chapterContent: content);
            if (graphData != null && graphData.containsKey('caption')) {
              graphCaption = graphData['caption'] as String?;
              _incrementGraphCount(chapterKey); // Track that we added a graph
              print('DEBUG: Graph generated successfully for "$subheading"');
            }
          } catch (e) {
            print('DEBUG: Failed to generate graph for "$subheading": $e');
          }
        }

        // Debug: Show current chapter visual counts
        _initializeChapterVisualCounts(chapterKey);
        final currentCounts = _chapterVisualCounts[chapterKey]!;
        print(
            'DEBUG: Chapter visual counts - Tables: ${currentCounts['tables']}/$_maxTablesPerChapter, Graphs: ${currentCounts['graphs']}/$_maxGraphsPerChapter');
      } else {
        print('DEBUG: Skipping visuals for non-data chapter: "$chapterTitle"');
      }

      try {
        await _updateThesisSubheadingContentWithVisuals(
            thesis.id, chapterIndex, subheading, content,
            tableData: tableData,
            graphData: graphData,
            tableCaption: tableCaption,
            graphCaption: graphCaption);
        print('DEBUG: ✅ Successfully updated Firebase for "$subheading"');
      } catch (e) {
        print('DEBUG: ❌ Failed to update Firebase for "$subheading": $e');
        rethrow;
      }
    } else {
      print('DEBUG: ⚠️ Empty content generated for "$subheading"');
    }
  }

  /// Update thesis content in Firestore and local storage
  Future<void> _updateThesisContent(String thesisId, int chapterIndex,
      String chapterTitle, String content) async {
    print(
        'DEBUG: Updating dual storage - chapter content for "$chapterTitle", contentLength: ${content.length}');

    bool firebaseSuccess = false;
    bool localSuccess = false;

    // Try Firebase first
    try {
      await _firestore.collection('thesis_data').doc(thesisId).update({
        'chapters.$chapterIndex.content': content,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      print(
          'DEBUG: ✅ Firebase chapter content update successful for "$chapterTitle"');
      firebaseSuccess = true;
    } catch (e) {
      print(
          'DEBUG: ❌ Firebase chapter content update failed for "$chapterTitle": $e');
    }

    // Update local storage directly
    try {
      await _updateLocalThesisChapterContentDirect(
          thesisId, chapterIndex, content);
      print(
          'DEBUG: ✅ Local chapter content update successful for "$chapterTitle"');
      localSuccess = true;
    } catch (e) {
      print(
          'DEBUG: ❌ Local chapter content update failed for "$chapterTitle": $e');
    }

    // Ensure at least one storage method succeeded
    if (!firebaseSuccess && !localSuccess) {
      throw Exception(
          'Failed to save chapter content to both Firebase and local storage');
    } else if (!firebaseSuccess) {
      print(
          'DEBUG: ⚠️ Chapter content saved to local storage only for "$chapterTitle"');
    } else if (!localSuccess) {
      print(
          'DEBUG: ⚠️ Chapter content saved to Firebase only for "$chapterTitle"');
    } else {
      print(
          'DEBUG: ✅ Chapter content saved to both Firebase and local storage for "$chapterTitle"');
    }
  }

  /// Update local thesis chapter content directly
  Future<void> _updateLocalThesisChapterContentDirect(
      String thesisId, int chapterIndex, String content) async {
    final prefs = await SharedPreferences.getInstance();
    final thesisKey = 'thesis_$thesisId';

    // Get existing thesis from local storage
    final existingThesisJson = prefs.getString(thesisKey);
    if (existingThesisJson == null) {
      // If no local thesis exists, try to get it from Firebase first
      await _updateLocalThesisBackup(thesisId);
      return _updateLocalThesisChapterContentDirect(
          thesisId, chapterIndex, content);
    }

    // Parse existing thesis
    final thesisData = jsonDecode(existingThesisJson) as Map<String, dynamic>;

    // Update the chapter content
    final chapters = thesisData['chapters'] as List;
    if (chapterIndex < chapters.length) {
      final chapter = chapters[chapterIndex] as Map<String, dynamic>;
      chapter['content'] = content;

      // Update timestamp
      thesisData['lastUpdated'] = DateTime.now().toIso8601String();

      // Save back to local storage
      await prefs.setString(thesisKey, jsonEncode(thesisData));
    }
  }

  /// Update thesis subheading content in Firestore and local storage
  Future<void> _updateThesisSubheadingContent(String thesisId, int chapterIndex,
      String subheading, String content) async {
    print(
        'DEBUG: Updating dual storage - thesisId: $thesisId, chapterIndex: $chapterIndex, subheading: "$subheading", contentLength: ${content.length}');

    bool firebaseSuccess = false;
    bool localSuccess = false;

    // Try Firebase first
    try {
      await _firestore.collection('thesis_data').doc(thesisId).update({
        'chapters.$chapterIndex.subheadingContents.$subheading': content,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      print('DEBUG: ✅ Firebase update successful for "$subheading"');
      firebaseSuccess = true;
    } catch (e) {
      print('DEBUG: ❌ Firebase update failed for "$subheading": $e');
    }

    // Update local storage directly with the new content
    try {
      await _updateLocalThesisContentDirect(
          thesisId, chapterIndex, subheading, content);
      print('DEBUG: ✅ Local storage update successful for "$subheading"');
      localSuccess = true;
    } catch (e) {
      print('DEBUG: ❌ Local storage update failed for "$subheading": $e');
    }

    // Ensure at least one storage method succeeded
    if (!firebaseSuccess && !localSuccess) {
      throw Exception(
          'Failed to save content to both Firebase and local storage');
    } else if (!firebaseSuccess) {
      print('DEBUG: ⚠️ Content saved to local storage only for "$subheading"');
    } else if (!localSuccess) {
      print('DEBUG: ⚠️ Content saved to Firebase only for "$subheading"');
    } else {
      print(
          'DEBUG: ✅ Content saved to both Firebase and local storage for "$subheading"');
    }
  }

  /// Update local thesis content directly without fetching from Firebase
  Future<void> _updateLocalThesisContentDirect(String thesisId,
      int chapterIndex, String subheading, String content) async {
    final prefs = await SharedPreferences.getInstance();
    final thesisKey = 'thesis_$thesisId';

    // Get existing thesis from local storage
    final existingThesisJson = prefs.getString(thesisKey);
    if (existingThesisJson == null) {
      // If no local thesis exists, try to get it from Firebase first
      await _updateLocalThesisBackup(thesisId);
      return _updateLocalThesisContentDirect(
          thesisId, chapterIndex, subheading, content);
    }

    // Parse existing thesis
    final thesisData = jsonDecode(existingThesisJson) as Map<String, dynamic>;

    // Update the specific subheading content
    final chapters = thesisData['chapters'] as List;
    if (chapterIndex < chapters.length) {
      final chapter = chapters[chapterIndex] as Map<String, dynamic>;

      // Ensure subheadingContents exists
      if (!chapter.containsKey('subheadingContents')) {
        chapter['subheadingContents'] = <String, String>{};
      }

      // Update the specific subheading
      final subheadingContents =
          chapter['subheadingContents'] as Map<String, dynamic>;
      subheadingContents[subheading] = content;

      // Update timestamp
      thesisData['lastUpdated'] = DateTime.now().toIso8601String();

      // Save back to local storage
      await prefs.setString(thesisKey, jsonEncode(thesisData));
    }
  }

  /// Update thesis subheading content with visual elements in Firestore and local storage
  Future<void> _updateThesisSubheadingContentWithVisuals(
    String thesisId,
    int chapterIndex,
    String subheading,
    String content, {
    Map<String, dynamic>? tableData,
    Map<String, dynamic>? graphData,
    String? tableCaption,
    String? graphCaption,
  }) async {
    print(
        'DEBUG: Updating dual storage with visuals - thesisId: $thesisId, chapterIndex: $chapterIndex, subheading: "$subheading", contentLength: ${content.length}');

    bool firebaseSuccess = false;
    bool localSuccess = false;

    // Try Firebase first - use document fetch and replace to handle nested arrays
    try {
      final docRef = _firestore.collection('thesis_data').doc(thesisId);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        Map<String, dynamic> thesisData =
            docSnapshot.data() as Map<String, dynamic>;

        print(
            'DEBUG: Firebase document structure - chapters type: ${thesisData['chapters'].runtimeType}');

        // Handle both List<dynamic> and Map<String, dynamic> chapter structures
        dynamic chaptersData = thesisData['chapters'];
        Map<String, dynamic> chapters;

        if (chaptersData is List) {
          // Convert List to Map for consistent handling
          chapters = {};
          for (int i = 0; i < chaptersData.length; i++) {
            chapters[i.toString()] = chaptersData[i];
          }
        } else if (chaptersData is Map<String, dynamic>) {
          chapters = chaptersData;
        } else {
          // Initialize if null or invalid
          chapters = {};
        }

        // Ensure chapter at index exists
        String chapterKey = chapterIndex.toString();
        if (!chapters.containsKey(chapterKey)) {
          chapters[chapterKey] = {
            'title': '',
            'content': '',
            'subheadingContents': <String, String>{},
            'subheadingTables': <String, dynamic>{},
            'subheadingGraphs': <String, dynamic>{},
            'subheadingTableCaptions': <String, String>{},
            'subheadingGraphCaptions': <String, String>{},
          };
        }

        Map<String, dynamic> chapter =
            chapters[chapterKey] as Map<String, dynamic>;

        // Initialize maps if they don't exist with proper null checks
        if (chapter['subheadingContents'] == null) {
          chapter['subheadingContents'] = <String, String>{};
        }
        if (chapter['subheadingTables'] == null) {
          chapter['subheadingTables'] = <String, dynamic>{};
        }
        if (chapter['subheadingGraphs'] == null) {
          chapter['subheadingGraphs'] = <String, dynamic>{};
        }
        if (chapter['subheadingTableCaptions'] == null) {
          chapter['subheadingTableCaptions'] = <String, String>{};
        }
        if (chapter['subheadingGraphCaptions'] == null) {
          chapter['subheadingGraphCaptions'] = <String, String>{};
        }

        // Get the maps safely
        Map<String, dynamic> subheadingContents =
            chapter['subheadingContents'] as Map<String, dynamic>;
        Map<String, dynamic> subheadingTables =
            chapter['subheadingTables'] as Map<String, dynamic>;
        Map<String, dynamic> subheadingGraphs =
            chapter['subheadingGraphs'] as Map<String, dynamic>;
        Map<String, dynamic> subheadingTableCaptions =
            chapter['subheadingTableCaptions'] as Map<String, dynamic>;
        Map<String, dynamic> subheadingGraphCaptions =
            chapter['subheadingGraphCaptions'] as Map<String, dynamic>;

        // Update content
        subheadingContents[subheading] = content;

        // Add visual elements if they exist
        if (tableData != null) {
          // Convert table data to Firebase-compatible format (no nested arrays)
          Map<String, dynamic> firebaseTableData = {
            'caption': tableData['caption'],
            'columns': tableData['columns'], // List<String> is fine
          };

          // Convert rows (List<List<String>>) to an indexed map
          if (tableData['rows'] is List) {
            Map<String, List<String>> rowsMap = {};
            List<dynamic> rows = tableData['rows'] as List;
            for (int i = 0; i < rows.length; i++) {
              // Convert each cell value to string to avoid type errors
              rowsMap['row_$i'] =
                  (rows[i] as List).map((cell) => cell.toString()).toList();
            }
            firebaseTableData['rows'] = rowsMap;
          }

          subheadingTables[subheading] = firebaseTableData;
          if (tableCaption != null) {
            subheadingTableCaptions[subheading] = tableCaption;
          }
        }

        if (graphData != null) {
          // Convert graph data to Firebase-compatible format (ensure all values are serializable)
          Map<String, dynamic> firebaseGraphData = {
            'caption': graphData['caption']?.toString() ?? '',
            'type': graphData['type']?.toString() ?? '',
            'xlabel': graphData['xlabel']?.toString() ?? '',
            'ylabel': graphData['ylabel']?.toString() ?? '',
            'source': graphData['source']?.toString() ?? '',
          };

          // Convert labels to list of strings
          if (graphData['labels'] is List) {
            firebaseGraphData['labels'] = List<String>.from(
                (graphData['labels'] as List).map((e) => e.toString()));
          }

          // Convert data values to list of strings to avoid type errors
          if (graphData['data'] is List) {
            firebaseGraphData['data'] = List<String>.from(
                (graphData['data'] as List).map((e) => e.toString()));
          }

          subheadingGraphs[subheading] = firebaseGraphData;
          if (graphCaption != null) {
            subheadingGraphCaptions[subheading] = graphCaption;
          }
        }

        // Update the chapters back into thesisData
        thesisData['chapters'] = chapters;

        // Update timestamp
        thesisData['lastUpdated'] = FieldValue.serverTimestamp();

        print(
            'DEBUG: About to save Firebase document with chapters structure: ${chapters.keys}');

        // Save the entire document back
        await docRef.set(thesisData);
        print(
            'DEBUG: ✅ Firebase update with visuals successful for "$subheading"');
        firebaseSuccess = true;
      } else {
        print('DEBUG: ❌ Firebase document does not exist for thesis $thesisId');
      }
    } catch (e) {
      print(
          'DEBUG: ❌ Firebase update with visuals failed for "$subheading": $e');
    }

    // Update local storage directly with the new content and visuals
    try {
      await _updateLocalThesisContentDirectWithVisuals(
          thesisId, chapterIndex, subheading, content,
          tableData: tableData,
          graphData: graphData,
          tableCaption: tableCaption,
          graphCaption: graphCaption);
      print(
          'DEBUG: ✅ Local storage update with visuals successful for "$subheading"');
      localSuccess = true;
    } catch (e) {
      print(
          'DEBUG: ❌ Local storage update with visuals failed for "$subheading": $e');
    }

    // Ensure at least one storage method succeeded
    if (!firebaseSuccess && !localSuccess) {
      throw Exception(
          'Failed to save content with visuals to both Firebase and local storage');
    } else if (!firebaseSuccess) {
      print(
          'DEBUG: ⚠️ Content with visuals saved to local storage only for "$subheading"');
    } else if (!localSuccess) {
      print(
          'DEBUG: ⚠️ Content with visuals saved to Firebase only for "$subheading"');
    } else {
      print(
          'DEBUG: ✅ Content with visuals saved to both Firebase and local storage for "$subheading"');
    }
  }

  /// Update local thesis content directly with visual elements
  Future<void> _updateLocalThesisContentDirectWithVisuals(
    String thesisId,
    int chapterIndex,
    String subheading,
    String content, {
    Map<String, dynamic>? tableData,
    Map<String, dynamic>? graphData,
    String? tableCaption,
    String? graphCaption,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final thesisKey = 'thesis_$thesisId';

    // Get existing thesis from local storage
    final existingThesisJson = prefs.getString(thesisKey);
    if (existingThesisJson == null) {
      // If no local thesis exists, try to get it from Firebase first
      await _updateLocalThesisBackup(thesisId);
      return _updateLocalThesisContentDirectWithVisuals(
          thesisId, chapterIndex, subheading, content,
          tableData: tableData,
          graphData: graphData,
          tableCaption: tableCaption,
          graphCaption: graphCaption);
    }

    // Parse existing thesis
    Map<String, dynamic> thesisData;
    try {
      thesisData = jsonDecode(existingThesisJson) as Map<String, dynamic>;
    } catch (e) {
      print(
          'DEBUG: Failed to parse local thesis JSON, refreshing from Firebase: $e');
      await _updateLocalThesisBackup(thesisId);
      return;
    }

    // Ensure chapters list exists and is not null
    if (!thesisData.containsKey('chapters') || thesisData['chapters'] == null) {
      print(
          'DEBUG: No chapters found in local storage, refreshing from Firebase');
      await _updateLocalThesisBackup(thesisId);
      return;
    }

    // Update the specific subheading content
    final chapters = thesisData['chapters'] as List;
    if (chapterIndex < chapters.length) {
      final chapterData = chapters[chapterIndex];
      if (chapterData == null) {
        print('DEBUG: Chapter data is null at index $chapterIndex');
        await _updateLocalThesisBackup(thesisId);
        return;
      }

      final chapter = chapterData as Map<String, dynamic>;

      // Ensure all required maps exist with proper null checks
      if (!chapter.containsKey('subheadingContents') ||
          chapter['subheadingContents'] == null) {
        chapter['subheadingContents'] = <String, String>{};
      }

      // Update the specific subheading
      final subheadingContents =
          chapter['subheadingContents'] as Map<String, dynamic>;
      subheadingContents[subheading] = content;

      // Add visual elements if they exist
      if (tableData != null) {
        if (!chapter.containsKey('subheadingTables') ||
            chapter['subheadingTables'] == null) {
          chapter['subheadingTables'] = <String, dynamic>{};
        }
        final subheadingTables =
            chapter['subheadingTables'] as Map<String, dynamic>;

        // Convert table data to Firebase-compatible format (no nested arrays)
        Map<String, dynamic> firebaseTableData = {
          'caption': tableData['caption'],
          'columns': tableData['columns'], // List<String> is fine
        };

        // Convert rows (List<List<String>>) to an indexed map
        if (tableData['rows'] is List) {
          Map<String, List<String>> rowsMap = {};
          List<dynamic> rows = tableData['rows'] as List;
          for (int i = 0; i < rows.length; i++) {
            // Convert each cell value to string to avoid type errors
            rowsMap['row_$i'] =
                (rows[i] as List).map((cell) => cell.toString()).toList();
          }
          firebaseTableData['rows'] = rowsMap;
        }

        subheadingTables[subheading] = firebaseTableData;

        if (tableCaption != null) {
          if (!chapter.containsKey('subheadingTableCaptions') ||
              chapter['subheadingTableCaptions'] == null) {
            chapter['subheadingTableCaptions'] = <String, dynamic>{};
          }
          final subheadingTableCaptions =
              chapter['subheadingTableCaptions'] as Map<String, dynamic>;
          subheadingTableCaptions[subheading] = tableCaption;
        }
      }

      if (graphData != null) {
        if (!chapter.containsKey('subheadingGraphs') ||
            chapter['subheadingGraphs'] == null) {
          chapter['subheadingGraphs'] = <String, dynamic>{};
        }
        final subheadingGraphs =
            chapter['subheadingGraphs'] as Map<String, dynamic>;

        // Convert graph data to local storage-compatible format (ensure all values are serializable)
        Map<String, dynamic> localGraphData = {
          'caption': graphData['caption']?.toString() ?? '',
          'type': graphData['type']?.toString() ?? '',
          'xlabel': graphData['xlabel']?.toString() ?? '',
          'ylabel': graphData['ylabel']?.toString() ?? '',
          'source': graphData['source']?.toString() ?? '',
        };

        // Convert labels to list of strings
        if (graphData['labels'] is List) {
          localGraphData['labels'] = List<String>.from(
              (graphData['labels'] as List).map((e) => e.toString()));
        }

        // Convert data values to list of strings to avoid type errors
        if (graphData['data'] is List) {
          localGraphData['data'] = List<String>.from(
              (graphData['data'] as List).map((e) => e.toString()));
        }

        subheadingGraphs[subheading] = localGraphData;

        if (graphCaption != null) {
          if (!chapter.containsKey('subheadingGraphCaptions') ||
              chapter['subheadingGraphCaptions'] == null) {
            chapter['subheadingGraphCaptions'] = <String, dynamic>{};
          }
          final subheadingGraphCaptions =
              chapter['subheadingGraphCaptions'] as Map<String, dynamic>;
          subheadingGraphCaptions[subheading] = graphCaption;
        }
      }

      // Update timestamp
      thesisData['lastUpdated'] = DateTime.now().toIso8601String();

      // Save back to local storage
      await prefs.setString(thesisKey, jsonEncode(thesisData));
    }
  }

  /// Update local thesis backup after Firebase changes
  Future<void> _updateLocalThesisBackup(String thesisId) async {
    try {
      final thesis = await FirebaseUserService.instance.getThesis(thesisId);
      if (thesis != null) {
        // This will save to local storage as backup
        await FirebaseUserService.instance.saveThesisWithBackup(thesis);
      }
    } catch (e) {
      print('WARNING: Failed to update local thesis backup: $e');
    }
  }

  /// Get active generation jobs for current user
  Stream<List<GenerationJob>> getActiveGenerationJobs() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    print('DEBUG: Querying active generation jobs for user: ${user.uid}');

    return _firestore
        .collection('generation_jobs')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .handleError((error) {
      print('ERROR: Firestore stream error: $error');
      return <QueryDocumentSnapshot>[];
    }).map((snapshot) {
      print('DEBUG: Found ${snapshot.docs.length} total generation jobs');
      final jobs = snapshot.docs
          .map((doc) {
            try {
              final job = GenerationJob.fromFirestore(doc.data(), doc.id);
              print('DEBUG: Job ${doc.id}: ${job.status} - ${job.progress}%');
              return job;
            } catch (e) {
              print('ERROR: Failed to parse job ${doc.id}: $e');
              return null;
            }
          })
          .where((job) => job != null)
          .cast<GenerationJob>()
          .where((job) =>
              job.status == 'queued' ||
              job.status == 'processing') // Filter manually
          .toList();

      print('DEBUG: Filtered to ${jobs.length} active jobs');

      // Sort by startedAt manually to avoid index requirements
      jobs.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return jobs;
    });
  }

  /// Cancel a generation job
  Future<void> cancelGenerationJob(String jobId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Get the job details first
      final jobDoc =
          await _firestore.collection('generation_jobs').doc(jobId).get();
      if (!jobDoc.exists) {
        throw Exception('Generation job not found');
      }

      final jobData = jobDoc.data()!;
      final thesisId = jobData['thesisId'];

      // Update job status to cancelled
      await _safeUpdateJob(jobId, {
        'status': 'cancelled',
        'currentStep': 'Generation cancelled by user',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      // Update thesis metadata
      try {
        await FirebaseUserService.instance.updateThesisMetadata(thesisId, {
          'status': 'draft',
          'generationJobId': null,
        });
      } catch (e) {
        print('Warning: Could not update thesis metadata: $e');
      }

      // Clean up active generation tracking
      _activeGenerations[jobId]?.cancel();
      _activeGenerations.remove(jobId);

      print('DEBUG: Generation job $jobId cancelled successfully');
    } catch (e) {
      print('Error cancelling generation job: $e');
      throw Exception('Failed to cancel generation job: $e');
    }
  }

  /// Helper methods
  int _calculateTotalSections(Thesis thesis) {
    int total = 0;
    for (final chapter in thesis.chapters) {
      if (chapter.title.toLowerCase().contains('references')) continue;
      if (_isSpecialChapter(chapter.title)) {
        total += 1;
      } else {
        total += chapter.subheadings.length;
      }
    }
    return total;
  }

  bool _isSpecialChapter(String title) {
    return title.toLowerCase().contains('introduction') ||
        title.toLowerCase().contains('conclusion');
  }

  int _estimateGenerationTime(Thesis thesis) {
    // Estimate in minutes based on number of sections
    int sections = _calculateTotalSections(thesis);
    return (sections * 2).clamp(5, 60); // 2 minutes per section, min 5, max 60
  }

  /// Get all generation jobs for current user (for history display)
  Stream<List<GenerationJob>> getAllGenerationJobs() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('generation_jobs')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .handleError((error) {
      print('ERROR: Firestore stream error: $error');
      return <QueryDocumentSnapshot>[];
    }).map((snapshot) {
      final jobs = snapshot.docs
          .map((doc) {
            try {
              return GenerationJob.fromFirestore(doc.data(), doc.id);
            } catch (e) {
              print('ERROR: Failed to parse job ${doc.id}: $e');
              return null;
            }
          })
          .where((job) => job != null)
          .cast<GenerationJob>()
          .where((job) =>
              job.status == 'completed' ||
              job.status == 'cancelled' ||
              job.status == 'failed')
          .toList();

      // Sort by most recent first
      jobs.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return jobs.take(5).toList(); // Show only last 5 completed jobs
    });
  }

  /// Delete a completed or cancelled generation job
  Future<void> deleteGenerationJob(String jobId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Verify the job belongs to the current user
      final jobDoc =
          await _firestore.collection('generation_jobs').doc(jobId).get();
      if (!jobDoc.exists) {
        throw Exception('Generation job not found');
      }

      final jobData = jobDoc.data()!;
      if (jobData['userId'] != user.uid) {
        throw Exception('Unauthorized to delete this job');
      }

      // Only allow deletion of completed, cancelled, or failed jobs
      final status = jobData['status'];
      if (!['completed', 'cancelled', 'failed'].contains(status)) {
        throw Exception(
            'Cannot delete active generation job. Cancel it first.');
      }

      // Delete the job document
      await _firestore.collection('generation_jobs').doc(jobId).delete();

      print('DEBUG: Generation job $jobId deleted successfully');
    } catch (e) {
      print('Error deleting generation job: $e');
      throw Exception('Failed to delete generation job: $e');
    }
  }
}

/// Model for generation job
class GenerationJob {
  final String id;
  final String userId;
  final String thesisId;
  final String status;
  final double progress;
  final String currentStep;
  final int totalSections;
  final int completedSections;
  final DateTime startedAt;
  final int estimatedDuration;
  final int queuePosition;
  final List<String> failedSections;

  GenerationJob({
    required this.id,
    required this.userId,
    required this.thesisId,
    required this.status,
    required this.progress,
    required this.currentStep,
    required this.totalSections,
    required this.completedSections,
    required this.startedAt,
    required this.estimatedDuration,
    required this.queuePosition,
    required this.failedSections,
  });

  factory GenerationJob.fromFirestore(Map<String, dynamic> data, String id) {
    return GenerationJob(
      id: id,
      userId: data['userId'] ?? '',
      thesisId: data['thesisId'] ?? '',
      status: data['status'] ?? 'queued',
      progress: (data['progress'] ?? 0.0).toDouble(),
      currentStep: data['currentStep'] ?? '',
      totalSections: data['totalSections'] ?? 0,
      completedSections: data['completedSections'] ?? 0,
      startedAt: (data['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      estimatedDuration: data['estimatedDuration'] ?? 30,
      queuePosition: data['queuePosition'] ?? 1,
      failedSections: List<String>.from(data['failedSections'] ?? []),
    );
  }
}

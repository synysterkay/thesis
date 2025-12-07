import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/thesis.dart';
import '../services/deepseek_service.dart';
import '../services/export_service.dart';
import '../services/thesis_persistence_service.dart';
import '../services/firebase_user_service.dart';
import '../models/chapter.dart';
import 'dart:async';

final deepseekServiceProvider = Provider((ref) => DeepSeekService());
final exportServiceProvider = Provider((ref) => ExportService());
final thesisStateProvider =
    StateNotifierProvider<ThesisNotifier, AsyncValue<Thesis>>((ref) {
  return ThesisNotifier(ref.watch(deepseekServiceProvider));
});

class ThesisNotifier extends StateNotifier<AsyncValue<Thesis>> {
  final DeepSeekService _deepseekService;
  final Set<String> _generatedSections = {};
  final ThesisPersistenceService _persistenceService = thesisPersistenceService;
  Timer? _saveDebounceTimer;
  bool _hasUnsavedChanges = false;

  ThesisNotifier(this._deepseekService) : super(const AsyncValue.loading()) {
    _initializePersistence();
  }

  // Add these new methods
  bool isSubheadingGenerated(String chapterTitle, String subheading) {
    return _generatedSections.contains('$chapterTitle-$subheading');
  }

  void _markSubheadingGenerated(String chapterTitle, String subheading) {
    _generatedSections.add('$chapterTitle-$subheading');
    _markForSave();
  }

  Future<void> setChaptersWithOutlines(List<String> chapterTitles,
      Map<String, List<String>> chapterOutlines) async {
    final chapters = chapterTitles.map((title) {
      return Chapter(
        title: title,
        content: '',
        subheadings: chapterOutlines[title] ?? [],
        subheadingContents: {},
      );
    }).toList();

    final thesis = Thesis(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      topic: state.value?.topic ?? '',
      chapters: chapters,
      writingStyle: state.value?.writingStyle ?? 'Academic',
      targetLength: 5000,
      format: 'APA',
    );

    state = AsyncValue.data(thesis);
    _markForSave();
  }

  bool canAccessSubheading(
      String chapterTitle, List<String> subheadings, String currentSubheading) {
    int index = subheadings.indexOf(currentSubheading);
    if (index == 0) return true;
    return isSubheadingGenerated(chapterTitle, subheadings[index - 1]);
  }

  // New method for generating thesis structure with section headings only (no content)
  Future<void> generateThesisStructure(
    String topic,
    List<String> chapters,
    String style, {
    required Function(int index, String chapterTitle) onChapterStart,
    required Function(int index, String chapterTitle) onChapterComplete,
    required Function(int index, String chapterTitle, String error)
        onChapterError,
  }) async {
    state = const AsyncValue.loading();
    try {
      List<Chapter> generatedChapters = [];

      // Generate chapter outlines with section titles only
      final chapterOutlines =
          await _deepseekService.generateChapterOutlines(topic, chapters);

      for (int i = 0; i < chapters.length; i++) {
        final chapterTitle = chapters[i];

        try {
          // Notify chapter structure generation start
          onChapterStart(i, chapterTitle);

          // Get section headings for this chapter
          final subheadings = chapterOutlines[chapterTitle] ?? [];

          generatedChapters.add(Chapter(
            title: chapterTitle,
            content: '', // No content initially - will be generated on-demand
            subheadings: subheadings,
            subheadingContents: {}, // Empty - will be populated when sections are generated
          ));

          // Notify chapter structure generation complete
          onChapterComplete(i, chapterTitle);
        } catch (chapterError) {
          // Notify chapter structure generation error
          onChapterError(i, chapterTitle, chapterError.toString());

          // Add empty chapter to maintain index consistency
          generatedChapters.add(Chapter(
            title: chapterTitle,
            content: 'Error generating structure: ${chapterError.toString()}',
            subheadings: [],
            subheadingContents: {},
          ));
        }
      }

      final thesis = Thesis(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        topic: topic,
        chapters: generatedChapters,
        writingStyle: style,
        targetLength: 5000,
        format: 'APA',
      );

      state = AsyncValue.data(thesis);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Method for generating content for a specific section on-demand
  Future<void> generateSectionContent(
      int chapterIndex, String sectionTitle) async {
    final currentThesis = state.value;
    if (currentThesis == null) return;

    try {
      // Generate content for this specific section
      final content = await _deepseekService.generateChapterContent(
        currentThesis.topic,
        sectionTitle,
        currentThesis.writingStyle,
      );

      // Update the section content
      await updateSubheadingContent(chapterIndex, sectionTitle, content);
    } catch (e) {
      throw Exception('Failed to generate section content: $e');
    }
  }

  // Original method for progressive generation with full content (kept for compatibility)
  Future<void> generateThesisWithProgress(
    String topic,
    List<String> chapters,
    String style, {
    required Function(int index, String chapterTitle) onChapterStart,
    required Function(int index, String chapterTitle) onChapterComplete,
    required Function(int index, String chapterTitle, String error)
        onChapterError,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Skip outline generation for now - we'll generate chapters directly
      List<Chapter> generatedChapters = [];

      for (int i = 0; i < chapters.length; i++) {
        final chapterTitle = chapters[i];

        try {
          // Notify chapter generation start
          onChapterStart(i, chapterTitle);

          final content = await _deepseekService.generateChapterContent(
              topic, chapterTitle, style);

          final subheadings = _extractSubheadings(content);
          Map<String, String> subheadingContents = {};

          generatedChapters.add(Chapter(
            title: chapterTitle,
            content: content,
            subheadings: subheadings,
            subheadingContents: subheadingContents,
          ));

          // Notify chapter generation complete
          onChapterComplete(i, chapterTitle);
        } catch (chapterError) {
          // Notify chapter generation error
          onChapterError(i, chapterTitle, chapterError.toString());

          // Add empty chapter to maintain index consistency
          generatedChapters.add(Chapter(
            title: chapterTitle,
            content: 'Error generating content: ${chapterError.toString()}',
            subheadings: [],
            subheadingContents: {},
          ));
        }
      }

      final thesis = Thesis(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        topic: topic,
        chapters: generatedChapters,
        writingStyle: style,
        targetLength: 5000,
        format: 'APA',
      );

      state = AsyncValue.data(thesis);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> generateThesis(
      String topic, List<String> chapters, String style) async {
    state = const AsyncValue.loading();
    try {
      await _deepseekService.generateOutline(topic, chapters);

      List<Chapter> generatedChapters = [];
      for (var chapterTitle in chapters) {
        final content = await _deepseekService.generateChapterContent(
            topic, chapterTitle, style);

        final subheadings = _extractSubheadings(content);
        Map<String, String> subheadingContents = {};

        generatedChapters.add(Chapter(
          title: chapterTitle,
          content: content,
          subheadings: subheadings,
          subheadingContents: subheadingContents,
        ));
      }

      final thesis = Thesis(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        topic: topic,
        chapters: generatedChapters,
        writingStyle: style,
        targetLength: 5000,
        format: 'APA',
      );

      state = AsyncValue.data(thesis);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void updateChapter(int chapterIndex, String newContent) {
    state.whenData((thesis) {
      var updatedChapters = List<Chapter>.from(thesis.chapters);
      var chapter = updatedChapters[chapterIndex];

      updatedChapters[chapterIndex] = chapter.copyWith(
        content: newContent,
        subheadings: _extractSubheadings(newContent),
      );

      state = AsyncValue.data(thesis.copyWith(
        chapters: updatedChapters,
      ));
      _markForSave();
    });
  }

  List<String> _extractSubheadings(String content) {
    final lines = content.split('\n');
    return lines
        .where((line) =>
            line.trim().startsWith('#') || line.trim().startsWith('##'))
        .map((line) => line.replaceAll(RegExp(r'#+ '), '').trim())
        .toList();
  }

  Future<void> updateChapterOutlines(
      int chapterIndex, List<String> newOutlines) async {
    state.whenData((thesis) {
      if (chapterIndex < thesis.chapters.length) {
        final updatedChapters = List<Chapter>.from(thesis.chapters);
        updatedChapters[chapterIndex] = updatedChapters[chapterIndex].copyWith(
          subheadings: newOutlines,
        );

        state = AsyncData(thesis.copyWith(chapters: updatedChapters));
      }
    });
  }

  Future<void> updateSubheadingContent(
      int chapterIndex, String subheading, String content) async {
    print('Updating subheading: $subheading in chapter $chapterIndex');

    state.whenData((thesis) {
      print('Current thesis state: ${thesis.chapters.length} chapters');
      var chapter = thesis.chapters[chapterIndex];
      print('Chapter title: ${chapter.title}');
      print('Subheadings: ${chapter.subheadings}');

      // Verify access
      if (!canAccessSubheading(
          chapter.title, chapter.subheadings, subheading)) {
        print('Access denied: Previous sections not complete');
        throw Exception('Please complete previous sections first');
      }

      var updatedChapters = List<Chapter>.from(thesis.chapters);
      var updatedSubheadingContents =
          Map<String, String>.from(chapter.subheadingContents);
      updatedSubheadingContents[subheading] = content;
      print('Updated content length: ${content.length}');

      updatedChapters[chapterIndex] = chapter.copyWith(
        subheadingContents: updatedSubheadingContents,
      );

      // Mark as generated
      _markSubheadingGenerated(chapter.title, subheading);
      print('Marked as generated: ${chapter.title}-$subheading');

      state = AsyncValue.data(thesis.copyWith(
        chapters: updatedChapters,
      ));
      _markForSave();
      print('State updated successfully');
    });
  }

  bool isChapterComplete(String chapterTitle, List<String> subheadings) {
    return subheadings
        .every((subheading) => isSubheadingGenerated(chapterTitle, subheading));
  }

  bool isThesisComplete() {
    return state.whenData((thesis) {
          return thesis.chapters.every((chapter) =>
              isChapterComplete(chapter.title, chapter.subheadings));
        }).value ??
        false;
  }

  String? getSubheadingContent(int chapterIndex, String subheading) {
    return state.value?.chapters[chapterIndex].subheadingContents[subheading];
  }

  /// Load thesis by ID from Firebase
  Future<void> loadThesisById(String thesisId) async {
    state = const AsyncValue.loading();
    try {
      final thesis = await FirebaseUserService.instance.getThesis(thesisId);
      if (thesis != null) {
        state = AsyncValue.data(thesis);
        _generatedSections.clear();

        // Mark all sections with content as generated
        for (int i = 0; i < thesis.chapters.length; i++) {
          final chapter = thesis.chapters[i];
          for (final subheading in chapter.subheadings) {
            final content = chapter.subheadingContents[subheading];
            if (content != null && content.isNotEmpty) {
              _markSubheadingGenerated(chapter.title, subheading);
            }
          }
        }

        print('✅ Loaded thesis from Firebase: $thesisId');
      } else {
        state = AsyncValue.error('Thesis not found', StackTrace.current);
      }
    } catch (e, stackTrace) {
      print('❌ Error loading thesis from Firebase: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Persistence and Auto-save Methods

  /// Initialize persistence service and load saved data
  Future<void> _initializePersistence() async {
    try {
      await _persistenceService.initialize();
      await _loadSavedThesis();
      _startAutoSave();
    } catch (e) {
      print('❌ Error initializing persistence: $e');
      // Continue without persistence if it fails
    }
  }

  /// Load thesis from local storage
  Future<void> _loadSavedThesis() async {
    try {
      final persistenceData = await _persistenceService.loadThesis();
      if (persistenceData != null) {
        state = AsyncValue.data(persistenceData.thesis);
        _generatedSections.clear();
        _generatedSections.addAll(persistenceData.generatedSections);
        print('✅ Loaded saved thesis: ${persistenceData.lastSaveTime}');
      }
    } catch (e) {
      print('❌ Error loading saved thesis: $e');
    }
  }

  /// Save current thesis state
  Future<void> saveThesis() async {
    final currentThesis = state.value;
    if (currentThesis == null) return;

    try {
      // Save to local storage
      await _persistenceService.saveThesis(currentThesis, _generatedSections);

      // Also save to Firebase for cloud backup and access from other devices
      await _saveToFirebase(currentThesis);

      _hasUnsavedChanges = false;
    } catch (e) {
      print('❌ Error saving thesis: $e');
    }
  }

  /// Save thesis to Firebase
  Future<void> _saveToFirebase(Thesis thesis) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseUserService.instance.saveThesisWithBackup(thesis);
        print('✅ Thesis saved to Firebase and local storage: ${thesis.id}');
      }
    } catch (e) {
      print('⚠️ Warning: Failed to save to Firebase (continuing anyway): $e');
      // Don't throw error here - local save succeeded
    }
  }

  /// Mark that changes need to be saved and trigger debounced save
  void _markForSave() {
    _hasUnsavedChanges = true;
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(const Duration(seconds: 2), () {
      if (_hasUnsavedChanges) {
        saveThesis();
      }
    });
  }

  /// Start auto-save functionality
  void _startAutoSave() {
    _persistenceService.startAutoSave(() {
      if (_hasUnsavedChanges) {
        saveThesis();
      }
    });
  }

  /// Check if there are unsaved changes
  bool get hasUnsavedChanges => _hasUnsavedChanges;

  /// Get last save time
  Future<DateTime?> getLastSaveTime() => _persistenceService.getLastSaveTime();

  /// Check if cached thesis exists
  Future<bool> hasCachedThesis() => _persistenceService.hasCachedThesis();

  /// Clear all cached data
  Future<void> clearCache() async {
    await _persistenceService.clearCache();
    _generatedSections.clear();
    _hasUnsavedChanges = false;
  }

  /// Enable/disable auto-save
  Future<void> setAutoSaveEnabled(bool enabled) async {
    await _persistenceService.setAutoSaveEnabled(enabled);
    if (enabled) {
      _startAutoSave();
    } else {
      _persistenceService.stopAutoSave();
    }
  }

  /// Get auto-save status
  bool get isAutoSaveEnabled => _persistenceService.isAutoSaveEnabled;

  /// Create backup of current thesis
  Future<Map<String, dynamic>> createBackup() =>
      _persistenceService.exportBackup();

  /// Restore thesis from backup
  Future<void> restoreFromBackup(Map<String, dynamic> backupData) async {
    await _persistenceService.importBackup(backupData);
    await _loadSavedThesis();
  }

  @override
  void dispose() {
    _saveDebounceTimer?.cancel();
    _persistenceService.stopAutoSave();
    super.dispose();
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/thesis.dart';
import '../services/gemini_service.dart';
import '../services/export_service.dart';
import '../models/chapter.dart';


final geminiServiceProvider = Provider((ref) => GeminiService());
final exportServiceProvider = Provider((ref) => ExportService());
final thesisStateProvider = StateNotifierProvider<ThesisNotifier, AsyncValue<Thesis>>((ref) {
  return ThesisNotifier(ref.watch(geminiServiceProvider));
});

class ThesisNotifier extends StateNotifier<AsyncValue<Thesis>> {
  final GeminiService _geminiService;
  final Set<String> _generatedSections = {};

  ThesisNotifier(this._geminiService) : super(const AsyncValue.loading());

  // Add these new methods
  bool isSubheadingGenerated(String chapterTitle, String subheading) {
    return _generatedSections.contains('$chapterTitle-$subheading');
  }

  void _markSubheadingGenerated(String chapterTitle, String subheading) {
    _generatedSections.add('$chapterTitle-$subheading');
  }

  Future<void> setChaptersWithOutlines(
      List<String> chapterTitles,
      Map<String, List<String>> chapterOutlines
      ) async {
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
  }

  bool canAccessSubheading(String chapterTitle, List<String> subheadings, String currentSubheading) {
    int index = subheadings.indexOf(currentSubheading);
    if (index == 0) return true;
    return isSubheadingGenerated(chapterTitle, subheadings[index - 1]);
  }
  Future<void> generateThesis(String topic, List<String> chapters, String style) async {
    state = const AsyncValue.loading();
    try {
      final outline = await _geminiService.generateOutline(topic, chapters);

      List<Chapter> generatedChapters = [];
      for (var chapterTitle in chapters) {
        final content = await _geminiService.generateChapterContent(
            topic,
            chapterTitle,
            style
        );

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
    });
  }
  List<String> _extractSubheadings(String content) {
    final lines = content.split('\n');
    return lines
        .where((line) => line.trim().startsWith('#') || line.trim().startsWith('##'))
        .map((line) => line.replaceAll(RegExp(r'#+ '), '').trim())
        .toList();
  }

  Future<void> updateChapterOutlines(int chapterIndex, List<String> newOutlines) async {
    state.whenData((thesis) {
      if (thesis != null && chapterIndex < thesis.chapters.length) {
        final updatedChapters = List<Chapter>.from(thesis.chapters);
        updatedChapters[chapterIndex] = updatedChapters[chapterIndex].copyWith(
          subheadings: newOutlines,
        );

        state = AsyncData(thesis.copyWith(chapters: updatedChapters));
      }
    });
  }


  Future<void> updateSubheadingContent(
      int chapterIndex,
      String subheading,
      String content
      ) async {
    print('Updating subheading: $subheading in chapter $chapterIndex');

    state.whenData((thesis) {
      print('Current thesis state: ${thesis.chapters.length} chapters');
      var chapter = thesis.chapters[chapterIndex];
      print('Chapter title: ${chapter.title}');
      print('Subheadings: ${chapter.subheadings}');

      // Verify access
      if (!canAccessSubheading(chapter.title, chapter.subheadings, subheading)) {
        print('Access denied: Previous sections not complete');
        throw Exception('Please complete previous sections first');
      }

      var updatedChapters = List<Chapter>.from(thesis.chapters);
      var updatedSubheadingContents = Map<String, String>.from(chapter.subheadingContents);
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
      print('State updated successfully');
    });
  }

  bool isChapterComplete(String chapterTitle, List<String> subheadings) {
    return subheadings.every((subheading) =>
        isSubheadingGenerated(chapterTitle, subheading)
    );
  }

  bool isThesisComplete() {
    return state.whenData((thesis) {
      return thesis.chapters.every((chapter) =>
          isChapterComplete(chapter.title, chapter.subheadings)
      );
    }).value ?? false;
  }



  String? getSubheadingContent(int chapterIndex, String subheading) {
    return state.value?.chapters[chapterIndex].subheadingContents[subheading];
  }
}

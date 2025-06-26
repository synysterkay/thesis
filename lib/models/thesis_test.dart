import 'package:flutter_test/flutter_test.dart';
import 'package:thesis_generator/models/thesis.dart';
import 'chapter.dart';

void main() {
  group('Thesis Model Tests', () {
    test('Thesis serialization and deserialization', () {
      final thesis = Thesis(
        id: '1',
        topic: 'Test Topic',
        chapters: [
          Chapter(
            title: 'Chapter 1',
            content: 'Content',
            subheadings: ['1.1', '1.2'],
            subheadingContents: {
              '1.1': 'Content for 1.1',
              '1.2': 'Content for 1.2'
            },
          )
        ],
        writingStyle: 'Academic',
        targetLength: 5000,
        format: 'APA',
      );

      final json = thesis.toJson();
      final reconstructed = Thesis.fromJson(json);

      // Test all fields
      expect(reconstructed.id, thesis.id);
      expect(reconstructed.topic, thesis.topic);
      expect(reconstructed.writingStyle, thesis.writingStyle);
      expect(reconstructed.targetLength, thesis.targetLength);
      expect(reconstructed.format, thesis.format);

      // Test chapters
      expect(reconstructed.chapters.length, thesis.chapters.length);
      expect(reconstructed.chapters[0].title, thesis.chapters[0].title);
      expect(reconstructed.chapters[0].content, thesis.chapters[0].content);
      expect(reconstructed.chapters[0].subheadings, thesis.chapters[0].subheadings);
      expect(reconstructed.chapters[0].subheadingContents, thesis.chapters[0].subheadingContents);
    });
  });
}

import 'package:flutter_quill/flutter_quill.dart';

class ThesisFormatting {
  static void applyChapterStyle(QuillController controller) {
    final sizeAttribute = Attribute.fromKeyValue('size', '14.0');
    controller.formatText(0, controller.document.length, Attribute.h1);
    controller.formatText(0, controller.document.length, sizeAttribute);
    controller.formatText(0, controller.document.length, Attribute.bold);
  }

  static void applySubheadingStyle(QuillController controller) {
    final sizeAttribute = Attribute.fromKeyValue('size', '12.0');
    controller.formatText(0, controller.document.length, Attribute.h2);
    controller.formatText(0, controller.document.length, sizeAttribute);
    controller.formatText(0, controller.document.length, Attribute.bold);
  }

  static void insertTable(QuillController controller) {
    final document = Document();
    document.insert(0, '\nTable X: \n\n');
    document.format(
        document.length - 1, 1, Attribute.fromKeyValue('table', true));
    document.insert(document.length, 'Source: \n');
    controller.replaceText(
        controller.selection.baseOffset, 0, document.toDelta(), null);
  }
}

import 'package:flutter_quill/flutter_quill.dart';

class ContentFormatter {
  static void applyBlockQuote(QuillController controller) {
    final sizeAttribute = Attribute.fromKeyValue('size', '11.0');
    final indentAttribute = Attribute.fromKeyValue('indent', '2');
    controller.formatText(0, controller.document.length, sizeAttribute);
    controller.formatText(0, controller.document.length, indentAttribute);
    controller.formatText(0, controller.document.length, Attribute.italic);
  }

  static void applyFigureCaption(QuillController controller) {
    final sizeAttribute = Attribute.fromKeyValue('size', '10.0');
    controller.replaceText(controller.selection.baseOffset, 0, '\nFigure X: ', null);
    controller.formatText(controller.selection.baseOffset - 10, 10, sizeAttribute);
  }
}

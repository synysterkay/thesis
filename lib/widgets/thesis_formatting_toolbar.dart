import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../services/thesis_formatting.dart';
import '../services/content_formatter.dart';

class ThesisFormattingToolbar extends StatelessWidget {
  final QuillController controller;

  const ThesisFormattingToolbar({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main QuillSimpleToolbar
        QuillSimpleToolbar(
          controller: controller,
          config: QuillSimpleToolbarConfig(
            multiRowsDisplay: true,
            showFontFamily: true,
            showFontSize: true,
            showBoldButton: true,
            showItalicButton: true,
            showUnderLineButton: true,
            showStrikeThrough: true,
            showInlineCode: true,
            showColorButton: true,
            showBackgroundColorButton: true,
            showClearFormat: true,
            showAlignmentButtons: true,
            showHeaderStyle: true,
            showListNumbers: true,
            showListBullets: true,
            showListCheck: true,
            showCodeBlock: true,
            showQuote: true,
            showIndent: true,
            showLink: true,
          ),
        ),

        // Custom thesis-specific buttons
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.title),
                tooltip: 'Chapter Style',
                onPressed: () => ThesisFormatting.applyChapterStyle(controller),
              ),
              IconButton(
                icon: const Icon(Icons.subtitles),
                tooltip: 'Subheading Style',
                onPressed: () =>
                    ThesisFormatting.applySubheadingStyle(controller),
              ),
              IconButton(
                icon: const Icon(Icons.table_chart),
                tooltip: 'Insert Table',
                onPressed: () => ThesisFormatting.insertTable(controller),
              ),
              IconButton(
                icon: const Icon(Icons.format_quote),
                tooltip: 'Block Quote',
                onPressed: () => ContentFormatter.applyBlockQuote(controller),
              ),
              IconButton(
                icon: const Icon(Icons.image),
                tooltip: 'Figure Caption',
                onPressed: () =>
                    ContentFormatter.applyFigureCaption(controller),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

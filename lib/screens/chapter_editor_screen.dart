import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/thesis_provider.dart';
import '../widgets/thesis_formatting_toolbar.dart';
import '../utils/text_styles.dart';
import 'dart:math';

const thesisTextStyle = {
  'font': 'Times New Roman',
  'size': 12.0,
  'lineHeight': 1.5,
  'margin': EdgeInsets.fromLTRB(3.5, 2.5, 2.5, 2.5),
};

class ChapterEditorScreen extends ConsumerStatefulWidget {
  final String chapterTitle;
  final String subheading;
  final String initialContent;
  final int chapterIndex;

  const ChapterEditorScreen({
    super.key,
    required this.chapterTitle,
    required this.subheading,
    required this.initialContent,
    required this.chapterIndex,
  });

  @override
  _ChapterEditorScreenState createState() => _ChapterEditorScreenState();
}

class _ChapterEditorScreenState extends ConsumerState<ChapterEditorScreen> {
  late QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    final content = widget.initialContent.endsWith('\n')
        ? widget.initialContent
        : '${widget.initialContent}\n';

    _controller = QuillController(
      document: Document.fromJson([{"insert": content}]),
      selection: const TextSelection.collapsed(offset: 0),
    );

    _controller.changes.listen((event) {
      setState(() => _isDirty = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Color(0xFF2E2E2E)),
          onPressed: () => _handleBack(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.chapterTitle,
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E2E2E),
              ),
            ),
            Text(
              widget.subheading,
              style: GoogleFonts.lato(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Color(0xFF2E2E2E)),
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, color: Colors.red[700], size: 20),
                    SizedBox(width: 8),
                    Text(l10n.reportContent, style: GoogleFonts.lato()),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'report') {
                _showReportDialog(context);
              }
            },
          ),
          _isDirty
              ? IconButton(
            icon: Icon(Icons.save, color: Color(0xFF2196F3)),
            onPressed: _saveContent,
          ).animate().fadeIn()
              : SizedBox.shrink(),
        ],
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ThesisFormattingToolbar(
              controller: _controller,
            ),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: QuillEditor(
                controller: _controller,
                focusNode: _focusNode,
                scrollController: _scrollController,
                configurations: QuillEditorConfigurations(
                  autoFocus: false,
                  padding: EdgeInsets.all(16),
                  showCursor: true,
                  enableInteractiveSelection: true,
                  expands: false,
                  scrollable: true,
                  placeholder: l10n.startWritingHere,
                  customStyles: DefaultStyles(
                    h1: DefaultTextBlockStyle(
                      ThesisTextStyles.heading1,
                      const HorizontalSpacing(0, 0),
                      const VerticalSpacing(8, 4),
                      const VerticalSpacing(0, 0),
                      BoxDecoration(),
                    ),
                    h2: DefaultTextBlockStyle(
                      ThesisTextStyles.heading2,
                      const HorizontalSpacing(0, 0),
                      const VerticalSpacing(6, 3),
                      const VerticalSpacing(0, 0),
                      BoxDecoration(),
                    ),
                    paragraph: DefaultTextBlockStyle(
                      ThesisTextStyles.bodyText,
                      const HorizontalSpacing(0, 0),
                      const VerticalSpacing(0, 0),
                      const VerticalSpacing(0, 0),
                      BoxDecoration(),
                    ),
                  ),
                ),
              ),
            ),
          ).animate().fadeIn().slideY(),
        ],
      ),
    );
  }

  void _handleBack(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isDirty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.unsavedChanges,
              style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
          content:
          Text(l10n.saveChangesQuestion, style: GoogleFonts.lato()),
          actions: [
            TextButton(
              child: Text(l10n.discard,
                  style: GoogleFonts.lato(color: Colors.grey)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
            TextButton(
              child: Text(l10n.save,
                  style: GoogleFonts.lato(color: Color(0xFF2196F3))),
              onPressed: () {
                _saveContent();
                Navigator.of(context).pop(true);
              },
            ),
          ],
        ),
      ).then((value) {
        if (value ?? false) {
          Navigator.of(context).pop();
        }
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  void _showReportDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final TextEditingController reportController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.reportContent,
            style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.reportContentIssue, style: GoogleFonts.lato()),
            SizedBox(height: 16),
            TextField(
              controller: reportController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: l10n.enterConcern,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text(l10n.cancel,
                style: GoogleFonts.lato(color: Colors.grey)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text(l10n.submit,
                style: GoogleFonts.lato(color: Colors.red[700])),
            onPressed: () {
              _submitReport(reportController.text);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    ).then((_) => reportController.dispose());
  }

  void _submitReport(String reportText) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.reportSubmitted,
            style: GoogleFonts.lato(color: Colors.white)),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _saveContent() {
    final l10n = AppLocalizations.of(context)!;
    final plainText = _controller.document.toPlainText();
    ref.read(thesisStateProvider.notifier).updateChapter(
      widget.chapterIndex,
      plainText,
    );
    setState(() => _isDirty = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.changesSaved, style: GoogleFonts.lato()),
        backgroundColor: Color(0xFF2196F3),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

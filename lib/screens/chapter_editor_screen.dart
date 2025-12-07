import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

  // Updated color scheme to match thesis form screen
  static const primaryColor = Color(0xFF2563EB);
  static const backgroundColor = Color(0xFFFFFFFF);
  static const surfaceColor = Color(0xFFF8FAFC);
  static const borderColor = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF4A5568);
  static const textMuted = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    final content = widget.initialContent.endsWith('\n')
        ? widget.initialContent
        : '${widget.initialContent}\n';

    _controller = QuillController.basic();
    // Set document with black text color to ensure visibility on white background
    _controller.document = Document.fromJson([
      {
        "insert": content,
        "attributes": {"color": "#000000"}
      }
    ]);

    _controller.changes.listen((event) {
      setState(() => _isDirty = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textPrimary),
          onPressed: () => _handleBack(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.chapterTitle,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            Text(
              widget.subheading,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: textPrimary),
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, color: Colors.red[700], size: 20),
                    SizedBox(width: 8),
                    Text('Report Content', style: GoogleFonts.inter()),
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
                  icon: Icon(Icons.save, color: primaryColor),
                  onPressed: _saveContent,
                ).animate().fadeIn()
              : SizedBox.shrink(),
        ],
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: QuillSimpleToolbar(
              controller: _controller,
              config: QuillSimpleToolbarConfig(
                showClipboardPaste: false,
                showClipboardCopy: false,
                showClipboardCut: false,
                showUndo: true,
                showRedo: true,
                showFontFamily: false,
                showFontSize: true,
                showBoldButton: true,
                showItalicButton: true,
                showUnderLineButton: true,
                showStrikeThrough: false,
                showInlineCode: false,
                showColorButton: false,
                showBackgroundColorButton: false,
                showClearFormat: true,
                showAlignmentButtons: true,
                showLeftAlignment: true,
                showCenterAlignment: true,
                showRightAlignment: true,
                showJustifyAlignment: false,
                showHeaderStyle: true,
                showListNumbers: true,
                showListBullets: true,
                showListCheck: false,
                showCodeBlock: false,
                showQuote: true,
                showIndent: true,
                showLink: false,
                showSearchButton: false,
                showSubscript: false,
                showSuperscript: false,
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  textTheme: Theme.of(context).textTheme.copyWith(
                        bodyMedium: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                      ),
                ),
                child: QuillEditor(
                  controller: _controller,
                  focusNode: _focusNode,
                  scrollController: _scrollController,
                  config: QuillEditorConfig(
                    autoFocus: false,
                    padding: EdgeInsets.all(16),
                    showCursor: true,
                    enableInteractiveSelection: true,
                    expands: false,
                    scrollable: true,
                    placeholder: 'Begin your practice here...',
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
    if (_isDirty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: borderColor),
          ),
          title: Text(
            'Unsaved Changes',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          content: Text(
            'Do you want to save your progress?',
            style: GoogleFonts.inter(color: textSecondary),
          ),
          actions: [
            TextButton(
              child: Text(
                'Discard',
                style: GoogleFonts.inter(color: textMuted),
              ),
              onPressed: () => Navigator.of(context).pop(true),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Save',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                ),
              ),
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
    final TextEditingController reportController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor),
        ),
        title: Text(
          'Report Content',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please describe the issue with this content:',
              style: GoogleFonts.inter(color: textSecondary),
            ),
            SizedBox(height: 16),
            TextField(
              controller: reportController,
              maxLines: 3,
              style: GoogleFonts.inter(color: textPrimary),
              decoration: InputDecoration(
                hintText: 'Enter your concern...',
                hintStyle: GoogleFonts.inter(color: textMuted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                filled: true,
                fillColor: backgroundColor,
                contentPadding: EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: textMuted),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Submit',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
              ),
            ),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Report submitted successfully',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _saveContent() {
    final plainText = _controller.document.toPlainText();
    ref.read(thesisStateProvider.notifier).updateChapter(
          widget.chapterIndex,
          plainText,
        );
    setState(() => _isDirty = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Progress saved',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
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

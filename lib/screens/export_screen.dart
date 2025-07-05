import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../providers/thesis_provider.dart';
import '../services/export_service.dart';
import 'dart:io';
import '../templates/thesis_templates.dart';
import 'package:thesis_generator/screens/outline_viewer_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:universal_html/html.dart' as html;

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  _ExportScreenState createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  final ExportService _exportService = ExportService();
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  final PdfViewerController _pdfViewerController = PdfViewerController();
  ThesisTemplateType _selectedTemplate = ThesisTemplateType.modern;
  dynamic _pdfFile;
  bool _isSubscribed = true;
  bool _isExporting = false;
  bool _isEditing = false;
  final List<String> _highlightedTexts = [];
  final List<String> _deletedTexts = [];
  String? _selectedText;
  String? _lastActionType;

  // Updated color scheme to match new white and blue design
  static const primaryColor = Color(0xFF2563EB);
  static const secondaryColor = Color(0xFF1D4ED8);
  static const backgroundColor = Color(0xFFFFFFFF);
  static const surfaceColor = Color(0xFFF8FAFC);
  static const borderColor = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF4A5568);
  static const textMuted = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _generateInitialPdf();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error generating PDF: $e',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    });
  }

  Widget _buildTemplateSelector() {
    return Container(
      height: 80,
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(color: borderColor),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildTemplateOption(ThesisTemplateType.modern, 'Modern Academic'),
          _buildTemplateOption(ThesisTemplateType.classic, 'Classic Research'),
          _buildTemplateOption(ThesisTemplateType.minimal, 'Minimal'),
        ],
      ),
    );
  }

  Widget _buildTemplateOption(ThesisTemplateType type, String label) {
    final isSelected = _selectedTemplate == type;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTemplate = type);
        _generateInitialPdf();
      },
      child: Container(
        width: 120,
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: isSelected ? LinearGradient(
            colors: [primaryColor, secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ) : null,
          color: isSelected ? null : surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : borderColor,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: isSelected ? Colors.white : textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildPdfViewer() {
  if (_isExporting) {
    return Container(
      color: surfaceColor,
      child: Center(
        child: Container(
          padding: EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
              SizedBox(height: 16),
              Text(
                'Generating PDF...',
                style: GoogleFonts.inter(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  if (_pdfFile == null) {
    return Container(
      color: surfaceColor,
      child: Center(
        child: Container(
          padding: EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.picture_as_pdf,
                size: 48,
                color: textMuted,
              ),
              SizedBox(height: 16),
              Text(
                'No PDF generated',
                style: GoogleFonts.inter(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // FIX: Wrap PDF viewer in a Theme widget to override dark theme
  return Container(
    margin: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white, // Force white background
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: primaryColor.withOpacity(0.1),
          blurRadius: 10,
          spreadRadius: 2,
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Theme(
        // Override the dark theme for PDF viewer
        data: ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: Colors.white,
          canvasColor: Colors.white,
          cardColor: Colors.white,
          dialogBackgroundColor: Colors.white,
          // Use colorScheme instead of deprecated backgroundColor
          colorScheme: ColorScheme.light(
            background: Colors.white,
            surface: Colors.white,
            onBackground: Colors.black,
            onSurface: Colors.black,
          ),
        ),
        child: Container(
          color: Colors.white, // Explicit white background
          child: SfPdfViewer.memory(
            _pdfFile as Uint8List,
            key: _pdfViewerKey,
            controller: _pdfViewerController,
            enableTextSelection: _isEditing,
            onTextSelectionChanged: _handleTextSelection,
            // Add these properties to ensure proper display
            canShowScrollHead: true,
            canShowScrollStatus: true,
            enableDoubleTapZooming: true,
            enableDocumentLinkAnnotation: false,
            canShowHyperlinkDialog: false,
            // Force light theme for PDF viewer
            scrollDirection: PdfScrollDirection.vertical,
            pageLayoutMode: PdfPageLayoutMode.single,
          ),
        ),
      ),
    ),
  );
}


  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color backgroundColor,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
        shadowColor: backgroundColor.withOpacity(0.3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateInitialPdf() async {
    setState(() => _isExporting = true);
    try {
      final thesisState = ref.read(thesisStateProvider);
      await thesisState.when(
        data: (thesis) async {
          if (thesis != null) {
            _pdfFile = await _exportService.exportToPdf(
              thesis,
              templateType: _selectedTemplate,
            );
          } else {
            throw Exception('No thesis data available');
          }
        },
        loading: () => throw Exception('Loading thesis data...'),
        error: (error, stack) => throw Exception('Error loading thesis: $error'),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error generating PDF: $e',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
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
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => OutlineViewerScreen()),
            );
          },
        ).animate().fadeIn(delay: 200.ms),
        title: Text(
          'Export Thesis',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ).animate().fadeIn(delay: 300.ms).slideX(),
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: Column(
        children: [
          _buildTemplateSelector(),
          Container(
            height: 60,
            padding: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border(
                bottom: BorderSide(color: borderColor),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildToolbarButton(Icons.edit, 'Edit', _toggleEditMode),
                _buildToolbarButton(Icons.text_fields, 'Add Text', _handleAddText),
                _buildToolbarButton(Icons.highlight, 'Highlight', _handleHighlight),
                _buildToolbarButton(Icons.delete, 'Delete', _handleDelete),
              ],
            ),
          ),
          Expanded(
            child: _buildPdfViewer(),
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border(
                top: BorderSide(color: borderColor),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleSavePdf,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      shadowColor: primaryColor.withOpacity(0.3),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save, size: 20, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Save PDF',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleSharePdf,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      shadowColor: secondaryColor.withOpacity(0.3),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.share, size: 20, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Share',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildToolbarButton(IconData icon, String tooltip, VoidCallback onPressed) {
    return Tooltip(
      message: tooltip,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(icon, color: primaryColor),
          onPressed: onPressed,
          splashRadius: 24,
          tooltip: tooltip,
        ),
      ),
    );
  }

  void _handleAddText() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor),
        ),
        title: Text(
          'Add Text',
          style: GoogleFonts.inter(
            color: textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: textController,
          style: GoogleFonts.inter(color: textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter text to add',
            hintStyle: GoogleFonts.inter(color: textMuted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: primaryColor),
            ),
            filled: true,
            fillColor: surfaceColor,
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: textMuted),
            ),
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
            onPressed: () {
              if (textController.text.isNotEmpty) {
                _addTextToPdf(textController.text);
                Navigator.pop(context);
              }
            },
            child: Text(
              'Add',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      _pdfViewerController.clearSelection();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditing ? 'Edit mode enabled' : 'Edit mode disabled',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _handleTextSelection(PdfTextSelectionChangedDetails details) {
    if (_isEditing) {
      setState(() {
        _selectedText = details.selectedText;
      });
    }
  }

  Future<void> _addTextToPdf(String text) async {
    if (_pdfFile != null) {
      setState(() {
        _pdfViewerController.clearSelection();
        _pdfViewerKey.currentState?.setState(() {});
      });
      _generateInitialPdf();
    }
  }

  Future<void> _handleSavePdf() async {
    if (_pdfFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No PDF file available to save',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }
    try {
      setState(() => _isExporting = true);
      if (kIsWeb) {
        final bytes = _pdfFile as Uint8List;
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement()
          ..href = url
          ..style.display = 'none'
          ..download = 'thesis_${DateTime.now().millisecondsSinceEpoch}.pdf';
        html.document.body?.children.add(anchor);
        anchor.click();
        html.document.body?.children.remove(anchor);
        html.Url.revokeObjectUrl(url);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'PDF downloaded successfully',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } else {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/temp_thesis.pdf');
        await tempFile.writeAsBytes(_pdfFile as Uint8List);
        final result = await _exportService.savePdf(tempFile);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result,
                style: GoogleFonts.inter(color: Colors.white),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving PDF: $e',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _handleSharePdf() async {
    if (_pdfFile != null) {
      try {
        if (kIsWeb) {
          final bytes = _pdfFile as Uint8List;
          final blob = html.Blob([bytes], 'application/pdf');
          final url = html.Url.createObjectUrlFromBlob(blob);
          await Share.share(url);
          html.Url.revokeObjectUrl(url);
        } else {
          final directory = await getApplicationDocumentsDirectory();
          final file = File('${directory.path}/thesis_${DateTime.now().millisecondsSinceEpoch}.pdf');
          await file.writeAsBytes(_pdfFile);
          await Share.shareFiles([file.path]);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'PDF shared successfully',
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
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error sharing PDF: $e',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No PDF file available to share',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Future<void> _updatePdfWithHighlights() async {
    if (_pdfFile != null && _highlightedTexts.isNotEmpty) {
      setState(() {
        _pdfViewerController.clearSelection();
        _pdfViewerKey.currentState?.setState(() {});
      });
      _generateInitialPdf();
    }
  }

  Future<void> _updatePdfWithDeletions() async {
    if (_pdfFile != null && _deletedTexts.isNotEmpty) {
      setState(() {
        _pdfViewerController.clearSelection();
        _pdfViewerKey.currentState?.setState(() {});
      });
      _generateInitialPdf();
    }
  }

  void _handleHighlight() {
    if (_selectedText != null) {
      setState(() {
        _highlightedTexts.add(_selectedText!);
        _pdfViewerController.clearSelection();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Text highlighted',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      _updatePdfWithHighlights();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Select text to highlight',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: textMuted,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _handleDelete() {
    if (_selectedText != null) {
      setState(() {
        _deletedTexts.add(_selectedText!);
        _pdfViewerController.clearSelection();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Text deleted',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: secondaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      _updatePdfWithDeletions();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Select text to delete',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: textMuted,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }
}

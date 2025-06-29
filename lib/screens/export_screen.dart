import 'package:flutter/material.dart';
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

  static const primaryColor = Color(0xFF9D4EDD);
  static const secondaryColor = Color(0xFFFF48B0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _generateInitialPdf();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error generating PDF: $e')),
          );
        }
      }
    });
  }

  Widget _buildTemplateSelector() {
    return Container(
      height: 80,
      padding: EdgeInsets.symmetric(horizontal: 16),
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
          color: isSelected ? null : Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.lato(
              color: Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPdfViewer() {
    if (_isExporting) {
      return Center(child: CircularProgressIndicator(color: primaryColor));
    }

    if (_pdfFile == null) {
      return Center(
        child: Text(
          'No PDF generated',
          style: GoogleFonts.lato(color: Colors.white),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SfPdfViewer.memory(
          _pdfFile as Uint8List,
          key: _pdfViewerKey,
          controller: _pdfViewerController,
          enableTextSelection: _isEditing,
          onTextSelectionChanged: _handleTextSelection,
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
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
            style: GoogleFonts.lato(
              fontSize: 16,
              fontWeight: FontWeight.bold,
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
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: secondaryColor),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => OutlineViewerScreen()),
            );
          },
        ).animate().fadeIn(delay: 200.ms),
        title: Text(
          'Export Thesis',
          style: GoogleFonts.lato(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: secondaryColor,
          ),
        ).animate().fadeIn(delay: 300.ms).slideX(),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildTemplateSelector(),
          Container(
            height: 60,
            padding: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: Border(
                bottom: BorderSide(color: primaryColor.withOpacity(0.3)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildToolbarButton(Icons.edit, 'Edit', _toggleEditMode),
                _buildToolbarButton(Icons.text_fields,'addText', _handleAddText),
                _buildToolbarButton(Icons.highlight,'highlight', _handleHighlight),
                _buildToolbarButton(Icons.delete,'delete', _handleDelete),
              ],
            ),
          ),
          Expanded(
            child: _buildPdfViewer(),
          ),
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleSavePdf,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save, size: 20, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Save PDF',
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.share, size: 20, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Share',
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
          gradient: LinearGradient(
            colors: [primaryColor, secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          icon: Icon(icon, color: Colors.white),
          onPressed: onPressed,
          splashRadius: 24,
        ),
      ),
    );
  }

  void _handleAddText() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Add Text',
            style: GoogleFonts.lato(color: Colors.white)
        ),
        content: TextField(
          controller: textController,
          style: GoogleFonts.lato(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter text to add',
            hintStyle: GoogleFonts.lato(color: Colors.grey),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: primaryColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: primaryColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: secondaryColor),
            ),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.lato(color: Colors.grey)
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: secondaryColor,
            ),
            onPressed: () {
              if (textController.text.isNotEmpty) {
                _addTextToPdf(textController.text);
                Navigator.pop(context);
              }
            },
            child: Text('Add',
                style: GoogleFonts.lato(color: Colors.white)
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
        content: Text(_isEditing ? 'Edit mode enabled' : 'Edit mode disabled'),
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
        SnackBar(content: Text('No PDF file available to save')),
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
      } else {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/temp_thesis.pdf');
        await tempFile.writeAsBytes(_pdfFile as Uint8List);

        final result = await _exportService.savePdf(tempFile);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving PDF: $e')),
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
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error sharing PDF: $e')),
          );
        }
      }
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
          content: Text('Text highlighted',
              style: GoogleFonts.lato(color: Colors.white)
          ),
          backgroundColor: primaryColor,
        ),
      );
      _updatePdfWithHighlights();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Select text to highlight',
              style: GoogleFonts.lato(color: Colors.white)
          ),
          backgroundColor: Colors.grey[800],
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
          content: Text('Text deleted',
              style: GoogleFonts.lato(color: Colors.white)
          ),
          backgroundColor: secondaryColor,
        ),
      );
      _updatePdfWithDeletions();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Select text to delete',
              style: GoogleFonts.lato(color: Colors.white)
          ),
          backgroundColor: Colors.grey[800],
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


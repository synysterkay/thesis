import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/thesis_provider.dart';
import '../services/export_service.dart';
import '../models/thesis.dart';
import 'dart:io';
import '../templates/thesis_templates.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

class ExportScreen extends ConsumerStatefulWidget {
  final String? thesisId;

  const ExportScreen({super.key, this.thesisId});

  @override
  _ExportScreenState createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  final ExportService _exportService = ExportService();
  ThesisTemplateType _selectedTemplate = ThesisTemplateType.modern;
  bool _isExporting = false;
  String _exportingFormat = '';

  // Updated color scheme
  static const primaryColor = Color(0xFF2563EB);
  static const secondaryColor = Color(0xFF1D4ED8);
  static const backgroundColor = Color(0xFFFFFFFF);
  static const surfaceColor = Color(0xFFF8FAFC);
  static const borderColor = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF4A5568);

  @override
  void initState() {
    super.initState();

    // Load thesis if thesisId is provided
    if (widget.thesisId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref
              .read(thesisStateProvider.notifier)
              .loadThesisById(widget.thesisId!);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final thesisState = ref.watch(thesisStateProvider);

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textPrimary),
          onPressed: () {
            // Just pop back to the previous screen (which should be MainNavigationScreen)
            Navigator.pop(context);
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
      body: thesisState.when(
        data: (thesis) => _buildExportInterface(thesis),
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(error.toString()),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
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
              'Loading thesis...',
              style: GoogleFonts.inter(
                color: textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please wait while we prepare your thesis for export',
              style: GoogleFonts.inter(
                color: textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(32),
        margin: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              'Error Loading Thesis',
              style: GoogleFonts.inter(
                color: textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              error,
              style: GoogleFonts.inter(
                color: textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportInterface(Thesis thesis) {
    return Column(
      children: [
        _buildTemplateSelector(),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildThesisInfo(thesis),
                SizedBox(height: 32),
                _buildExportOptions(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThesisInfo(Thesis thesis) {
    return Container(
      padding: EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.school,
                color: primaryColor,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Thesis Information',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildInfoRow('Title', thesis.topic),
          SizedBox(height: 12),
          _buildInfoRow('Writing Style', thesis.writingStyle),
          SizedBox(height: 12),
          _buildInfoRow('Chapters', '${thesis.chapters.length} chapters'),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateSelector() {
    return Container(
      height: 100,
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
          _buildTemplateOption(ThesisTemplateType.modern, 'Modern\nAcademic'),
          _buildTemplateOption(ThesisTemplateType.classic, 'Classic\nResearch'),
          _buildTemplateOption(ThesisTemplateType.minimal, 'Minimal\nClean'),
          _buildTemplateOption(ThesisTemplateType.ieee, 'IEEE\nStandard'),
          _buildTemplateOption(ThesisTemplateType.apa, 'APA\nStyle'),
          _buildTemplateOption(ThesisTemplateType.harvard, 'Harvard\nStyle'),
        ],
      ),
    );
  }

  Widget _buildTemplateOption(ThesisTemplateType type, String label) {
    final isSelected = _selectedTemplate == type;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTemplate = type);
      },
      child: Container(
        width: 120,
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [primaryColor, secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
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

  Widget _buildExportOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Export Options',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ).animate().fadeIn(delay: 500.ms),
        SizedBox(height: 20),
        GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildExportCard(
              title: 'PDF',
              subtitle: '',
              icon: Icons.picture_as_pdf,
              color: primaryColor,
              onTap: () => _handleExportPdf(),
            ).animate().fadeIn(delay: 600.ms).scale(delay: 600.ms),
            _buildExportCard(
              title: 'Share',
              subtitle: '',
              icon: Icons.share,
              color: secondaryColor,
              onTap: () => _handleSharePdf(),
            ).animate().fadeIn(delay: 700.ms).scale(delay: 700.ms),
          ],
        ),
      ],
    );
  }

  Widget _buildExportCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isExporting ? null : onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: color,
                ),
              ),
            ),
            SizedBox(height: 8),
            Flexible(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              SizedBox(height: 2),
              Flexible(
                child: Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
            if (_isExporting && _exportingFormat == title)
              Flexible(
                child: Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Export handler methods
  Future<void> _handleExportPdf() async {
    setState(() {
      _isExporting = true;
      _exportingFormat = 'PDF';
    });

    try {
      final thesisState = ref.read(thesisStateProvider);
      if (!thesisState.hasValue || thesisState.value == null) {
        throw Exception('No thesis data available');
      }

      final pdfBytes = await _exportService.exportToPdf(
        thesisState.value!,
        templateType: _selectedTemplate,
      );

      if (kIsWeb) {
        final blob = html.Blob([pdfBytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement()
          ..href = url
          ..style.display = 'none'
          ..download = 'thesis_${DateTime.now().millisecondsSinceEpoch}.pdf';
        html.document.body?.children.add(anchor);
        anchor.click();
        html.document.body?.children.remove(anchor);
        html.Url.revokeObjectUrl(url);
        _showSuccessMessage(
            'PDF exported successfully! Check your Downloads folder.');
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File(
            '${directory.path}/thesis_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await file.writeAsBytes(pdfBytes);
        await _exportService.savePdf(file);
        _showSuccessMessage(
            'PDF exported successfully! You can find it in your Downloads folder.');
      }

      // Remove the duplicate success message below
    } catch (e) {
      _showErrorMessage('Error exporting PDF: $e');
    } finally {
      setState(() {
        _isExporting = false;
        _exportingFormat = '';
      });
    }
  }

  Future<void> _handleSharePdf() async {
    setState(() {
      _isExporting = true;
      _exportingFormat = 'Share';
    });

    try {
      final thesisState = ref.read(thesisStateProvider);
      if (!thesisState.hasValue || thesisState.value == null) {
        throw Exception('No thesis data available');
      }

      final pdfBytes = await _exportService.exportToPdf(
        thesisState.value!,
        templateType: _selectedTemplate,
      );

      if (kIsWeb) {
        final blob = html.Blob([pdfBytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        await Share.share(url);
        html.Url.revokeObjectUrl(url);
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File(
            '${directory.path}/thesis_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await file.writeAsBytes(pdfBytes);
        await Share.shareFiles([file.path]);
      }

      _showSuccessMessage('PDF shared successfully');
    } catch (e) {
      _showErrorMessage('Error sharing PDF: $e');
    } finally {
      setState(() {
        _isExporting = false;
        _exportingFormat = '';
      });
    }
  }

  void _showSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
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

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
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
}

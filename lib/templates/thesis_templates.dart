import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

enum ThesisTemplateType { modern, classic, minimal }

class ThesisTemplate {
  final String name;
  final PdfPageFormat pageFormat;
  final pw.TextStyle titleStyle;
  final pw.TextStyle chapterStyle;
  final pw.TextStyle subheadingStyle;
  final pw.TextStyle bodyStyle;
  final pw.EdgeInsets contentMargin;
  final bool includeHeader;
  final bool includeFooter;
  final pw.Widget Function(pw.Context)? headerBuilder;
  final pw.Widget Function(pw.Context)? footerBuilder;
  final pw.Widget Function(pw.Context)? backgroundBuilder;

  ThesisTemplate({
    required this.name,
    required this.pageFormat,
    required this.titleStyle,
    required this.chapterStyle,
    required this.subheadingStyle,
    required this.bodyStyle,
    this.contentMargin = const pw.EdgeInsets.all(32),
    this.includeHeader = true,
    this.includeFooter = true,
    this.headerBuilder,
    this.footerBuilder,
    this.backgroundBuilder,
  });

  static ThesisTemplate modern() {
    return ThesisTemplate(
      name: 'Modern Academic',
      pageFormat: PdfPageFormat.a4,
      titleStyle: pw.TextStyle(
        fontSize: 28,
        color: PdfColors.blue800,
        fontWeight: pw.FontWeight.bold,
      ),
      chapterStyle: pw.TextStyle(
        fontSize: 20,
        color: PdfColors.blue600,
        fontWeight: pw.FontWeight.bold,
      ),
      subheadingStyle: pw.TextStyle(
        fontSize: 16,
        color: PdfColors.blue500,
        fontWeight: pw.FontWeight.bold,
      ),
      bodyStyle: pw.TextStyle(
        fontSize: 12,
        color: PdfColors.black, // Explicitly set text color to black
        lineSpacing: 1.5,
      ),
      backgroundBuilder: (context) => pw.Container(
        decoration: pw.BoxDecoration(
          color: PdfColors.white, // Explicitly set background to white
          border: pw.Border(
            top: pw.BorderSide(width: 2, color: PdfColors.blue800),
          ),
        ),
      ),
    );
  }

  static ThesisTemplate classic() {
    return ThesisTemplate(
      name: 'Classic Research',
      pageFormat: PdfPageFormat.a4,
      titleStyle: pw.TextStyle(
        fontSize: 24,
        color: PdfColors.black, // Explicitly set text color to black
        fontWeight: pw.FontWeight.bold,
      ),
      chapterStyle: pw.TextStyle(
        fontSize: 18,
        color: PdfColors.black, // Explicitly set text color to black
        fontWeight: pw.FontWeight.bold,
      ),
      subheadingStyle: pw.TextStyle(
        fontSize: 14,
        color: PdfColors.black, // Explicitly set text color to black
        fontWeight: pw.FontWeight.bold,
      ),
      bodyStyle: pw.TextStyle(
        fontSize: 12,
        color: PdfColors.black, // Explicitly set text color to black
        lineSpacing: 2.0,
      ),
      backgroundBuilder: (context) => pw.Container(
        decoration: pw.BoxDecoration(
          color: PdfColors.white, // Explicitly set background to white
          border: pw.Border.all(
            width: 0.5,
            color: PdfColors.grey300,
          ),
        ),
      ),
    );
  }

  static ThesisTemplate minimal() {
    return ThesisTemplate(
      name: 'Minimal',
      pageFormat: PdfPageFormat.a4,
      titleStyle: pw.TextStyle(
        fontSize: 24,
        color: PdfColors.black, // Explicitly set text color to black
        fontWeight: pw.FontWeight.bold,
      ),
      chapterStyle: pw.TextStyle(
        fontSize: 18,
        color: PdfColors.black, // Explicitly set text color to black
        fontWeight: pw.FontWeight.bold,
      ),
      subheadingStyle: pw.TextStyle(
        fontSize: 14,
        color: PdfColors.black, // Explicitly set text color to black
        fontWeight: pw.FontWeight.bold,
      ),
      bodyStyle: pw.TextStyle(
        fontSize: 12,
        color: PdfColors.black, // Explicitly set text color to black
        lineSpacing: 1.5,
      ),
      includeHeader: false,
      includeFooter: false,
      backgroundBuilder: (context) => pw.Container(
        decoration: pw.BoxDecoration(
          color: PdfColors.white, // Explicitly set background to white
        ),
      ),
    );
  }
}

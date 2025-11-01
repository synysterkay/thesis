import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

enum ThesisTemplateType { modern, classic, minimal, ieee, apa, harvard }

class ThesisTemplate {
  final String name;
  final PdfPageFormat pageFormat;
  final pw.TextStyle titleStyle;
  final pw.TextStyle chapterStyle;
  final pw.TextStyle subheadingStyle;
  final pw.TextStyle bodyStyle;
  final pw.TextStyle captionStyle;
  final pw.TextStyle referenceStyle;
  final pw.EdgeInsets contentMargin;
  final bool includeHeader;
  final bool includeFooter;
  final pw.Widget Function(pw.Context)? headerBuilder;
  final pw.Widget Function(pw.Context)? footerBuilder;
  final pw.Widget Function(pw.Context)? backgroundBuilder;
  final double paragraphSpacing;
  final double sectionSpacing;
  final bool justified;

  ThesisTemplate({
    required this.name,
    required this.pageFormat,
    required this.titleStyle,
    required this.chapterStyle,
    required this.subheadingStyle,
    required this.bodyStyle,
    required this.captionStyle,
    required this.referenceStyle,
    this.contentMargin = const pw.EdgeInsets.all(32),
    this.includeHeader = true,
    this.includeFooter = true,
    this.headerBuilder,
    this.footerBuilder,
    this.backgroundBuilder,
    this.paragraphSpacing = 12.0,
    this.sectionSpacing = 24.0,
    this.justified = true,
  });

  static ThesisTemplate modern() {
    return ThesisTemplate(
      name: 'Modern Academic',
      pageFormat: PdfPageFormat.a4,
      titleStyle: pw.TextStyle(
        fontSize: 28,
        color: PdfColors.blue800,
        fontWeight: pw.FontWeight.bold,
        letterSpacing: 0.5,
      ),
      chapterStyle: pw.TextStyle(
        fontSize: 22,
        color: PdfColors.blue700,
        fontWeight: pw.FontWeight.bold,
        letterSpacing: 0.3,
      ),
      subheadingStyle: pw.TextStyle(
        fontSize: 16,
        color: PdfColors.blue600,
        fontWeight: pw.FontWeight.bold,
      ),
      bodyStyle: pw.TextStyle(
        fontSize: 12,
        color: PdfColors.black,
        lineSpacing: 1.6,
        letterSpacing: 0.1,
      ),
      captionStyle: pw.TextStyle(
        fontSize: 10,
        color: PdfColors.grey700,
        fontStyle: pw.FontStyle.italic,
      ),
      referenceStyle: pw.TextStyle(
        fontSize: 11,
        color: PdfColors.black,
        lineSpacing: 1.4,
      ),
      contentMargin: const pw.EdgeInsets.fromLTRB(40, 50, 40, 50),
      paragraphSpacing: 14.0,
      sectionSpacing: 28.0,
    );
  }

  static ThesisTemplate classic() {
    return ThesisTemplate(
      name: 'Classic Academic',
      pageFormat: PdfPageFormat.a4,
      titleStyle: pw.TextStyle(
        fontSize: 26,
        color: PdfColors.black,
        fontWeight: pw.FontWeight.bold,
      ),
      chapterStyle: pw.TextStyle(
        fontSize: 20,
        color: PdfColors.black,
        fontWeight: pw.FontWeight.bold,
      ),
      subheadingStyle: pw.TextStyle(
        fontSize: 16,
        color: PdfColors.black,
        fontWeight: pw.FontWeight.bold,
      ),
      bodyStyle: pw.TextStyle(
        fontSize: 12,
        color: PdfColors.black,
        lineSpacing: 2.0,
      ),
      captionStyle: pw.TextStyle(
        fontSize: 11,
        color: PdfColors.black,
        fontStyle: pw.FontStyle.italic,
      ),
      referenceStyle: pw.TextStyle(
        fontSize: 11,
        color: PdfColors.black,
        lineSpacing: 1.8,
      ),
      contentMargin: const pw.EdgeInsets.fromLTRB(50, 60, 50, 60),
      paragraphSpacing: 16.0,
      sectionSpacing: 32.0,
    );
  }

  static ThesisTemplate minimal() {
    return ThesisTemplate(
      name: 'Minimal Clean',
      pageFormat: PdfPageFormat.a4,
      titleStyle: pw.TextStyle(
        fontSize: 24,
        color: PdfColors.black,
        fontWeight: pw.FontWeight.bold,
      ),
      chapterStyle: pw.TextStyle(
        fontSize: 18,
        color: PdfColors.black,
        fontWeight: pw.FontWeight.bold,
      ),
      subheadingStyle: pw.TextStyle(
        fontSize: 14,
        color: PdfColors.black,
        fontWeight: pw.FontWeight.bold,
      ),
      bodyStyle: pw.TextStyle(
        fontSize: 11,
        color: PdfColors.black,
        lineSpacing: 1.5,
      ),
      captionStyle: pw.TextStyle(
        fontSize: 10,
        color: PdfColors.grey600,
        fontStyle: pw.FontStyle.italic,
      ),
      referenceStyle: pw.TextStyle(
        fontSize: 10,
        color: PdfColors.black,
        lineSpacing: 1.3,
      ),
      includeHeader: false,
      includeFooter: true,
      contentMargin: const pw.EdgeInsets.fromLTRB(35, 40, 35, 40),
      paragraphSpacing: 10.0,
      sectionSpacing: 20.0,
    );
  }

  static ThesisTemplate ieee() {
    return ThesisTemplate(
      name: 'IEEE Standard',
      pageFormat: PdfPageFormat.a4,
      titleStyle: pw.TextStyle(
        fontSize: 24,
        color: PdfColors.black,
        fontWeight: pw.FontWeight.bold,
      ),
      chapterStyle: pw.TextStyle(
        fontSize: 16,
        color: PdfColors.black,
        fontWeight: pw.FontWeight.bold,
      ),
      subheadingStyle: pw.TextStyle(
        fontSize: 14,
        color: PdfColors.black,
        fontWeight: pw.FontWeight.bold,
      ),
      bodyStyle: pw.TextStyle(
        fontSize: 10,
        color: PdfColors.black,
        lineSpacing: 1.2,
      ),
      captionStyle: pw.TextStyle(
        fontSize: 9,
        color: PdfColors.black,
        fontWeight: pw.FontWeight.bold,
      ),
      referenceStyle: pw.TextStyle(
        fontSize: 9,
        color: PdfColors.black,
        lineSpacing: 1.1,
      ),
      contentMargin:
          const pw.EdgeInsets.fromLTRB(19, 25, 19, 25), // IEEE margins
      paragraphSpacing: 6.0,
      sectionSpacing: 12.0,
      justified: false,
    );
  }

  static ThesisTemplate apa() {
    return ThesisTemplate(
      name: 'APA Style',
      pageFormat: PdfPageFormat.a4,
      titleStyle: pw.TextStyle(
        fontSize: 24,
        color: PdfColors.black,
        fontWeight: pw.FontWeight.bold,
      ),
      chapterStyle: pw.TextStyle(
        fontSize: 18,
        color: PdfColors.black,
        fontWeight: pw.FontWeight.bold,
      ),
      subheadingStyle: pw.TextStyle(
        fontSize: 14,
        color: PdfColors.black,
        fontWeight: pw.FontWeight.bold,
      ),
      bodyStyle: pw.TextStyle(
        fontSize: 12,
        color: PdfColors.black,
        lineSpacing: 2.0, // Double-spaced as per APA
      ),
      captionStyle: pw.TextStyle(
        fontSize: 12,
        color: PdfColors.black,
        fontStyle: pw.FontStyle.italic,
      ),
      referenceStyle: pw.TextStyle(
        fontSize: 12,
        color: PdfColors.black,
        lineSpacing: 2.0,
      ),
      contentMargin: const pw.EdgeInsets.all(25.4), // 1 inch margins
      paragraphSpacing: 0.0, // APA uses line spacing, not paragraph spacing
      sectionSpacing: 24.0,
    );
  }

  static ThesisTemplate harvard() {
    return ThesisTemplate(
      name: 'Harvard Style',
      pageFormat: PdfPageFormat.a4,
      titleStyle: pw.TextStyle(
        fontSize: 26,
        color: PdfColors.black,
        fontWeight: pw.FontWeight.bold,
      ),
      chapterStyle: pw.TextStyle(
        fontSize: 20,
        color: PdfColors.black,
        fontWeight: pw.FontWeight.bold,
      ),
      subheadingStyle: pw.TextStyle(
        fontSize: 16,
        color: PdfColors.black,
        fontWeight: pw.FontWeight.bold,
      ),
      bodyStyle: pw.TextStyle(
        fontSize: 12,
        color: PdfColors.black,
        lineSpacing: 1.5,
      ),
      captionStyle: pw.TextStyle(
        fontSize: 11,
        color: PdfColors.black,
        fontStyle: pw.FontStyle.italic,
      ),
      referenceStyle: pw.TextStyle(
        fontSize: 11,
        color: PdfColors.black,
        lineSpacing: 1.3,
      ),
      contentMargin:
          const pw.EdgeInsets.fromLTRB(38, 51, 25, 51), // Harvard margins
      paragraphSpacing: 12.0,
      sectionSpacing: 24.0,
    );
  }
}

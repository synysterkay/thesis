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
        font: pw.Font.helvetica(),
      ),
      chapterStyle: pw.TextStyle(
        fontSize: 20,
        color: PdfColors.blue600,
      ),
      subheadingStyle: pw.TextStyle(
        fontSize: 16,
        color: PdfColors.blue500,
      ),
      bodyStyle: pw.TextStyle(
        fontSize: 12,
        lineSpacing: 1.5,
      ),
      backgroundBuilder: (context) => pw.Container(
        decoration: pw.BoxDecoration(
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
        font: pw.Font.timesBold(),
      ),
      chapterStyle: pw.TextStyle(
        fontSize: 18,
        font: pw.Font.timesBold(),
      ),
      subheadingStyle: pw.TextStyle(
        fontSize: 14,
        font: pw.Font.timesBold(),
      ),
      bodyStyle: pw.TextStyle(
        fontSize: 12,
        lineSpacing: 2.0,
        font: pw.Font.times(),
      ),
      backgroundBuilder: (context) => pw.Container(
        decoration: pw.BoxDecoration(
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
        color: PdfColors.black,
        font: pw.Font.courierBold(),
      ),
      chapterStyle: pw.TextStyle(
        fontSize: 18,
        color: PdfColors.black,
        font: pw.Font.courierBold(),
      ),
      subheadingStyle: pw.TextStyle(
        fontSize: 14,
        color: PdfColors.black,
        font: pw.Font.courierBold(),
      ),
      bodyStyle: pw.TextStyle(
        fontSize: 12,
        color: PdfColors.black,
        lineSpacing: 1.5,
        font: pw.Font.courier(),
      ),
      includeHeader: false,
      includeFooter: false,
      backgroundBuilder: null,
    );
  }
}

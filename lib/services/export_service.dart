import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/thesis.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../templates/thesis_templates.dart';
import 'package:printing/printing.dart';
import 'dart:typed_data';
import 'package:media_store_plus/media_store_plus.dart';

class ExportService {
  String cleanText(String text) {
    return text.replaceAll(RegExp(r'[#*]+'), '').trim();
  }

  Future<Uint8List> exportToPdf(Thesis thesis, {ThesisTemplateType templateType = ThesisTemplateType.modern}) async {
    // Add validation
    if (thesis.chapters.isEmpty) {
      throw Exception('Thesis has no chapters');
    }

    final template = _getTemplate(templateType);
    final pdf = pw.Document();

    try {
      // Load web-safe fonts with error handling
      final font = await PdfGoogleFonts.notoSansRegular();
      final boldFont = await PdfGoogleFonts.notoSansBold();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: template.pageFormat,
          theme: pw.ThemeData.withFont(
            base: font,
            bold: boldFont,
          ).copyWith(
            defaultTextStyle: pw.TextStyle(
              color: PdfColors.black, // Ensure default text is black
            ),
          ),
          build: (context) {
            // Wrap content generation in try-catch
            try {
              return [
                // Add white background container
                pw.Container(
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                  ),
                  child: pw.Column(
                    children: [
                      _buildTitlePage(thesis, template),
                    ],
                  ),
                ),
                pw.NewPage(),
                pw.Container(
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                  ),
                  child: _buildTableOfContents(thesis, template, context),
                ),
                ..._buildChapters(thesis, template),
                if (thesis.references.isNotEmpty) ...[
                  pw.NewPage(),
                  pw.Container(
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                    ),
                    child: _buildReferences(thesis.references, template),
                  ),
                ],
              ];
            } catch (e) {
              print('Error building PDF content: $e');
              throw Exception('Failed to build PDF content: $e');
            }
          },
          margin: template.contentMargin,
          header: template.includeHeader ?
              (context) => _buildHeader(context, thesis.topic, template) : null,
          footer: template.includeFooter ?
              (context) => _buildFooter(context, template) : null,
        ),
      );

      // Return PDF as bytes with error handling
      final bytes = await pdf.save();
      if (bytes.isEmpty) {
        throw Exception('Generated PDF is empty');
      }
      return bytes;
    } catch (e) {
      print('Error in PDF generation: $e');
      throw Exception('Failed to generate PDF: $e');
    }
  }

  ThesisTemplate _getTemplate(ThesisTemplateType type) {
    switch (type) {
      case ThesisTemplateType.modern:
        return ThesisTemplate.modern();
      case ThesisTemplateType.classic:
        return ThesisTemplate.classic();
      case ThesisTemplateType.minimal:
        return ThesisTemplate.minimal();
    }
  }

  pw.Widget _buildHeader(pw.Context context, String topic, ThesisTemplate template) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(bottom: 10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
      ),
      child: pw.Text(
        cleanText(topic), 
        style: template.subheadingStyle.copyWith(
          color: PdfColors.black,
        ),
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context, ThesisTemplate template) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(top: 10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
      ),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: template.bodyStyle.copyWith(
          color: PdfColors.black,
        ),
      ),
    );
  }

  pw.Widget _buildTitlePage(Thesis thesis, ThesisTemplate template) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
      ),
      child: pw.Center(
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              cleanText(thesis.topic), 
              style: template.titleStyle.copyWith(
                color: template.titleStyle.color ?? PdfColors.black,
              ), 
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 40),
            pw.Text(
              'Writing Style: ${thesis.writingStyle}', 
              style: template.bodyStyle.copyWith(
                color: PdfColors.black,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Format: ${thesis.format}', 
              style: template.bodyStyle.copyWith(
                color: PdfColors.black,
              ),
            ),
            pw.SizedBox(height: 40),
            pw.Text(
              'Generated on: ${DateTime.now().toString().split('.')[0]}', 
              style: template.bodyStyle.copyWith(
                color: PdfColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildTableOfContents(Thesis thesis, ThesisTemplate template, pw.Context context) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Table of Contents', 
            style: template.chapterStyle.copyWith(
              color: template.chapterStyle.color ?? PdfColors.black,
            ),
          ),
          pw.SizedBox(height: 20),
          for (var i = 0; i < thesis.chapters.length; i++)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 5),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      '${i + 1}. ${cleanText(thesis.chapters[i].title)}',
                      style: template.bodyStyle.copyWith(
                        color: PdfColors.black,
                      ),
                    ),
                  ),
                  pw.Text(
                    '${i + 3}', 
                    style: template.bodyStyle.copyWith(
                      color: PdfColors.black,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<pw.Widget> _buildChapters(Thesis thesis, ThesisTemplate template) {
    List<pw.Widget> widgets = [];
    for (var chapter in thesis.chapters) {
      widgets.addAll([
        pw.NewPage(),
        pw.Container(
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  cleanText(chapter.title),
                  style: template.chapterStyle.copyWith(
                    color: template.chapterStyle.color ?? PdfColors.black,
                  ),
                  textAlign: pw.TextAlign.justify,
                ),
              ),
              pw.SizedBox(height: 20),
              for (var entry in chapter.subheadings.asMap().entries) ...[
                pw.Header(
                  level: 1,
                  child: pw.Text(
                    '${entry.key + 1}. ${cleanText(entry.value)}',
                    style: template.subheadingStyle.copyWith(
                      color: template.subheadingStyle.color ?? PdfColors.black,
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Paragraph(
                  text: cleanText(chapter.subheadingContents[entry.value] ?? ''),
                  style: template.bodyStyle.copyWith(
                    color: PdfColors.black,
                  ),
                  textAlign: pw.TextAlign.justify,
                ),
                pw.SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ]);
    }
    return widgets;
  }

  pw.Widget _buildReferences(List<String> references, ThesisTemplate template) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'References', 
            style: template.chapterStyle.copyWith(
              color: template.chapterStyle.color ?? PdfColors.black,
            ),
          ),
          pw.SizedBox(height: 20),
          for (var ref in references)
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 30, bottom: 10),
              child: pw.Text(
                cleanText(ref),
                style: template.bodyStyle.copyWith(
                  color: PdfColors.black,
                ),
                textAlign: pw.TextAlign.justify,
              ),
            ),
        ],
      ),
    );
  }

  Future<File> _exportWebPdf(pw.Document pdf) async {
    final bytes = await pdf.save();
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

    return File('');
  }

  Future<File> _exportNativePdf(pw.Document pdf) async {
    await Permission.storage.request();
    await Permission.manageExternalStorage.request();

    Directory? directory;
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted) {
        directory = Directory('/storage/emulated/0/Download');
      } else {
        directory = await getExternalStorageDirectory();
      }
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    if (directory == null) {
      throw Exception('Could not access storage directory');
    }

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final fileName = 'thesis_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  bool _validateThesisContent(Thesis thesis) {
    for (var chapter in thesis.chapters) {
      if (chapter.title.toLowerCase().contains('references')) {
        continue;
      }

      if (chapter.title.toLowerCase().contains('introduction') ||
          chapter.title.toLowerCase().contains('conclusion')) {
        if (chapter.subheadingContents.isEmpty) {
          return false;
        }
      } else {
        for (var subheading in chapter.subheadings) {
          if (!chapter.subheadingContents.containsKey(subheading) ||
              chapter.subheadingContents[subheading]?.isEmpty == true) {
            return false;
          }
        }
      }
    }
    return true;
  }

  Future<String> savePdf(File pdfFile) async {
    try {
      if (Platform.isAndroid) {
        await MediaStore.ensureInitialized();
        MediaStore.appFolder = "ThesisGenerator";
        final mediaStore = MediaStore();
        final result = await mediaStore.saveFile(
          tempFilePath: pdfFile.path,
          dirType: DirType.download,
          dirName: DirName.download,
        );
        return 'PDF saved successfully to Downloads folder';
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'thesis_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final savedFile = await pdfFile.copy('${directory.path}/$fileName');
        return 'PDF saved successfully: ${savedFile.path}';
      }
    } catch (e) {
      throw Exception('Failed to save PDF: $e');
    }
  }
}

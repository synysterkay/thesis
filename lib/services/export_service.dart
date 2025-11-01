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

  /// Split long text into manageable chunks for PDF generation
  List<String> _chunkText(String text, int maxChunkLength) {
    if (text.length <= maxChunkLength) return [text];

    // First, try to split by double newlines (paragraph breaks)
    final paragraphs = text.split('\n\n');
    final chunks = <String>[];

    for (final paragraph in paragraphs) {
      if (paragraph.trim().isEmpty) continue;

      if (paragraph.length <= maxChunkLength) {
        chunks.add(paragraph.trim());
      } else {
        // If paragraph is too long, split by sentences
        final sentences = paragraph.split(RegExp(r'[.!?]+'));
        String currentChunk = '';

        for (final sentence in sentences) {
          final trimmedSentence = sentence.trim();
          if (trimmedSentence.isEmpty) continue;

          final sentenceWithPeriod = '$trimmedSentence.';

          // Check if adding this sentence would exceed the limit
          if (currentChunk.length + sentenceWithPeriod.length >
                  maxChunkLength &&
              currentChunk.isNotEmpty) {
            chunks.add(currentChunk.trim());
            currentChunk = sentenceWithPeriod + ' ';
          } else {
            currentChunk += sentenceWithPeriod + ' ';
          }
        }

        // Add the last chunk if it's not empty
        if (currentChunk.trim().isNotEmpty) {
          chunks.add(currentChunk.trim());
        }
      }
    }

    return chunks.isEmpty ? [text] : chunks;
  }

  /// Build text content as multiple paragraphs to avoid PDF generation issues
  List<pw.Widget> _buildTextContent(String text, pw.TextStyle style,
      {double? spacing}) {
    if (text.isEmpty) return [];

    // Split large text into smaller paragraphs (max 3000 chars each)
    const maxParagraphLength = 3000;
    final textChunks = _chunkText(text, maxParagraphLength);

    final widgets = <pw.Widget>[];

    for (int i = 0; i < textChunks.length; i++) {
      final chunk = textChunks[i];
      if (chunk.trim().isNotEmpty) {
        widgets.add(
          pw.Paragraph(
            text: chunk.trim(),
            style: style.copyWith(color: PdfColors.black),
            textAlign: pw.TextAlign.justify,
          ),
        );

        // Add spacing between paragraphs, but not after the last one
        if (i < textChunks.length - 1) {
          widgets.add(pw.SizedBox(height: spacing ?? 10));
        }
      }
    }

    return widgets;
  }

  Future<Uint8List> exportToPdf(Thesis thesis,
      {ThesisTemplateType templateType = ThesisTemplateType.modern}) async {
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
          header: template.includeHeader
              ? (context) => _buildHeader(context, thesis.topic, template)
              : null,
          footer: template.includeFooter
              ? (context) => _buildFooter(context, template)
              : null,
        ),
      );

      // Return PDF as bytes with error handling
      final bytes = await pdf.save();
      if (bytes.isEmpty) {
        throw Exception('Generated PDF is empty');
      }
      return bytes;
    } on Exception catch (e) {
      print('Error in PDF generation: $e');
      final errorString = e.toString();

      if (errorString.contains('TooManyPagesException')) {
        print(
            'PDF generation failed due to content size. Attempting to optimize...');
        // This was likely caused by very large content blocks
        throw Exception(
            'PDF generation failed: Content is too large for a single processing block. The text has been split into smaller sections to resolve this issue. Please try exporting again.');
      }

      throw Exception('Failed to generate PDF: $e');
    } catch (e) {
      print('Unexpected error in PDF generation: $e');
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
      case ThesisTemplateType.ieee:
        return ThesisTemplate.ieee();
      case ThesisTemplateType.apa:
        return ThesisTemplate.apa();
      case ThesisTemplateType.harvard:
        return ThesisTemplate.harvard();
    }
  }

  pw.Widget _buildHeader(
      pw.Context context, String topic, ThesisTemplate template) {
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

  pw.Widget _buildTableOfContents(
      Thesis thesis, ThesisTemplate template, pw.Context context) {
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

  /// Builds a table widget for PDF rendering
  pw.Widget _buildTable(Map<String, dynamic> tableData, String? caption,
      ThesisTemplate template) {
    final columns = List<String>.from(tableData['columns'] ?? []);

    // Handle both old format (List<List>) and new Firebase-compatible format (Map<String, List>)
    List<List<dynamic>> rows = [];

    if (tableData['rows'] is List) {
      // Old format: direct list of lists
      rows = List<List<dynamic>>.from(tableData['rows'] ?? []);
    } else if (tableData['rows'] is Map) {
      // New Firebase-compatible format: map with row_0, row_1, etc.
      final rowsMap = tableData['rows'] as Map<String, dynamic>;
      final sortedKeys = rowsMap.keys.toList()..sort();
      for (String key in sortedKeys) {
        if (rowsMap[key] is List) {
          rows.add(List<dynamic>.from(rowsMap[key]));
        }
      }
    }

    // Safety check for empty data
    if (columns.isEmpty || rows.isEmpty) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(height: 20),
          pw.Container(
            width: double.infinity,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              color: PdfColors.grey100,
            ),
            padding: const pw.EdgeInsets.all(16),
            child: pw.Center(
              child: pw.Text(
                'Table data unavailable',
                style: template.bodyStyle.copyWith(
                  color: PdfColors.grey600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          if (caption != null && caption.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              caption,
              style: template.bodyStyle.copyWith(
                color: PdfColors.black,
                fontSize: 9,
                fontStyle: pw.FontStyle.italic,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ],
          pw.SizedBox(height: 20),
        ],
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 20),
        // Table
        pw.Table.fromTextArray(
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          headerDecoration: pw.BoxDecoration(
            color: PdfColors.grey200,
          ),
          headers: columns,
          data: rows
              .map((row) => row.map((cell) => cell?.toString() ?? '').toList())
              .toList(),
          headerStyle: template.subheadingStyle.copyWith(
            color: PdfColors.black,
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
          cellStyle: template.bodyStyle.copyWith(
            color: PdfColors.black,
            fontSize: 9,
          ),
          cellPadding: const pw.EdgeInsets.all(8),
          cellAlignment: pw.Alignment.centerLeft,
        ),
        // Caption
        if (caption != null && caption.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          pw.Text(
            caption,
            style: template.bodyStyle.copyWith(
              color: PdfColors.black,
              fontSize: 9,
              fontStyle: pw.FontStyle.italic,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
        pw.SizedBox(height: 20),
      ],
    );
  }

  /// Builds a chart widget for PDF rendering
  pw.Widget _buildChart(Map<String, dynamic> graphData, String? caption,
      ThesisTemplate template) {
    final labels = List<String>.from(graphData['labels'] ?? []);
    final data = List<num>.from(graphData['data'] ?? []);
    final chartType = graphData['type'] ?? 'bar';
    final xLabel = graphData['xlabel'] ?? '';
    final yLabel = graphData['ylabel'] ?? '';

    // Safety check for empty data
    if (labels.isEmpty || data.isEmpty) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(height: 20),
          pw.Container(
            width: double.infinity,
            height: 200,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              color: PdfColors.grey100,
            ),
            child: pw.Center(
              child: pw.Text(
                'Chart data unavailable',
                style: template.bodyStyle.copyWith(
                  color: PdfColors.grey600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          if (caption != null && caption.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              caption,
              style: template.bodyStyle.copyWith(
                color: PdfColors.black,
                fontSize: 9,
                fontStyle: pw.FontStyle.italic,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ],
          pw.SizedBox(height: 20),
        ],
      );
    }

    // Calculate appropriate Y-axis range
    final maxValue = data.reduce((a, b) => a > b ? a : b).toDouble();
    final minValue = data.reduce((a, b) => a < b ? a : b).toDouble();
    final range = maxValue - minValue;
    final yMax = maxValue + (range * 0.1); // Add 10% padding
    final yMin = minValue > 0 ? 0 : minValue - (range * 0.1);
    final step = (yMax - yMin) / 5;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 20),
        // Chart container with border
        pw.Container(
          width: double.infinity,
          height: 250, // Increased height for better spacing
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            color: PdfColors.white,
          ),
          padding: const pw.EdgeInsets.all(20), // Increased padding
          child: _buildChartContent(
              chartType, labels, data, yMin.toDouble(), step.toDouble()),
        ),
        // Axis labels
        if (xLabel.isNotEmpty || yLabel.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              if (yLabel.isNotEmpty)
                pw.Transform.rotate(
                  angle: -1.5708, // -90 degrees in radians
                  child: pw.Text(
                    yLabel,
                    style: template.bodyStyle.copyWith(
                      color: PdfColors.black,
                      fontSize: 8,
                    ),
                  ),
                ),
              pw.Spacer(),
              if (xLabel.isNotEmpty)
                pw.Text(
                  xLabel,
                  style: template.bodyStyle.copyWith(
                    color: PdfColors.black,
                    fontSize: 8,
                  ),
                ),
            ],
          ),
        ],
        // Caption
        if (caption != null && caption.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          pw.Text(
            caption,
            style: template.bodyStyle.copyWith(
              color: PdfColors.black,
              fontSize: 9,
              fontStyle: pw.FontStyle.italic,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
        pw.SizedBox(height: 20),
      ],
    );
  }

  /// Builds different types of chart content based on chart type
  pw.Widget _buildChartContent(String chartType, List<String> labels,
      List<num> data, double yMin, double step) {
    // Define extended color palette for variety
    final colors = [
      PdfColors.blue400,
      PdfColors.green400,
      PdfColors.orange400,
      PdfColors.purple400,
      PdfColors.red400,
      PdfColors.teal400,
      PdfColors.indigo400,
      PdfColors.pink400,
      PdfColors.cyan400,
      PdfColors.amber400,
    ];

    // Randomly select a color based on current time for variety
    final randomColorIndex =
        DateTime.now().millisecondsSinceEpoch % colors.length;
    final primaryColor = colors[randomColorIndex];

    switch (chartType.toLowerCase()) {
      case 'pie':
        return _buildPieChart(labels, data, colors);

      case 'area':
        return _buildAreaChart(labels, data, yMin, step, primaryColor);

      case 'scatter':
        return _buildScatterChart(labels, data, yMin, step, primaryColor);

      case 'line':
        return _buildLineChart(labels, data, yMin, step, primaryColor);

      case 'bar':
      default:
        return _buildBarChart(labels, data, yMin, step, primaryColor);
    }
  }

  /// Builds a bar chart
  pw.Widget _buildBarChart(List<String> labels, List<num> data, double yMin,
      double step, PdfColor color) {
    return pw.Chart(
      grid: pw.CartesianGrid(
        xAxis: pw.FixedAxis.fromStrings(labels),
        yAxis: pw.FixedAxis(
            [for (var i = 0; i <= 5; i++) (yMin + (step * i)).round()]),
      ),
      datasets: [
        pw.BarDataSet(
          color: color,
          data: data
              .asMap()
              .entries
              .map((entry) => pw.PointChartValue(
                  entry.key.toDouble(), entry.value.toDouble()))
              .toList(),
        ),
      ],
    );
  }

  /// Builds a line chart
  pw.Widget _buildLineChart(List<String> labels, List<num> data, double yMin,
      double step, PdfColor color) {
    return pw.Chart(
      grid: pw.CartesianGrid(
        xAxis: pw.FixedAxis.fromStrings(labels),
        yAxis: pw.FixedAxis(
            [for (var i = 0; i <= 5; i++) (yMin + (step * i)).round()]),
      ),
      datasets: [
        pw.LineDataSet(
          color: color,
          data: data
              .asMap()
              .entries
              .map((entry) => pw.PointChartValue(
                  entry.key.toDouble(), entry.value.toDouble()))
              .toList(),
        ),
      ],
    );
  }

  /// Builds an area chart (filled line chart)
  pw.Widget _buildAreaChart(List<String> labels, List<num> data, double yMin,
      double step, PdfColor color) {
    return pw.Chart(
      grid: pw.CartesianGrid(
        xAxis: pw.FixedAxis.fromStrings(labels),
        yAxis: pw.FixedAxis(
            [for (var i = 0; i <= 5; i++) (yMin + (step * i)).round()]),
      ),
      datasets: [
        pw.LineDataSet(
          color: color,
          data: data
              .asMap()
              .entries
              .map((entry) => pw.PointChartValue(
                  entry.key.toDouble(), entry.value.toDouble()))
              .toList(),
          isCurved: true,
        ),
      ],
    );
  }

  /// Builds a scatter plot
  pw.Widget _buildScatterChart(List<String> labels, List<num> data, double yMin,
      double step, PdfColor color) {
    return pw.Chart(
      grid: pw.CartesianGrid(
        xAxis: pw.FixedAxis.fromStrings(labels),
        yAxis: pw.FixedAxis(
            [for (var i = 0; i <= 5; i++) (yMin + (step * i)).round()]),
      ),
      datasets: [
        pw.LineDataSet(
          color: color,
          data: data
              .asMap()
              .entries
              .map((entry) => pw.PointChartValue(
                  entry.key.toDouble(), entry.value.toDouble()))
              .toList(),
          drawLine: false, // Only show points, no connecting lines
        ),
      ],
    );
  }

  /// Builds a pie chart using a custom implementation
  pw.Widget _buildPieChart(
      List<String> labels, List<num> data, List<PdfColor> colors) {
    final total = data.reduce((a, b) => a + b);

    return pw.Stack(
      children: [
        // Simple pie chart representation using containers
        pw.Container(
          width: 150,
          height: 150,
          child: pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                // Legend showing percentages
                for (int i = 0; i < labels.length && i < data.length; i++)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 12,
                        height: 12,
                        color: colors[i % colors.length],
                        margin: const pw.EdgeInsets.only(right: 8),
                      ),
                      pw.Text(
                        '${labels[i]}: ${(data[i] / total * 100).toStringAsFixed(1)}%',
                        style: pw.TextStyle(fontSize: 8),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Determines if a chapter should not contain tables or graphs
  /// (Introduction, Conclusion, References are typically text-only)
  bool _isNonDataChapter(String chapterTitle) {
    final title = chapterTitle.toLowerCase().trim();
    return title.contains('introduction') ||
        title.contains('conclusion') ||
        title.contains('references') ||
        title.contains('bibliography') ||
        title.contains('abstract') ||
        title.contains('acknowledgment') ||
        title.contains('preface') ||
        title.contains('foreword');
  }

  List<pw.Widget> _buildChapters(Thesis thesis, ThesisTemplate template) {
    List<pw.Widget> widgets = [];
    for (var chapter in thesis.chapters) {
      // DEBUG: Print chapter content information
      print('DEBUG PDF Export - Chapter: ${chapter.title}');
      print(
          'DEBUG PDF Export - Chapter content length: ${chapter.content.length}');
      print(
          'DEBUG PDF Export - Chapter content preview: ${chapter.content.substring(0, chapter.content.length > 100 ? 100 : chapter.content.length)}...');
      print(
          'DEBUG PDF Export - Subheadings count: ${chapter.subheadings.length}');
      print(
          'DEBUG PDF Export - SubheadingContents keys: ${chapter.subheadingContents.keys.toList()}');
      for (var subheading in chapter.subheadings) {
        final content = chapter.subheadingContents[subheading] ?? '';
        print(
            'DEBUG PDF Export - Subheading "$subheading" content length: ${content.length}');
        if (content.isNotEmpty) {
          print(
              'DEBUG PDF Export - Subheading "$subheading" content preview: ${content.substring(0, content.length > 50 ? 50 : content.length)}...');
        }
      }

      // DEBUG: Check for tables and graphs
      print(
          'DEBUG PDF Export - Chapter has table: ${chapter.tableData != null}');
      print(
          'DEBUG PDF Export - Chapter has graph: ${chapter.graphData != null}');
      if (chapter.tableData != null) {
        print('DEBUG PDF Export - Table data: ${chapter.tableData}');
      }
      if (chapter.graphData != null) {
        print('DEBUG PDF Export - Graph data: ${chapter.graphData}');
      }

      // Chapter header on new page
      widgets.add(pw.NewPage());

      // Chapter title
      widgets.add(
        pw.Header(
          level: 0,
          child: pw.Text(
            cleanText(chapter.title),
            style: template.chapterStyle.copyWith(
              color: template.chapterStyle.color ?? PdfColors.black,
            ),
          ),
        ),
      );
      widgets.add(pw.SizedBox(height: template.sectionSpacing / 2));

      // Add main chapter content if available
      if (chapter.content.isNotEmpty) {
        widgets.addAll(_buildTextContent(
            cleanText(chapter.content), template.bodyStyle,
            spacing: template.paragraphSpacing));
        widgets.add(pw.SizedBox(height: template.sectionSpacing));
      }

      // Add subheading-specific content if available
      for (var entry in chapter.subheadings.asMap().entries) {
        if (chapter.subheadingContents.containsKey(entry.value) &&
            chapter.subheadingContents[entry.value]!.isNotEmpty) {
          // Subheading
          widgets.add(
            pw.Header(
              level: 1,
              child: pw.Text(
                '${entry.key + 1}. ${cleanText(entry.value)}',
                style: template.subheadingStyle.copyWith(
                  color: template.subheadingStyle.color ?? PdfColors.black,
                ),
              ),
            ),
          );
          widgets.add(pw.SizedBox(height: template.paragraphSpacing));

          // Subheading content
          widgets.addAll(_buildTextContent(
              cleanText(chapter.subheadingContents[entry.value]!),
              template.bodyStyle,
              spacing: template.paragraphSpacing));
          widgets.add(pw.SizedBox(height: template.sectionSpacing));

          // Add subheading-specific table if available (exclude Introduction, Conclusion, References)
          if (chapter.subheadingTables != null &&
              chapter.subheadingTables!.containsKey(entry.value) &&
              !_isNonDataChapter(chapter.title)) {
            print(
                'DEBUG PDF Export - Adding subheading table for: ${entry.value}');
            final tableCaption = chapter.subheadingTableCaptions?[entry.value];
            widgets.add(_buildTable(chapter.subheadingTables![entry.value]!,
                tableCaption, template));
            widgets.add(pw.SizedBox(height: template.sectionSpacing));
          }

          // Add subheading-specific chart/graph if available (exclude Introduction, Conclusion, References)
          if (chapter.subheadingGraphs != null &&
              chapter.subheadingGraphs!.containsKey(entry.value) &&
              !_isNonDataChapter(chapter.title)) {
            print(
                'DEBUG PDF Export - Adding subheading graph for: ${entry.value}');
            final graphCaption = chapter.subheadingGraphCaptions?[entry.value];
            widgets.add(_buildChart(chapter.subheadingGraphs![entry.value]!,
                graphCaption, template));
            widgets.add(pw.SizedBox(height: template.sectionSpacing));
          }
        }
      }

      // Add table if available (exclude Introduction, Conclusion, References)
      if (chapter.tableData != null && !_isNonDataChapter(chapter.title)) {
        widgets.add(
            _buildTable(chapter.tableData!, chapter.tableCaption, template));
        widgets.add(pw.SizedBox(height: template.sectionSpacing));
      }

      // Add chart/graph if available (exclude Introduction, Conclusion, References)
      if (chapter.graphData != null && !_isNonDataChapter(chapter.title)) {
        widgets.add(
            _buildChart(chapter.graphData!, chapter.graphCaption, template));
        widgets.add(pw.SizedBox(height: template.sectionSpacing));
      }
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

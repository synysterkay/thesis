import 'package:dio/dio.dart';
import 'dart:async';
import '../utils/text_processor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chapter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:math' show pow;
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'dart:convert';

class ContentValidator {
  final Map<String, Set<String>> _contentFingerprints = {};

  bool isContentUnique(String chapterKey, String content) {
    final sentences = _extractSentences(content);
    final fingerprints = _generateFingerprints(sentences);

    for (var entry in _contentFingerprints.entries) {
      if (entry.key != chapterKey) {
        final overlap = fingerprints.intersection(entry.value);
        if (overlap.length / fingerprints.length > 0.2) return false;
      }
    }

    _contentFingerprints[chapterKey] = fingerprints;
    return true;
  }

  Set<String> _extractSentences(String content) {
    return content
        .split(RegExp(r'[.!?]'))
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.length > 10)
        .toSet();
  }

  Set<String> _generateFingerprints(Set<String> sentences) {
    return sentences
        .map((s) => s.split(' ').where((w) => w.length > 3).join(' '))
        .toSet();
  }
}

class GenerationProgress {
  final String title;
  final String content;
  final bool isComplete;
  final double progress;

  GenerationProgress(this.title, this.content, this.isComplete, this.progress);
}

class DeepSeekService {
  final Dio _dio = Dio();
  final ContentValidator _contentValidator = ContentValidator();
  final StreamController<GenerationProgress> _progressController =
      StreamController<GenerationProgress>.broadcast();
  int _currentApiKeyIndex = 0;
  final String _baseUrl = 'https://api.deepseek.com/v1/chat/completions';
  Stream<GenerationProgress> get progressStream => _progressController.stream;
  String? _userApiKey;
  DeepSeekService();

  final List<String> _apiKeys = [
    'sk-b23e53885fb94d93a9cc7144d09ff507', // Replace with your actual DeepSeek API key
  ];

  // Enhanced model configuration for more natural output
  final Map<String, dynamic> _modelConfig = {
    'model': 'deepseek-chat',
    'temperature': 0.8, // Increased for more variation
    'max_tokens': 8192,
    'top_p': 0.85, // Increased for more diverse vocabulary
    'frequency_penalty': 0.3, // Added to reduce repetition
    'presence_penalty': 0.2, // Added to encourage topic diversity
    'stream': false,
  };
  Options getRequestOptions(String apiKey) {
    if (kIsWeb) {
      return Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        receiveTimeout: const Duration(minutes: 2),
      );
    }
    return Options(
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      sendTimeout: const Duration(minutes: 2),
      receiveTimeout: const Duration(minutes: 2),
    );
  }

  void setUserApiKey(String apiKey) {
    _userApiKey = apiKey;
  }

  Future<void> _rotateApiKey() async {
    _currentApiKeyIndex = (_currentApiKeyIndex + 1) % _apiKeys.length;
    // More aggressive backoff - using exponential backoff with a cap
    final backoffDuration =
        Duration(seconds: pow(3, _currentApiKeyIndex % 5).toInt());
    print(
        'Rotating to API key ${_currentApiKeyIndex + 1}/${_apiKeys.length}, waiting ${backoffDuration.inSeconds}s');
    await Future.delayed(backoffDuration);
  }

  // Enhanced system prompt for natural academic writing
  Map<String, dynamic> _buildDeepSeekRequest(String prompt) {
    return {
      ..._modelConfig,
      'messages': [
        {
          'role': 'system',
          'content':
              '''You are an experienced postgraduate researcher writing a thesis. Your task is to produce genuinely human-sounding academic writing that feels natural and authentic.

## NATURAL ACADEMIC WRITING INSTRUCTIONS

Write so it sounds genuinely human — like it was authored by a real postgraduate researcher, not an algorithm.

### LANGUAGE & STYLE GUIDELINES

- Maintain academic tone, but use natural flow and rhythm — avoid overly stiff or formulaic phrasing.
- Vary sentence length: mix short, clear sentences with longer, more complex ones.
- Use natural transitions: "however," "for instance," "notably," "in contrast," etc.
- Avoid repetitive sentence structures like "This shows that..." or "It is important to note that..."
- Use human-like expressions: "it appears," "perhaps," "arguably," "it could be said that..."
- Avoid cliches and buzzwords such as "revolutionary," "game-changing," "transformative," "leverage," or "optimize."
- Keep the tone measured and reflective — sound like someone reasoning, not summarizing.
- Include subtle hedging and nuance, as real academics do.
- Avoid perfect symmetry in paragraph structure — let the flow feel organic.

### HUMAN TOUCH

- Introduce occasional interpretive comments or transitions ("this suggests that," "an interesting aspect is...").
- Maintain citations, references, and factual accuracy.
- Don't add exaggerated enthusiasm or marketing tone.
- Avoid robotic repetition or predictable phrasing patterns.
- Let some ideas develop more fully than others — not everything needs equal treatment.
- Include moments of intellectual curiosity: "This raises the question," "One wonders whether"

### STRUCTURAL VARIETY

- Vary paragraph lengths organically (some short, some extended)
- Don't start every paragraph with topic sentences
- Use varied transition methods, not just linking words
- Allow some asymmetry in how you develop different points
- Include occasional brief reflective passages

### FINAL CHECK
Before finishing, ensure the writing:
- Reads naturally aloud.
- Feels authored by a thoughtful person, not an algorithm.
- Keeps the same meaning and structure as the source text.
- Is suitable for academic publication or a postgraduate thesis.
- Shows natural variation in complexity and development.'''
        },
        {'role': 'user', 'content': prompt}
      ]
    };
  }

  String _extractDeepSeekContent(dynamic responseData) {
    try {
      return responseData['choices'][0]['message']['content'] as String;
    } catch (e) {
      throw Exception('Failed to parse DeepSeek response: $e');
    }
  }

  Future<T> _executeWithRetry<T>(
      Future<T> Function(String apiKey) operation) async {
    if (_userApiKey != null && _userApiKey!.isNotEmpty) {
      try {
        return await operation(_userApiKey!);
      } on DioException catch (e) {
        if (e.response?.statusCode == 401) {
          throw Exception(
              'Your API key is invalid. Please check your DeepSeek API key in Settings.');
        }
        print('Error with user API key: $e');
      }
    }

    final Set<int> usedKeyIndexes = {};
    final _lastRequestTime = <String, DateTime>{};

    while (usedKeyIndexes.length < _apiKeys.length) {
      final apiKey = _apiKeys[_currentApiKeyIndex];

      final now = DateTime.now();
      if (_lastRequestTime.containsKey(apiKey)) {
        final timeSinceLastRequest = now.difference(_lastRequestTime[apiKey]!);
        if (timeSinceLastRequest < const Duration(seconds: 6)) {
          await Future.delayed(
              const Duration(seconds: 6) - timeSinceLastRequest);
        }
      }
      _lastRequestTime[apiKey] = now;

      try {
        return await operation(apiKey);
      } on DioException catch (e) {
        if (e.response?.statusCode == 401) {
          // Unauthorized - invalid API key
          throw Exception(
              'Invalid API key. Please check your DeepSeek API key and try again. You can set your own API key using the key button (🔑) in the app.');
        } else if (e.response?.statusCode == 429 ||
            e.response?.statusCode == 503) {
          usedKeyIndexes.add(_currentApiKeyIndex);
          await _rotateApiKey();
          if (usedKeyIndexes.length == _apiKeys.length) {
            usedKeyIndexes.clear();
            await Future.delayed(const Duration(minutes: 3));
          }
          continue;
        }
        rethrow;
      } catch (e) {
        print('Error during API request: $e');
        usedKeyIndexes.add(_currentApiKeyIndex);
        await _rotateApiKey();
        if (usedKeyIndexes.length == _apiKeys.length) {
          throw Exception('All API keys failed: $e');
        }
      }
    }
    throw Exception('Service unavailable after trying all keys');
  }

  Future<String> generateOutline(String topic, List<String> chapters) async {
    return _executeWithRetry((apiKey) async {
      final prompt =
          '''Create a detailed thesis outline that feels naturally crafted by a thoughtful researcher.

Topic: $topic
Chapters: ${chapters.join(", ")}

Generate an outline that shows genuine intellectual engagement with the topic:

- Provide detailed subheadings for each chapter (vary their complexity naturally)
- Include key points to cover, but explain them briefly rather than just listing
- Show logical flow between sections with natural, varied transitions
- Let some chapters be more detailed than others, reflecting natural emphasis
- Use language that sounds like a researcher thinking through their approach
- Avoid formulaic patterns or overly symmetrical structure
- Include occasional insights about why certain aspects are important
- Use varied phrasing — not every chapter needs the same structural approach

Write this outline as a knowledgeable researcher would naturally structure it, showing your thinking process and allowing for organic variation in detail and emphasis across chapters.''';

      final response = await _dio.post(
        _baseUrl,
        options: getRequestOptions(apiKey),
        data: _buildDeepSeekRequest(prompt),
      );

      if (response.statusCode == 200) {
        return _extractDeepSeekContent(response.data);
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
      );
    });
  }

  Future<void> initializeRemoteConfig() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      await remoteConfig.setDefaults({
        'deepseek_api_keys': jsonEncode(_apiKeys),
      });

      await remoteConfig.fetchAndActivate();

      final keysString = remoteConfig.getString('deepseek_api_keys');
      if (keysString.isNotEmpty) {
        try {
          final List<dynamic> keys = jsonDecode(keysString);
          if (keys.isNotEmpty) {
            _apiKeys.clear();
            _apiKeys.addAll(keys.cast<String>());
            print(
                '✅ Loaded ${_apiKeys.length} API keys from Firebase Remote Config');
            return;
          }
        } catch (e) {
          print('❌ Error parsing API keys from Remote Config: $e');
        }
      } else {
        print('⚠️ No API keys found in Remote Config, using defaults');
      }

      print('🔄 Retrying Remote Config fetch with zero minimum interval...');
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 2),
        minimumFetchInterval: Duration.zero,
      ));

      await remoteConfig.fetchAndActivate();
      final retryKeysString = remoteConfig.getString('deepseek_api_keys');

      if (retryKeysString.isNotEmpty) {
        try {
          final List<dynamic> keys = jsonDecode(retryKeysString);
          if (keys.isNotEmpty) {
            _apiKeys.clear();
            _apiKeys.addAll(keys.cast<String>());
            print(
                '✅ Loaded ${_apiKeys.length} API keys from Firebase Remote Config on retry');
            return;
          }
        } catch (e) {
          print('❌ Error parsing API keys from Remote Config on retry: $e');
        }
      }

      print(
          '⚠️ Failed to load API keys from Remote Config after retry, using hardcoded defaults');
    } catch (e) {
      print('❌ Failed to initialize Remote Config: $e');
    }
  }

  Future<List<String>> suggestChapters(String topic) async {
    return _executeWithRetry((apiKey) async {
      final prefs = await SharedPreferences.getInstance();
      final String languageCode = prefs.getString('language_code') ?? 'en_US';
      final String targetLanguage = _getLanguageName(languageCode);

      final String chapterPrompt =
          '''Generate chapter suggestions in $targetLanguage for an academic thesis that feel naturally conceived.

Topic: $topic

Suggest 5-7 logical chapters that would naturally flow in this thesis. Think like a graduate student planning their research structure — showing genuine intellectual engagement rather than following a rigid template.

Consider:
- How would a researcher naturally approach this topic?
- What logical progression would make sense for investigating this subject?
- How can chapter titles reflect authentic academic thinking?
- What balance of breadth and depth would be appropriate?

Vary the length and complexity of chapter titles naturally — some can be more direct, others more analytical or descriptive. Avoid overly formulaic titles that all follow the same pattern.

Format: Return only the chapter titles, one per line, without numbers or bullet points.''';

      final response = await _dio.post(
        _baseUrl,
        options: getRequestOptions(apiKey),
        data: _buildDeepSeekRequest(chapterPrompt),
      );

      if (response.statusCode == 200) {
        String chaptersText = _extractDeepSeekContent(response.data);
        List<String> chapters = chaptersText
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .map((line) => line.replaceAll(RegExp(r'^\d+[\.\)]\s*'), '').trim())
            .toList();

        return _ensureRequiredChapters(chapters);
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
      );
    });
  }

  List<String> _ensureRequiredChapters(List<String> chapters) {
    if (!chapters.first.toLowerCase().contains('introduction')) {
      chapters.insert(0, 'Introduction');
    }
    if (!chapters.last.toLowerCase().contains('references')) {
      chapters.add('References');
    }
    if (!chapters[chapters.length - 2].toLowerCase().contains('conclusion')) {
      chapters.insert(chapters.length - 1, 'Conclusion');
    }
    return chapters;
  }

  Future<Map<String, List<String>>> generateChapterOutlines(
      String topic, List<String> chapters) async {
    Map<String, List<String>> chapterOutlines = {};

    for (int i = 0; i < chapters.length; i++) {
      String chapter = chapters[i];
      _progressController.add(GenerationProgress(
          chapter,
          'Generating outline for Chapter ${i + 1}: $chapter',
          false,
          (i / chapters.length) * 100));

      if (chapter.toLowerCase().contains('introduction')) {
        chapterOutlines[chapter] = _getIntroductionOutline();
        continue;
      }
      if (chapter.toLowerCase().contains('conclusion')) {
        chapterOutlines[chapter] = _getConclusionOutline();
        continue;
      }
      if (chapter.toLowerCase().contains('references')) {
        continue;
      }

      final outline = await _generateSingleChapterOutline(chapter, topic);
      chapterOutlines[chapter] = outline;

      await Future.delayed(Duration(seconds: 45));
    }

    return chapterOutlines;
  }

  Future<List<String>> _generateSingleChapterOutline(
      String chapter, String topic) async {
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final result = await _executeWithRetry((apiKey) async {
          final requestData =
              _buildDeepSeekRequest(_getChapterOutlinePrompt(chapter, topic));

          final response = await _dio.post(
            _baseUrl,
            options: getRequestOptions(apiKey),
            data: requestData,
          );

          if (response.statusCode == 200 && response.data != null) {
            return _extractDeepSeekContent(response.data);
          }
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
          );
        });

        final subheadings = _processOutlineResponse(result);
        if (_validateOutline(subheadings)) {
          return subheadings;
        }
      } catch (e) {
        await Future.delayed(Duration(seconds: 5));
      }
    }
    return _getFallbackOutline(chapter);
  }

  List<String> _getIntroductionOutline() {
    return [
      'Background and Context of Research Topic',
      'Problem Statement and Research Questions',
      'Research Objectives and Significance',
      'Scope and Limitations of Study',
      'Overview of Research Methodology'
    ];
  }

  List<String> _getConclusionOutline() {
    return [
      'Summary of Key Research Findings',
      'Discussion of Research Implications',
      'Recommendations Based on Findings',
      'Limitations and Future Research Directions',
      'Final Concluding Remarks and Reflections'
    ];
  }

  List<String> _processOutlineResponse(String response) {
    final processedResponse = TextProcessor.processHierarchy(response);
    final lines = processedResponse
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .map((line) => line.replaceAll(RegExp(r'^\d+[\.\)]\s*'), '').trim())
        .toList();

    return lines.length >= 5 ? lines.take(5).toList() : _getFallbackOutline('');
  }

  List<String> _getFallbackOutline(String chapter) {
    return [
      'Overview and Background Information',
      'Key Concepts and Theoretical Framework',
      'Analysis and Critical Discussion',
      'Practical Applications and Examples',
      'Summary and Future Implications'
    ];
  }

  String _getChapterOutlinePrompt(String chapter, String topic) {
    return '''Generate academic subheadings for this chapter that sound natural and human-crafted.

Chapter: "$chapter"
Research Topic: "$topic"

Create exactly 5 subheadings that feel like they were written by a thoughtful researcher:
- Use 4-8 words each, but vary the length naturally
- Employ appropriate academic terminology without being overly dense
- Show natural progression of ideas rather than rigid structure
- Vary in complexity and focus — some direct, some more analytical
- Reflect how a researcher would actually organize this chapter
- Avoid formulaic patterns like "Overview of..." "Analysis of..." "Discussion of..."
- Use varied phrasing styles — some can be more descriptive, others more action-oriented

Think about how ideas would naturally flow in this chapter and create subheadings that feel organic to that development.

Return only the 5 numbered subheadings (1-5), without explanations.''';
  }

  Future<String> generateChapterContent(
      String topic, String chapter, String style) async {
    int attempts = 0;
    const maxAttempts = 3;

    while (attempts < maxAttempts) {
      try {
        final content = await _executeWithRetry((apiKey) async {
          final prefs = await SharedPreferences.getInstance();
          final String languageCode =
              prefs.getString('language_code') ?? 'en_US';
          final String targetLanguage = _getLanguageName(languageCode);

          String prompt = chapter.toLowerCase().contains('introduction')
              ? _getIntroductionPrompt(topic, style, targetLanguage)
              : _getRegularChapterPrompt(topic, chapter, style, targetLanguage);

          final response = await _dio.post(
            _baseUrl,
            options: getRequestOptions(apiKey),
            data: _buildDeepSeekRequest(prompt),
          );

          final content = _extractDeepSeekContent(response.data);

          if (_contentValidator.isContentUnique(chapter, content) &&
              _validateContent(content)) {
            return content;
          }
          throw Exception('Generated content failed validation');
        });

        return content;
      } catch (e) {
        attempts++;
        if (attempts >= maxAttempts) rethrow;
        await Future.delayed(Duration(seconds: 30));
      }
    }
    throw Exception('Failed to generate content after $maxAttempts attempts');
  }

  /// Generates table data for a specific chapter topic and content
  /// Returns a Map with 'columns' and 'rows' structure for PDF rendering
  Future<Map<String, dynamic>?> _generateTableData(
      String topic, String chapterTitle, String academicField,
      {String? chapterContent}) async {
    try {
      print('DEBUG: Starting table data generation for "$chapterTitle"');

      final prompt = '''
You are creating an academic data table for a thesis chapter. Analyze the chapter information and create a relevant table.

Chapter Title: "${chapterTitle}"
Topic: ${topic}
Academic Field: ${academicField}
${chapterContent != null ? 'Chapter Content Preview: ${chapterContent.length > 500 ? chapterContent.substring(0, 500) + '...' : chapterContent}' : ''}

Task: Generate a realistic academic data table that directly supports the chapter content. The table should:

1. Be directly relevant to the chapter topic and content
2. Include realistic data that could be found in academic research
3. Have 3-5 meaningful column headers
4. Contain 5-8 rows of data
5. Use appropriate data types (numbers, percentages, categories, etc.)
6. Have a descriptive caption that explains what the table shows

Examples of relevant tables based on chapter content:
- If about market analysis: companies, revenue, market share, growth rates
- If about technology: platforms, features, adoption rates, performance metrics  
- If about user behavior: demographics, usage patterns, engagement metrics
- If about research methods: techniques, sample sizes, reliability scores
- If about historical trends: years, events, impacts, growth figures

Return ONLY valid JSON with this exact structure:
{
  "caption": "Descriptive table title that explains what data is shown",
  "columns": ["Column1", "Column2", "Column3", "Column4"],
  "rows": [
    ["DataPoint1", "Value1", "Metric1", "Status1"],
    ["DataPoint2", "Value2", "Metric2", "Status2"],
    ["DataPoint3", "Value3", "Metric3", "Status3"]
  ]
}

Make the data realistic and academically appropriate. Do not include any explanatory text, just the JSON.''';

      final response = await _executeWithRetry((apiKey) async {
        final dio = Dio();
        final result = await dio.post(
          'https://api.deepseek.com/v1/chat/completions',
          options: Options(headers: {'Authorization': 'Bearer $apiKey'}),
          data: {
            'model': 'deepseek-chat',
            'messages': [
              {'role': 'user', 'content': prompt}
            ],
            'max_tokens': 500,
            'temperature': 0.7,
          },
        );
        return result;
      });

      final content =
          response.data['choices'][0]['message']['content'].toString().trim();

      print(
          'DEBUG: Received table generation response: ${content.substring(0, content.length > 200 ? 200 : content.length)}...');

      // Clean up the content and extract JSON
      String jsonString = content;
      if (content.contains('```json')) {
        jsonString = content.split('```json')[1].split('```')[0].trim();
      } else if (content.contains('```')) {
        jsonString = content.split('```')[1].split('```')[0].trim();
      }

      print(
          'DEBUG: Extracted JSON string: ${jsonString.substring(0, jsonString.length > 200 ? 200 : jsonString.length)}...');

      final tableData = jsonDecode(jsonString);
      print(
          'DEBUG: Parsed table data successfully: ${tableData.keys.toList()}');

      // Validate the structure
      if (tableData is Map<String, dynamic> &&
          tableData.containsKey('columns') &&
          tableData.containsKey('rows') &&
          tableData['columns'] is List &&
          tableData['rows'] is List) {
        print('DEBUG: Table data validation successful');
        return tableData;
      }

      print('DEBUG: Table data validation failed - missing required fields');
      return null;
    } catch (e) {
      print('Error generating table data: $e');
      return null;
    }
  }

  /// Generates graph data for a specific chapter topic and content
  /// Returns a Map with chart data structure for PDF rendering
  Future<Map<String, dynamic>?> _generateGraphData(
      String topic, String chapterTitle, String academicField,
      {String? chapterContent}) async {
    try {
      print('DEBUG: Starting graph data generation for "$chapterTitle"');

      // Randomly select chart type for variety
      final chartTypes = ['bar', 'line', 'pie', 'area', 'scatter'];
      final randomChartType =
          chartTypes[DateTime.now().millisecondsSinceEpoch % chartTypes.length];

      print('DEBUG: Selected chart type: $randomChartType');

      final prompt = '''
You are creating an academic chart/graph for a thesis chapter. Analyze the chapter information and create a relevant visualization.

Chapter Title: "${chapterTitle}"
Topic: ${topic}
Academic Field: ${academicField}
Chart Type: ${randomChartType.toUpperCase()}
${chapterContent != null ? 'Chapter Content Preview: ${chapterContent.length > 500 ? chapterContent.substring(0, 500) + '...' : chapterContent}' : ''}

Task: Generate realistic ${randomChartType.toUpperCase()} chart data that directly supports the chapter content. The chart should:

1. Be directly relevant to the chapter topic and content
2. Show realistic data that could be found in academic research
3. Have meaningful, SHORT labels that relate to the chapter
4. Include 4-7 data points with realistic numerical values
5. Have SHORT, clear axis labels and caption (avoid long text that causes overlap)
6. Use the specified chart type: ${randomChartType.toUpperCase()}

Chart Type Guidelines:
- BAR: for comparing discrete categories or values
- LINE: for showing trends, changes, or progression over time  
- PIE: for showing proportions, percentages (ensure data adds to 100%)
- AREA: for cumulative data or filled trends over time
- SCATTER: for showing relationships between two variables

IMPORTANT: Keep all text SHORT to prevent overlap in visualizations:
- Caption: Maximum 50 characters
- X/Y labels: Maximum 15 characters each
- Data labels: Maximum 12 characters each

Return ONLY valid JSON with this exact structure:
{
  "caption": "Short descriptive chart title",
  "type": "${randomChartType}",
  "labels": ["Short1", "Short2", "Short3", "Short4"],
  "data": [23.5, 45.2, 67.8, 34.1],
  "xlabel": "Short X-axis",
  "ylabel": "Short Y-axis"
}

Choose the most appropriate chart type based on the chapter content and data being visualized. Make the data realistic and academically appropriate. Do not include any explanatory text, just the JSON.''';

      final response = await _executeWithRetry((apiKey) async {
        final dio = Dio();
        final result = await dio.post(
          'https://api.deepseek.com/v1/chat/completions',
          options: Options(headers: {'Authorization': 'Bearer $apiKey'}),
          data: {
            'model': 'deepseek-chat',
            'messages': [
              {'role': 'user', 'content': prompt}
            ],
            'max_tokens': 400,
            'temperature': 0.7,
          },
        );
        return result;
      });

      final content =
          response.data['choices'][0]['message']['content'].toString().trim();

      print(
          'DEBUG: Received graph generation response: ${content.substring(0, content.length > 200 ? 200 : content.length)}...');

      // Clean up the content and extract JSON
      String jsonString = content;
      if (content.contains('```json')) {
        jsonString = content.split('```json')[1].split('```')[0].trim();
      } else if (content.contains('```')) {
        jsonString = content.split('```')[1].split('```')[0].trim();
      }

      print(
          'DEBUG: Extracted graph JSON string: ${jsonString.substring(0, jsonString.length > 200 ? 200 : jsonString.length)}...');

      final graphData = jsonDecode(jsonString);
      print(
          'DEBUG: Parsed graph data successfully: ${graphData.keys.toList()}');

      // Validate the structure
      if (graphData is Map<String, dynamic> &&
          graphData.containsKey('labels') &&
          graphData.containsKey('data') &&
          graphData['labels'] is List &&
          graphData['data'] is List) {
        print('DEBUG: Graph data validation successful');
        return graphData;
      }

      print('DEBUG: Graph data validation failed - missing required fields');
      return null;
    } catch (e) {
      print('Error generating graph data: $e');
      return null;
    }
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

  Future<Chapter> generateCompleteChapter(
      String topic, String chapterTitle, String style,
      {String academicField = "General"}) async {
    final subheadings =
        await _generateSingleChapterOutline(chapterTitle, topic);
    final content = await generateChapterContent(topic, chapterTitle, style);

    // Generate table and graph data for enhanced academic content
    // Skip visual elements for Introduction, Conclusion, References chapters
    Map<String, dynamic>? tableData;
    Map<String, dynamic>? graphData;
    String? tableCaption;
    String? graphCaption;

    print('DEBUG: Checking if "$chapterTitle" is a non-data chapter...');
    final isNonDataChapter = _isNonDataChapter(chapterTitle);
    print('DEBUG: Is non-data chapter: $isNonDataChapter');

    if (!isNonDataChapter) {
      try {
        // Generate table data for content chapters - academic papers should have data visualizations
        print('DEBUG: Generating table data for "$chapterTitle"...');
        tableData = await _generateTableData(topic, chapterTitle, academicField,
            chapterContent: content);
        print(
            'DEBUG: Table generation result: ${tableData != null ? "SUCCESS" : "FAILED"}');
        if (tableData != null) {
          print('DEBUG: Table data keys: ${tableData.keys.toList()}');
          if (tableData.containsKey('caption')) {
            tableCaption = tableData['caption'] as String?;
          }
        }

        // Generate graph data for content chapters - visual representation enhances academic quality
        print('DEBUG: Generating graph data for "$chapterTitle"...');
        graphData = await _generateGraphData(topic, chapterTitle, academicField,
            chapterContent: content);
        print(
            'DEBUG: Graph generation result: ${graphData != null ? "SUCCESS" : "FAILED"}');
        if (graphData != null) {
          print('DEBUG: Graph data keys: ${graphData.keys.toList()}');
          if (graphData.containsKey('caption')) {
            graphCaption = graphData['caption'] as String?;
          }
        }
      } catch (e) {
        print('Error generating visual data for chapter "$chapterTitle": $e');
        print('DEBUG: Error stack trace: ${StackTrace.current}');
        // Continue without visual data if generation fails
      }
    } else {
      print(
          'DEBUG: Skipping table/graph generation for non-data chapter: "$chapterTitle"');
    }

    return Chapter(
      title: chapterTitle,
      content: content,
      subheadings: subheadings,
      subheadingContents: {}, // Can be populated later with specific content for each subheading
      tableData: tableData,
      graphData: graphData,
      tableCaption: tableCaption,
      graphCaption: graphCaption,
    );
  }

  Future<String> retryGenerateContent(
      String topic, String chapter, String style,
      {int maxAttempts = 3}) async {
    int apiAttempts = 0;

    while (apiAttempts < _apiKeys.length * maxAttempts) {
      try {
        final content = await _executeWithRetry(
            (apiKey) => generateChapterContent(topic, chapter, style));

        if (content.isNotEmpty && _validateContent(content)) {
          return content;
        }

        apiAttempts++;
        await Future.delayed(Duration(seconds: 2));
      } catch (e) {
        apiAttempts++;
        if (apiAttempts >= _apiKeys.length * maxAttempts) rethrow;
        await Future.delayed(Duration(seconds: 2));
      }
    }
    throw Exception('Failed to generate valid content after multiple attempts');
  }

  Future<List<Chapter>> generateAllChapters(
      String topic, List<String> chapterTitles, String style,
      {String academicField = "General"}) async {
    List<Chapter> chapters = [];

    for (String title in chapterTitles) {
      final chapter = await generateCompleteChapter(topic, title, style,
          academicField: academicField);
      chapters.add(chapter);
    }

    return chapters;
  }

  String _getIntroductionPrompt(
      String topic, String style, String targetLanguage) {
    return '''Write in $targetLanguage. Create a comprehensive academic introduction chapter that reads naturally and authentically.

Topic: $topic
Writing Style: $style

Create an introduction that flows naturally through these elements (don't treat them as rigid sections):
- Background and context of the research area
- The specific problem or gap your research addresses
- Your research objectives and questions
- Why this research matters and its potential contributions
- A brief overview of your approach

HUMANIZATION REQUIREMENTS:
- Maintain academic tone, but use natural flow and rhythm — avoid overly stiff or formulaic phrasing
- Vary sentence length: mix short, clear sentences with longer, more complex analytical ones
- Use natural transitions: "however," "for instance," "notably," "in contrast," "interestingly"
- Avoid repetitive sentence structures like "This shows that..." or "It is important to note that..."
- Use human-like expressions: "it appears," "perhaps," "arguably," "it could be said that," "one might consider"
- Keep the tone measured and reflective — sound like someone reasoning through the topic, not summarizing
- Include subtle hedging and nuance, as real academics do
- Let paragraph structure feel organic rather than perfectly symmetrical
- Include occasional interpretive comments: "this suggests that," "an interesting aspect is," "this raises the question"
- Don't add exaggerated enthusiasm or marketing language
- Avoid robotic repetition or predictable phrasing patterns

STRUCTURAL VARIETY:
- Vary paragraph lengths (some brief, others more extended)
- Don't start every paragraph identically
- Use organic transitions between ideas
- Allow some concepts to be developed more fully than others
- Include moments that show your thinking process

Target length: 1000+ words of naturally flowing academic prose that feels authored by a thoughtful human researcher, not generated by AI.''';
  }

  String _getRegularChapterPrompt(
      String topic, String chapter, String style, String targetLanguage) {
    return '''Write in $targetLanguage. Create detailed academic content for this specific section/subheading.

Section/Subheading: $chapter
Research Topic: $topic
Writing Style: $style

IMPORTANT: You are writing ONLY the content for this specific section. Do NOT include:
- Chapter headers (like "Chapter 3:" or "## Chapter")
- Section numbers or prefixes
- Table of contents
- Introduction to the section

Write 800-1200 words of pure academic content that directly addresses this specific section topic.

## CONTENT REQUIREMENTS

### ACADEMIC DEPTH
- Provide in-depth analysis specific to this section topic
- Include relevant theories, frameworks, or methodologies
- Present evidence-based arguments and reasoning
- Maintain scholarly rigor throughout

### STRUCTURE & FLOW
- Start directly with substantive content (no introductory phrases like "This section explores...")
- Use clear paragraph structure with logical progression
- Include relevant academic citations and references
- Connect ideas cohesively within the section scope

### HUMANIZATION REQUIREMENTS
- Maintain academic tone with natural, human-like flow
- Vary sentence length and structure organically
- Use natural transitions: "however," "furthermore," "notably," "in contrast"
- Include interpretive comments: "this suggests," "it appears," "arguably"
- Avoid robotic patterns or buzzwords
- Show reasoning process through nuanced analysis

### PROFESSIONAL QUALITY
- Use precise academic terminology appropriate to the field
- Include specific examples or case studies where relevant
- Present balanced perspectives on complex issues
- Maintain objectivity while showing critical thinking

Write as an expert researcher would - with authority, nuance, and genuine academic insight specific to this section topic.''';
  }

  bool _validateContent(String content) {
    if (content.length < 500) return false;
    if (!content.contains(RegExp(r'\n[A-Z][^\n]+\n'))) return false;
    final paragraphs = content.split('\n\n');
    if (paragraphs.length < 3) return false;
    return true;
  }

  bool _validateOutline(List<String> subheadings) {
    if (subheadings.length < 4) return false;
    if (subheadings.any((heading) => heading.split(' ').length < 3))
      return false;
    if (subheadings.toSet().length != subheadings.length) return false;
    return true;
  }

  String _getLanguageName(String code) {
    final Map<String, String> languageNames = {
      'en_US': 'English',
      'es': 'Spanish',
      'fr': 'French',
      'zh': 'Chinese',
      'hi': 'Hindi',
    };
    return languageNames[code] ?? 'English';
  }

  List<List<Map<String, dynamic>>> _splitIntoChunks(
      List<Map<String, dynamic>> items, int chunkSize) {
    List<List<Map<String, dynamic>>> chunks = [];
    for (var i = 0; i < items.length; i += chunkSize) {
      chunks.add(items.sublist(
          i, i + chunkSize > items.length ? items.length : i + chunkSize));
    }
    return chunks;
  }

  Future<List<String>> generateChapterContentInParallel(
    String topic,
    List<Map<String, dynamic>> sections,
    String style,
  ) async {
    final chunks = _splitIntoChunks(sections, 2);
    List<String> results = [];

    for (var chunk in chunks) {
      final futures = chunk.map((section) =>
          retryGenerateContent(topic, section['title'], style)
              .catchError((e) => ''));

      results.addAll(await Future.wait(futures));
      await Future.delayed(Duration(seconds: 30));
    }

    return results;
  }

  Future<List<String>> regenerateChapterOutlines(
      String topic, String chapter) async {
    try {
      if (chapter.toLowerCase().contains('introduction'))
        return _getIntroductionOutline();
      if (chapter.toLowerCase().contains('conclusion'))
        return _getConclusionOutline();
      if (chapter.toLowerCase().contains('references')) return [];
      return await _generateSingleChapterOutline(chapter, topic);
    } catch (e) {
      throw Exception('Failed to regenerate outlines');
    }
  }

  /// Generate table data for a specific subheading
  Future<Map<String, dynamic>?> generateTableDataForSubheading(
      String topic, String subheading, String academicField,
      {String? chapterContent}) async {
    try {
      return await _generateTableData(topic, subheading, academicField,
          chapterContent: chapterContent);
    } catch (e) {
      print('Error generating table data for subheading: $e');
      return null;
    }
  }

  /// Generate graph data for a specific subheading
  Future<Map<String, dynamic>?> generateGraphDataForSubheading(
      String topic, String subheading, String academicField,
      {String? chapterContent}) async {
    try {
      return await _generateGraphData(topic, subheading, academicField,
          chapterContent: chapterContent);
    } catch (e) {
      print('Error generating graph data for subheading: $e');
      return null;
    }
  }

  void dispose() {
    _progressController.close();
  }
}

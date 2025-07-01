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

class GeminiService {
  final Dio _dio = Dio();
  final ContentValidator _contentValidator = ContentValidator();
  final StreamController<GenerationProgress> _progressController = StreamController<GenerationProgress>.broadcast();
  int _currentApiKeyIndex = 0;
  final String _baseUrl = 'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-pro:generateContent';
  final _lastRequestTime = <String, DateTime>{};
  Stream<GenerationProgress> get progressStream => _progressController.stream;
  String get _currentApiKey => _apiKeys[_currentApiKeyIndex];
  String? _userApiKey;
  GeminiService() ;
  final List<String> _apiKeys = [
    'AIzaSyDtH2niottKPgMlx0adprvIHIkvtMAoVMs',
    'AIzaSyCE487wEu8VCtnrufphb0jhKrGoXAzZE7E',
    'AIzaSyCvPBVcU0VO2IImQycGcwxuPP0uo9WF8m8',
    'AIzaSyAnUwFSIl0-JkRKa_KkhMz5HdTP1H04Sss',
    'AIzaSyC-MK750JTYS-3txJBg8BdGKnCuFtl0clw',
    'AIzaSyAfaKDEPIJNmPNwhb49DOZHrx4bJRR0sZo',
    'AIzaSyB0yMtAqZ_oVar1yIP29NRpb9rykSHKaMk',
    'AIzaSyC-MK750JTYS-3txJBg8BdGKnCuFtl0clw',
    'AIzaSyAnUwFSIl0-JkRKa_KkhMz5HdTP1H04Sss',
    'AIzaSyD3aLlusWlxOylwiJ9lWzEki8iBHssuCdA',
    'AIzaSyBCaIo_IQrQTOzBGcD2O3P2dMwgBEOMwaQ',
    'AIzaSyBcybPLEYan0sAvjoQHVnnuw4crTIJpJQQ',
    'AIzaSyCb6ipHWuw2qBQVbFN54SBJAd_m8f-P5Lo',
    'AIzaSyC2oVznuIRTEY4n21zY5P9ftpkVSrk8XW8',
    'AIzaSyB3PmkMDnHREjg5mH1KPvfEFyvEmasbsRQ',
    'AIzaSyChUxi3qyBWTEbwQbO8fHb4tLWVH7khjmI',
    'AIzaSyDAZnEji-JeGCqoy3bmOukXYoCprfDPcQg',
    'AIzaSyB7VqpurA97HUiEEUZQStNIGQJrOfzx_jQ',
    'AIzaSyAzJrJFDfavkqwq_5z6zjqTVTPOnLUZC_w',
    'AIzaSyBJFUfHRiAln0GQS6eC_laIUMVY2FN4irw',
    'AIzaSyDbyJwS5k7R7_QWgH63e0CG3xvTLH5TPxs',
    'AIzaSyBbdSxZ9Ng761I-AbhK0zNlHurdj3bLOlU',
    'AIzaSyBsMgMgZLPkDXH4jkP6YgfhX99ZHDQrZqI',
    'AIzaSyAU8gk3NwmUbWs79rKp87sUe_ZFVajiWdQ',
    'AIzaSyBVl9-1GyUn_UgSc7SqymNgyy_slfT6ETg',
    'AIzaSyCdICqKk9GTGW-As_efNCdc67bmFnfaRwg',
    'AIzaSyAsE_lrgFZOBnOh-g97pfpXU7CoyUIA9V8',
    'AIzaSyAuC2-njrcavMfJobK2PiX2uXcNLiozDIk',
    'AIzaSyBzqei35_wSet2MkHfvp9ep8ZcEwpbG3SY',
    'AIzaSyAk_15PCBgMM0wJbLEel80KiLutNbEot-I',
    'AIzaSyA5QJSaOvKboymh6aHR_KauzOoQG5chAhg',
    'AIzaSyCRJ_usfd1VENUVFmOVAqAp-kvh5uhKatQ',
    'AIzaSyBiZ7UgyoXIc8GHDeq0mQGNzCzCNehYvak',
    'AIzaSyB7MGaa6HvdkdK27lLlOf3yIbSSWjr5x04',
  ];

  final Map<String, dynamic> _modelConfig = {
    'generationConfig': {
      'temperature': 0.7,
      'candidateCount': 1,
      'maxOutputTokens': 8192,
      'topP': 0.8,
      'topK': 40
    },
    'safetySettings': [
      {
        'category': 'HARM_CATEGORY_HARASSMENT',
        'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
      },
      {
        'category': 'HARM_CATEGORY_HATE_SPEECH',
        'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
      },
      {
        'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
        'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
      },
      {
        'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
        'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
      }
    ]
  };
  Options getRequestOptions(String apiKey) {
    if (kIsWeb) {
      return Options(
        headers: {'x-goog-api-key': apiKey},
        receiveTimeout: const Duration(minutes: 2),
      );
    }
    return Options(
      headers: {'x-goog-api-key': apiKey},
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
    final backoffDuration = Duration(seconds: pow(3, _currentApiKeyIndex % 5).toInt());
    print('Rotating to API key ${_currentApiKeyIndex + 1}/${_apiKeys.length}, waiting ${backoffDuration.inSeconds}s');
    await Future.delayed(backoffDuration);
  }


  Future<T> _executeWithRetry<T>(Future<T> Function(String apiKey) operation) async {
    if (_userApiKey != null && _userApiKey!.isNotEmpty) {
      try {
        return await operation(_userApiKey!); // Use user API key directly
      } on DioException catch (e) {
        // Handle user key errors (e.g., invalid key)
        print('Error with user API key: $e');
        // Consider informing the user about the invalid key
        // Optionally, you could disable the user-provided key here:
        // _userApiKey = null;
        // and let it fall back to the default rotation below.
      }
    }

    // Fallback to default key rotation if no user key or user key failed
    final Set<int> usedKeyIndexes = {};
    final _lastRequestTime = <String, DateTime>{}; // Moved inside this block

    while (usedKeyIndexes.length < _apiKeys.length) {
      final apiKey = _apiKeys[_currentApiKeyIndex]; // Use _apiKeys here

      final now = DateTime.now();
      if (_lastRequestTime.containsKey(apiKey)) {
        final timeSinceLastRequest = now.difference(_lastRequestTime[apiKey]!);
        if (timeSinceLastRequest < const Duration(seconds: 6)) {
          await Future.delayed(const Duration(seconds: 6) - timeSinceLastRequest);
        }
      }
      _lastRequestTime[apiKey] = now;

      try {
        return await operation(apiKey);
      } on DioException catch (e) {
        if (e.response?.statusCode == 429 || e.response?.statusCode == 503) {
          usedKeyIndexes.add(_currentApiKeyIndex);
          await _rotateApiKey();
          if (usedKeyIndexes.length == _apiKeys.length) {
            usedKeyIndexes.clear();
            await Future.delayed(const Duration(minutes: 3)); // Longer delay
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
      final response = await _dio.post(
        _baseUrl,
        options: getRequestOptions(apiKey),
        data: {
          'contents': [{
            'parts': [{
              'text': '''Create a detailed thesis outline for:
Topic: $topic
Chapters: ${chapters.join(", ")}
Requirements:
- Detailed subheadings for each chapter
- Key points to cover
- Logical flow between sections'''
            }]
          }],
          ..._modelConfig
        },
      );

      if (response.statusCode == 200) {
        return response.data['candidates'][0]['content']['parts'][0]['text'];
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

      // Set default values in case remote fetch fails
      await remoteConfig.setDefaults({
        'gemini_api_keys': jsonEncode(_apiKeys),
      });

      // Fetch and activate remote config
      bool updated = await remoteConfig.fetchAndActivate();

      // Get the API keys from remote config
      final keysString = remoteConfig.getString('gemini_api_keys');
      if (keysString.isNotEmpty) {
        try {
          final List<dynamic> keys = jsonDecode(keysString);
          if (keys.isNotEmpty) {
            _apiKeys.clear();
            _apiKeys.addAll(keys.cast<String>());
            print('✅ Loaded ${_apiKeys.length} API keys from Firebase Remote Config');
            if (updated) {
              print('🔄 Remote config was updated with new values');
            } else {
              print('ℹ️ Using cached remote config values');
            }
            return; // Successfully loaded from Firebase, exit the function
          }
        } catch (e) {
          print('❌ Error parsing API keys from Remote Config: $e');
          // Continue to fallback
        }
      } else {
        print('⚠️ No API keys found in Remote Config, using defaults');
      }

      // If we reach here, we need to retry with more aggressive settings
      print('🔄 Retrying Remote Config fetch with zero minimum interval...');
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 2),
        minimumFetchInterval: Duration.zero, // Force fetch
      ));

      updated = await remoteConfig.fetchAndActivate();
      final retryKeysString = remoteConfig.getString('gemini_api_keys');

      if (retryKeysString.isNotEmpty) {
        try {
          final List<dynamic> keys = jsonDecode(retryKeysString);
          if (keys.isNotEmpty) {
            _apiKeys.clear();
            _apiKeys.addAll(keys.cast<String>());
            print('✅ Loaded ${_apiKeys.length} API keys from Firebase Remote Config on retry');
            return;
          }
        } catch (e) {
          print('❌ Error parsing API keys from Remote Config on retry: $e');
        }
      }

      // If we still don't have keys, log a warning but continue with defaults
      print('⚠️ Failed to load API keys from Remote Config after retry, using hardcoded defaults');

    } catch (e) {
      print('❌ Failed to initialize Remote Config: $e');
      // Continue with default keys
    }
  }


  Future<List<String>> suggestChapters(String topic) async {
    return _executeWithRetry((apiKey) async {
      final prefs = await SharedPreferences.getInstance();
      final String languageCode = prefs.getString('language_code') ?? 'en_US';
      final String targetLanguage = _getLanguageName(languageCode);

      final String chapterPrompt = '''Generate in $targetLanguage:
      Suggest 5-7 logical chapters for an academic thesis on: $topic
      Format: Return chapter titles only, one per line''';

      final response = await _dio.post(
        _baseUrl,
        options: getRequestOptions(apiKey),
        data: {
          'contents': [
            {
              'parts': [
                {
                  'text': chapterPrompt
                }
              ]
            }
          ],
          'generationConfig': _modelConfig['generationConfig'],
          'safetySettings': _modelConfig['safetySettings']
        },
      );

      if (response.statusCode == 200) {
        String chaptersText = response.data['candidates'][0]['content']['parts'][0]['text'];
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
  Future<Map<String, List<String>>> generateChapterOutlines(String topic, List<String> chapters) async {
    Map<String, List<String>> chapterOutlines = {};

    for (int i = 0; i < chapters.length; i++) {
      String chapter = chapters[i];
      _progressController.add(GenerationProgress(
          chapter,
          'Generating outline for Chapter ${i + 1}: $chapter',
          false,
          (i / chapters.length) * 100
      ));

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

  Future<List<String>> _generateSingleChapterOutline(String chapter, String topic) async {
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final result = await _executeWithRetry((apiKey) async {
          final requestData = {
            'contents': [{
              'parts': [{
                'text': _getChapterOutlinePrompt(chapter, topic)
              }]
            }],
            ..._modelConfig
          };

          final response = await _dio.post(
            _baseUrl,
            options: getRequestOptions(apiKey),
            data: requestData,
          );

          if (response.statusCode == 200 && response.data != null) {
            return response.data['candidates'][0]['content']['parts'][0]['text'];
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
    final lines = processedResponse.split('\n')
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
    return '''
  Generate academic subheadings for:
  Chapter: "$chapter"
  Research Topic: "$topic"

  Instructions:
  1. Create exactly 5 subheadings
  2. Each subheading: 4-8 words
  3. Use academic terminology and phrasing
  4. Maintain clear progression of ideas
  5. Align with research methodology standards

  Required Format:
  1. [First Subheading]
  2. [Second Subheading]
  3. [Third Subheading]
  4. [Fourth Subheading]
  5. [Fifth Subheading]

  Note: Return numbered list only, no additional text
  ''';
  }

  Future<String> generateChapterContent(String topic, String chapter, String style) async {
    int attempts = 0;
    const maxAttempts = 3;

    while (attempts < maxAttempts) {
      try {
        final content = await _executeWithRetry((apiKey) async {
          final prefs = await SharedPreferences.getInstance();
          final String languageCode = prefs.getString('language_code') ?? 'en_US';
          final String targetLanguage = _getLanguageName(languageCode);

          String prompt = chapter.toLowerCase().contains('introduction')
              ? _getIntroductionPrompt(topic, style, targetLanguage)
              : _getRegularChapterPrompt(topic, chapter, style, targetLanguage);

          final response = await _dio.post(
            _baseUrl,
            options: getRequestOptions(apiKey),
            data: {
              'contents': [{
                'parts': [{'text': prompt}]
              }],
              ..._modelConfig
            },
          );

          final content = response.data['candidates'][0]['content']['parts'][0]['text'] as String;

          if (_contentValidator.isContentUnique(chapter, content) && _validateContent(content)) {
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
  Future<Chapter> generateCompleteChapter(String topic, String chapterTitle, String style) async {
    final subheadings = await _generateSingleChapterOutline(chapterTitle, topic);
    final content = await generateChapterContent(topic, chapterTitle, style);

    return Chapter(
        title: chapterTitle,
        content: content,
        subheadings: subheadings,
        subheadingContents: {} // Can be populated later with specific content for each subheading
    );
  }
  Future<String> retryGenerateContent(String topic, String chapter, String style, {int maxAttempts = 3}) async {
    int apiAttempts = 0;

    while (apiAttempts < _apiKeys.length * maxAttempts) {
      try {
        final content = await _executeWithRetry((apiKey) =>
            generateChapterContent(topic, chapter, style)
        );

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

  Future<List<Chapter>> generateAllChapters(String topic, List<String> chapterTitles, String style) async {
    List<Chapter> chapters = [];

    for (String title in chapterTitles) {
      final chapter = await generateCompleteChapter(topic, title, style);
      chapters.add(chapter);
    }

    return chapters;
  }

  String _getIntroductionPrompt(String topic, String style, String targetLanguage) {
    return '''Generate in $targetLanguage:
    Write a detailed academic introduction chapter for:
    Topic: $topic
    Style: $style
    Requirements:
    - Comprehensive background information
    - Clear problem statement
    - Research objectives
    - Study significance
    - Minimum 1000 words
    - Professional academic tone
    - Include section headings
    Format: Return as formatted text with clear sections''';
  }

  String _getRegularChapterPrompt(String topic, String chapter, String style, String targetLanguage) {
    return '''Generate in $targetLanguage:
    Write detailed academic content for:
    Chapter: $chapter
    Topic: $topic
    Style: $style
    Requirements:
    - In-depth analysis and discussion
    - Clear logical structure
    - Academic references and citations
    - Minimum 1000 words
    - Professional tone
    - Include section headings
    Format: Return as formatted text with clear sections''';
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
    if (subheadings.any((heading) => heading.split(' ').length < 3)) return false;
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

  List<List<Map<String, dynamic>>> _splitIntoChunks(List<Map<String, dynamic>> items, int chunkSize) {
    List<List<Map<String, dynamic>>> chunks = [];
    for (var i = 0; i < items.length; i += chunkSize) {
      chunks.add(
          items.sublist(i, i + chunkSize > items.length ? items.length : i + chunkSize)
      );
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
              .catchError((e) => '')
      );

      results.addAll(await Future.wait(futures));
      await Future.delayed(Duration(seconds: 30));
    }

    return results;
  }

  Future<List<String>> regenerateChapterOutlines(String topic, String chapter) async {
    try {
      if (chapter.toLowerCase().contains('introduction')) return _getIntroductionOutline();
      if (chapter.toLowerCase().contains('conclusion')) return _getConclusionOutline();
      if (chapter.toLowerCase().contains('references')) return [];
      return await _generateSingleChapterOutline(chapter, topic);
    } catch (e) {
      throw Exception('Failed to regenerate outlines');
    }
  }

  String _getConclusionPrompt(String topic, String style) {
    return '''Generate thesis conclusion for topic: "$topic"
          Style: $style
          Include:
          - Summary of key findings
          - Research implications
          - Recommendations
          - Future research directions
          Minimum 800 words''';
  }

  void dispose() {
    _progressController.close();
  }
}
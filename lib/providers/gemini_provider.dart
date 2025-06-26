import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/gemini_service.dart';

final geminiServiceProvider = Provider<GeminiService>((ref) => GeminiService());

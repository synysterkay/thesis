import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/deepseek_service.dart';

final deepseekServiceProvider =
    Provider<DeepSeekService>((ref) => DeepSeekService());

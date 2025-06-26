import 'package:flutter_riverpod/flutter_riverpod.dart';

final loadingStateProvider = StateProvider.autoDispose<bool>((ref) => false);


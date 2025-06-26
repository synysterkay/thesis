import 'package:hive/hive.dart';

class CacheService {
  final Box _box = Hive.box('thesisCache');

  Future<void> cacheThesis(String thesisId, Map<String, dynamic> thesisData) async {
    await _box.put(thesisId, thesisData);
  }

  Map<String, dynamic>? getCachedThesis(String thesisId) {
    return _box.get(thesisId);
  }
}

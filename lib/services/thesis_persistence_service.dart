import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/thesis.dart';

class ThesisPersistenceService {
  static const String _thesisKey = 'cached_thesis_data';
  static const String _generatedSectionsKey = 'generated_sections';
  static const String _lastSaveKey = 'last_save_time';
  static const String _autoSaveEnabledKey = 'auto_save_enabled';

  // Auto-save configuration
  static const Duration _autoSaveInterval = Duration(seconds: 30);
  Timer? _autoSaveTimer;
  bool _autoSaveEnabled = true;

  /// Initialize the persistence service
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _autoSaveEnabled = prefs.getBool(_autoSaveEnabledKey) ?? true;
  }

  /// Save thesis data to local storage
  Future<void> saveThesis(Thesis thesis, Set<String> generatedSections) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert thesis to JSON
      final thesisJson = jsonEncode(thesis.toJson());

      // Save thesis data
      await prefs.setString(_thesisKey, thesisJson);

      // Save generated sections
      final generatedSectionsList = generatedSections.toList();
      await prefs.setStringList(_generatedSectionsKey, generatedSectionsList);

      // Save timestamp
      await prefs.setInt(_lastSaveKey, DateTime.now().millisecondsSinceEpoch);

      print('✅ Thesis saved successfully at ${DateTime.now()}');
    } catch (e) {
      print('❌ Error saving thesis: $e');
      rethrow;
    }
  }

  /// Load thesis data from local storage
  Future<ThesisPersistenceData?> loadThesis() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load thesis JSON
      final thesisJson = prefs.getString(_thesisKey);
      if (thesisJson == null) return null;

      // Load generated sections
      final generatedSectionsList =
          prefs.getStringList(_generatedSectionsKey) ?? [];
      final generatedSections = generatedSectionsList.toSet();

      // Load last save time
      final lastSaveTimestamp = prefs.getInt(_lastSaveKey) ?? 0;
      final lastSaveTime =
          DateTime.fromMillisecondsSinceEpoch(lastSaveTimestamp);

      // Parse thesis
      final thesisMap = jsonDecode(thesisJson) as Map<String, dynamic>;
      final thesis = Thesis.fromJson(thesisMap);

      print('✅ Thesis loaded successfully. Last saved: $lastSaveTime');

      return ThesisPersistenceData(
        thesis: thesis,
        generatedSections: generatedSections,
        lastSaveTime: lastSaveTime,
      );
    } catch (e) {
      print('❌ Error loading thesis: $e');
      return null;
    }
  }

  /// Check if cached thesis exists
  Future<bool> hasCachedThesis() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_thesisKey);
    } catch (e) {
      return false;
    }
  }

  /// Get last save time
  Future<DateTime?> getLastSaveTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastSaveKey);
      if (timestamp == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      return null;
    }
  }

  /// Clear cached thesis data
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_thesisKey);
      await prefs.remove(_generatedSectionsKey);
      await prefs.remove(_lastSaveKey);
      print('✅ Thesis cache cleared');
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }

  /// Start auto-save timer
  void startAutoSave(Function() saveCallback) {
    if (!_autoSaveEnabled) return;

    _stopAutoSave();
    _autoSaveTimer = Timer.periodic(_autoSaveInterval, (timer) {
      saveCallback();
    });
    print('✅ Auto-save started (every ${_autoSaveInterval.inSeconds}s)');
  }

  /// Stop auto-save timer
  void stopAutoSave() {
    _stopAutoSave();
    print('⏹️ Auto-save stopped');
  }

  void _stopAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
  }

  /// Enable/disable auto-save
  Future<void> setAutoSaveEnabled(bool enabled) async {
    _autoSaveEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSaveEnabledKey, enabled);

    if (!enabled) {
      stopAutoSave();
    }
  }

  /// Get auto-save status
  bool get isAutoSaveEnabled => _autoSaveEnabled;

  /// Dispose resources
  void dispose() {
    _stopAutoSave();
  }

  /// Export thesis data for backup
  Future<Map<String, dynamic>> exportBackup() async {
    try {
      final data = await loadThesis();
      if (data == null) throw Exception('No thesis data to backup');

      return {
        'thesis': data.thesis.toJson(),
        'generatedSections': data.generatedSections.toList(),
        'lastSaveTime': data.lastSaveTime.millisecondsSinceEpoch,
        'exportTime': DateTime.now().millisecondsSinceEpoch,
        'version': '1.0',
      };
    } catch (e) {
      print('❌ Error creating backup: $e');
      rethrow;
    }
  }

  /// Import thesis data from backup
  Future<void> importBackup(Map<String, dynamic> backupData) async {
    try {
      final thesisMap = backupData['thesis'] as Map<String, dynamic>;
      final thesis = Thesis.fromJson(thesisMap);

      final generatedSectionsList =
          backupData['generatedSections'] as List<dynamic>;
      final generatedSections = generatedSectionsList.cast<String>().toSet();

      await saveThesis(thesis, generatedSections);
      print('✅ Backup imported successfully');
    } catch (e) {
      print('❌ Error importing backup: $e');
      rethrow;
    }
  }
}

/// Data class for persistence results
class ThesisPersistenceData {
  final Thesis thesis;
  final Set<String> generatedSections;
  final DateTime lastSaveTime;

  ThesisPersistenceData({
    required this.thesis,
    required this.generatedSections,
    required this.lastSaveTime,
  });
}

/// Global persistence service instance
final thesisPersistenceService = ThesisPersistenceService();

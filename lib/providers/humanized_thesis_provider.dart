import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/humanized_thesis.dart';

// Firestore service for humanized theses
class HumanizedThesisService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  // Get collection reference for current user's humanized theses
  CollectionReference get _userThesesCollection => _firestore
      .collection('users')
      .doc(_userId)
      .collection('humanized_theses');

  // Add a new humanized thesis to Firestore
  Future<String> addHumanizedThesis(HumanizedThesis thesis) async {
    try {
      final docRef = await _userThesesCollection.add(thesis.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to save humanized thesis: $e');
    }
  }

  // Get all humanized theses for current user
  Stream<List<HumanizedThesis>> getHumanizedTheses() {
    if (_userId.isEmpty) {
      return Stream.value([]);
    }

    return _userThesesCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
      // Log the error but don't crash the app
      print('Firebase error in getHumanizedTheses: $error');
      // Return empty list for common Firebase errors that indicate no data
      if (error.toString().contains('permission-denied') ||
          error.toString().contains('not-found') ||
          error.toString().contains('missing or insufficient permissions')) {
        return [];
      }
      throw error;
    }).map((snapshot) {
      try {
        return snapshot.docs
            .map((doc) => HumanizedThesis.fromFirestore(doc))
            .toList();
      } catch (e) {
        print('Error parsing documents: $e');
        return <HumanizedThesis>[];
      }
    });
  }

  // Update a humanized thesis
  Future<void> updateHumanizedThesis(
      String thesisId, Map<String, dynamic> updates) async {
    try {
      await _userThesesCollection.doc(thesisId).update(updates);
    } catch (e) {
      throw Exception('Failed to update humanized thesis: $e');
    }
  }

  // Delete a humanized thesis
  Future<void> deleteHumanizedThesis(String thesisId) async {
    try {
      await _userThesesCollection.doc(thesisId).delete();
    } catch (e) {
      throw Exception('Failed to delete humanized thesis: $e');
    }
  }

  // Get a specific humanized thesis by ID
  Future<HumanizedThesis?> getHumanizedThesis(String thesisId) async {
    try {
      final doc = await _userThesesCollection.doc(thesisId).get();
      if (doc.exists) {
        return HumanizedThesis.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get humanized thesis: $e');
    }
  }
}

// Service provider
final humanizedThesisServiceProvider = Provider<HumanizedThesisService>((ref) {
  return HumanizedThesisService();
});

// Stream provider for user's humanized theses
final humanizedThesesProvider = StreamProvider<List<HumanizedThesis>>((ref) {
  final service = ref.watch(humanizedThesisServiceProvider);
  return service.getHumanizedTheses();
});

// State notifier for managing humanized theses operations
class HumanizedThesesNotifier
    extends StateNotifier<AsyncValue<List<HumanizedThesis>>> {
  final HumanizedThesisService _service;

  HumanizedThesesNotifier(this._service) : super(const AsyncValue.loading()) {
    _loadTheses();
  }

  void _loadTheses() {
    _service.getHumanizedTheses().listen(
      (theses) {
        if (mounted) {
          state = AsyncValue.data(theses);
        }
      },
      onError: (error, stackTrace) {
        if (mounted) {
          state = AsyncValue.error(error, stackTrace);
        }
      },
    );
  }

  // Add a new humanized thesis
  Future<String> addThesis(HumanizedThesis thesis) async {
    try {
      final id = await _service.addHumanizedThesis(thesis);
      return id;
    } catch (e) {
      rethrow;
    }
  }

  // Update thesis status
  Future<void> updateThesisStatus(
    String thesisId,
    String status, {
    String? downloadUrl,
    int? processingTime,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': status,
      };

      if (downloadUrl != null) {
        updates['downloadUrl'] = downloadUrl;
      }

      if (processingTime != null) {
        updates['processingTimeSeconds'] = processingTime;
      }

      await _service.updateHumanizedThesis(thesisId, updates);
    } catch (e) {
      rethrow;
    }
  }

  // Delete a thesis
  Future<void> deleteThesis(String thesisId) async {
    try {
      await _service.deleteHumanizedThesis(thesisId);
    } catch (e) {
      rethrow;
    }
  }

  // Refresh the list
  void refresh() {
    _loadTheses();
  }
}

// Provider for the state notifier
final humanizedThesesNotifierProvider = StateNotifierProvider<
    HumanizedThesesNotifier, AsyncValue<List<HumanizedThesis>>>((ref) {
  final service = ref.watch(humanizedThesisServiceProvider);
  return HumanizedThesesNotifier(service);
});

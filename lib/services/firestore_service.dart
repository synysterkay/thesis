import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/thesis.dart'; // Add this import

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveThesis(String userId, Thesis thesis) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('theses')
        .doc(thesis.id)
        .set(thesis.toJson());
  }

  Stream<List<Thesis>> getUserTheses(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('theses')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Thesis.fromJson(doc.data())).toList());
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/signalement.dart';

class SignetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId; // À passer depuis AuthProvider

  SignetService() : _userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<List<String>> getMesSignetsIds() async {
    final snapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('signets')
        .get();

    return snapshot.docs.map((doc) => doc.id).toList();
  }

  Future<List<Signalement>> getSignalementsFromIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    final snapshots = await _firestore
        .collection('signalements')
        .where(FieldPath.documentId, whereIn: ids)
        .get();

    return snapshots.docs
        .map((doc) => Signalement.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> ajouterSignet(String signalementId) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('signets')
        .doc(signalementId)
        .set({'createdAt': FieldValue.serverTimestamp()});
  }

  Future<void> supprimerSignet(String signalementId) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('signets')
        .doc(signalementId)
        .delete();
  }
}
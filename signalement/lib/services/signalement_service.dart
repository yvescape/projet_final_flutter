import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/signalement.dart';

class SignalementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _signalementCollection => _firestore.collection('signalements');

  // Ajouter un signalement
  Future<void> ajouterSignalement(Signalement signal) async {
    await _signalementCollection.doc(signal.id).set(signal.toMap());
  }

  // Modifier un signalement
  Future<void> modifierSignalement(Signalement signal) async {
    await _signalementCollection.doc(signal.id).update(signal.toMap());
  }

  // Supprimer un signalement
  Future<void> supprimerSignalement(String id) async {
    await _signalementCollection.doc(id).delete();
  }

  // Récupérer touts les signalements
  Future<List<Signalement>> getTousLesSignalements() async {
    final snapshot = await _signalementCollection.get();
    return snapshot.docs.map((doc) => Signalement.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  // Récupérer touts les signalement d'un utilisateur
  Future<List<Signalement>> getSignalementParUtilisateur(String auteur) async {
    final snapshot = await _signalementCollection.where('auteurUid', isEqualTo: auteur).get();
    return snapshot.docs.map((doc) => Signalement.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  // Récupérer un signalement par son ID
  Future<Signalement?> getSignalementParId(String id) async {
    final doc = await _signalementCollection.doc(id).get();

    if (doc.exists) {
      return Signalement.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } else {
      return null;
    }
  } 
}
import 'package:cloud_firestore/cloud_firestore.dart';

class Signet {
  final String id;
  final String utilisateurId;
  final String signalementId;
  final DateTime dateAjout;

  Signet({
    required this.id,
    required this.utilisateurId,
    required this.signalementId,
    DateTime? dateAjout,
  }) : dateAjout = dateAjout ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'utilisateurId': utilisateurId,
      'signalementId': signalementId,
      'dateAjout': Timestamp.fromDate(dateAjout),
    };
  }

  factory Signet.fromMap(String id, Map<String, dynamic> data) {
    return Signet(
      id: id,
      utilisateurId: data['utilisateurId'],
      signalementId: data['signalementId'],
      dateAjout: (data['dateAjout'] as Timestamp).toDate(),
    );
  }
}

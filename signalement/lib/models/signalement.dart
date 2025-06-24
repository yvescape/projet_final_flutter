import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../utils/statut_signalement.dart';

class Signalement {
  final String id;
  final String titre;
  final String description;
  final String pays;
  final String ville;
  final double latitude;
  final double longitude;
  final String auteurUid;
  final String auteurDisplayName;
  final DateTime date;
  final StatutSignalement statut;

  Signalement({
    String? id,
    required this.titre,
    required this.description,
    required this.pays,
    required this.ville,
    required this.latitude,
    required this.longitude,
    required this.auteurUid,
    required this.auteurDisplayName,
    DateTime? date,
    required this.statut,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titre': titre,
      'description': description,
      'pays': pays,
      'ville': ville,
      'latitude': latitude,
      'longitude': longitude,
      'auteurUid': auteurUid,
      'auteurDisplayName': auteurDisplayName,
      'date': Timestamp.fromDate(date),
      'statut': statut.toString().split('.').last,
    };
  }

  factory Signalement.fromMap(Map<String, dynamic> map, String documentId) {
    return Signalement(
      id: documentId,
      titre: map['titre'],
      description: map['description'],
      pays: map['pays'],
      ville: map['ville'],
      latitude: (map['latitude'] as num?)!.toDouble(),
      longitude: (map['longitude'] as num?)!.toDouble(),
      auteurUid: map['auteurUid'],
      auteurDisplayName: map['auteurDisplayName'],
      date: (map['date'] as Timestamp).toDate(),
      statut: StatutExtension.fromString(map['statut']),
    );
  }

  // Méthode copyWith
  Signalement copyWith({
    String? id,
    String? titre,
    String? description,
    String? pays,
    String? ville,
    String? auteurUid,
    String? auteurDisplayName,
    double? latitude,
    double? longitude,
    StatutSignalement? statut,
    DateTime? date,
  }) {
    return Signalement(
      id: id ?? this.id,
      titre: titre ?? this.titre,
      description: description ?? this.description,
      pays: pays ?? this.pays,
      ville: ville ?? this.ville,
      auteurUid: auteurUid ?? this.auteurUid,
      auteurDisplayName: auteurDisplayName ?? this.auteurDisplayName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      statut: statut ?? this.statut,
      date: date ?? this.date,
    );
  }

  String get dateCreationFormatted =>
    DateFormat('dd/MM/yy HH:mm').format(date);

}

enum StatutSignalement {
  aucun,
  nonTraite,
  enCours,
  resolu
}

extension StatutExtension on StatutSignalement {
  String get displayName {
    switch (this) {
      case StatutSignalement.aucun: return 'Aucun';
      case StatutSignalement.nonTraite: return 'Non traité';
      case StatutSignalement.enCours: return 'En cours';
      case StatutSignalement.resolu: return 'Résolu';
    }
  }

  // Pour convertir depuis String (utile pour Firestore)
  static StatutSignalement fromString(String value) {
    return StatutSignalement.values.firstWhere(
      (e) => e.toString().split('.').last == value,
      orElse: () => StatutSignalement.nonTraite,
    );
  }
}
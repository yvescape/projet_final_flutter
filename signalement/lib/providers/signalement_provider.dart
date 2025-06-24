import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/signalement.dart';
import '../services/signalement_service.dart';
import '../services/notification_service.dart';

class SignalementProvider with ChangeNotifier {
  final SignalementService _service = SignalementService();
  final List<Signalement> _tousLesSignalements = [];
  List<Signalement> _signalementsFiltres = [];   
  bool _isLoading = false;

  List<Signalement> get signalements => List.unmodifiable(_signalementsFiltres);
  bool get isLoading => _isLoading;

  /// Récupère tous les signalements
  Future<void> chargerTousLesSignalements() async {
    Future.microtask(() {
      _isLoading = true;
      notifyListeners();
    });

    try {
      final resultats = await _service.getTousLesSignalements();
      _tousLesSignalements
        ..clear()
        ..addAll(resultats);
      _signalementsFiltres = List.from(_tousLesSignalements); // par défaut tout est visible
    } catch (e) {
      print('Erreur lors du chargement des signalements : $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Récupère les signalements de l'utilisateur connecté
  Future<void> chargerSignalements() async {
    final utilisateur = FirebaseAuth.instance.currentUser;
    if (utilisateur == null) return;

    Future.microtask(() {
      _isLoading = true;
      notifyListeners();
    });

    try {
      final resultats = await _service.getSignalementParUtilisateur(utilisateur.uid);
      _tousLesSignalements
        ..clear()
        ..addAll(resultats);
    } catch (e) {
      print('Erreur lors du chargement des signalements utilisateur : $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void filtrerSignalements(String query) {
    if (query.isEmpty) {
      _signalementsFiltres = _tousLesSignalements;
    } else {
      _signalementsFiltres = _tousLesSignalements
          .where((s) => s.titre.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  /// Récupère un signalement par son ID
  Future<Signalement?> getSignalementParId(String id) async {
    return await _service.getSignalementParId(id);
  }

  /// Ajoute un signalement (Firestore + local)
  Future<void> ajouterSignalement(Signalement signalement) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.ajouterSignalement(signalement);
      _tousLesSignalements.add(signalement);
    } catch (e) {
      print('Erreur lors de l\'ajout du signalement : $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Modifie un signalement
  Future<void> modifierSignalement(Signalement signalement) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.modifierSignalement(signalement);

      final index = _tousLesSignalements.indexWhere((s) => s.id == signalement.id);
      if (index != -1) {
        _tousLesSignalements[index] = signalement;
      }

      // 🔔 Notifier les utilisateurs qui ont ce signalement en signet
      await NotificationService.showLocalNotification(
        title: 'Signalement modifié',
        body: 'Vous avez modifié votre signalement.',
        payload: signalement.id, // facultatif, pour redirection
      );
    } catch (e) {
      print('Erreur lors de la modification du signalement : $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Supprime un signalement
  Future<void> supprimerSignalement(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.supprimerSignalement(id);
      _tousLesSignalements.removeWhere((s) => s.id == id);

      // 🔔 Notifier les utilisateurs qui ont ce signalement en signet
      await NotificationService.showLocalNotification(
        title: 'Signalement supprimé',
        body: 'Vous avez supprimé votre signalement.',
      );
    } catch (e) {
      print('Erreur lors de la suppression du signalement : $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Vide la liste locale des signalements
  void reset() {
    _tousLesSignalements.clear();
    notifyListeners();
  }
}

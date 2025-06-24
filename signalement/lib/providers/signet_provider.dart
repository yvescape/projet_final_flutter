import 'package:flutter/material.dart';
import '../models/signalement.dart';
import '../services/signet_service.dart';

class SignetProvider with ChangeNotifier {
  final List<Signalement> _tousLesSignets = [];
  List<Signalement> _signetsFiltres = [];
  bool _isLoading = false;

  List<Signalement> get signalementsSignets => List.unmodifiable(_signetsFiltres);
  bool get isLoading => _isLoading;

  Future<void> chargerMesSignets() async {
    Future.microtask(() {
      _isLoading = true;
      notifyListeners();
    });

    try {
      _tousLesSignets.clear();
      _signetsFiltres.clear();

      final signetService = SignetService();
      final signalementIds = await signetService.getMesSignetsIds();
      
      if (signalementIds.isNotEmpty) {
        final signalements = await signetService.getSignalementsFromIds(signalementIds);
        _tousLesSignets.addAll(signalements);
        _signetsFiltres = List.from(_tousLesSignets); // copie pour affichage initial
      }
    } catch (e) {
      debugPrint('Erreur chargement signets: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void filtrerSignets(String query) {
    if (query.trim().isEmpty) {
      _signetsFiltres = List.from(_tousLesSignets);
    } else {
      final lowerQuery = query.toLowerCase();
      _signetsFiltres = _tousLesSignets
          .where((s) => s.titre.toLowerCase().contains(lowerQuery))
          .toList();
    }
    notifyListeners();
  }

  Future<void> ajouterSignet(String signalementId) async {
    try {
      await SignetService().ajouterSignet(signalementId);
      await chargerMesSignets(); // recharge et met à jour les deux listes
    } catch (e) {
      debugPrint('Erreur ajout signet: $e');
      rethrow;
    }
  }

  Future<void> supprimerSignet(String signalementId) async {
    try {
      await SignetService().supprimerSignet(signalementId);
      _tousLesSignets.removeWhere((s) => s.id == signalementId);
      _signetsFiltres.removeWhere((s) => s.id == signalementId);
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur suppression signet: $e');
      rethrow;
    }
  }

  bool estDansSignets(String signalementId) {
    return _tousLesSignets.any((s) => s.id == signalementId);
  }
}

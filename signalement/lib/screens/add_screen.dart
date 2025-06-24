import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';

import '../providers/signalement_provider.dart';
import '../providers/auth_provider.dart' as myAuth;
import '../models/signalement.dart';
import '../providers/location_provider.dart';
import '../utils/statut_signalement.dart';

class AddScreen extends StatefulWidget {
  final Signalement? signalementExist; // signalement à modifier

  const AddScreen({super.key, this.signalementExist});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titreController = TextEditingController();
  final _paysController = TextEditingController();
  final _villeController = TextEditingController();
  final _descriptionController = TextEditingController();

  StatutSignalement _selectedStatut = StatutSignalement.aucun;
  late bool isUpdateMode;
  late Signalement? signalement;

  @override
  void initState() {
    super.initState();

    signalement = widget.signalementExist;
    isUpdateMode = signalement != null;

    if (isUpdateMode) {
      _titreController.text = signalement!.titre;
      _paysController.text = signalement!.pays;
      _villeController.text = signalement!.ville;
      _descriptionController.text = signalement!.description;
      _selectedStatut = signalement!.statut;
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleText = isUpdateMode
        ? 'Modifier le signalement'
        : 'Créer un signalement';
    final buttonText = isUpdateMode ? 'Modifier' : 'Ajouter';

    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: Column(
                children: [
                  Text(
                    titleText,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.all(10),
                        children: [
                          _buildTextField(_titreController, 'Titre', 6),
                          const SizedBox(height: 20),
                          _buildTextField(_paysController, 'Pays'),
                          const SizedBox(height: 20),
                          _buildTextField(_villeController, 'Ville'),
                          const SizedBox(height: 20),
        
                          DropdownButtonFormField<StatutSignalement>(
                            value: _selectedStatut,
                            decoration: _inputDecoration('Statut'),
                            items: StatutSignalement.values.map((statut) {
                              return DropdownMenuItem(
                                value: statut,
                                child: Text(statut.displayName),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedStatut = value);
                              }
                            },
                            validator: (value) => value == null
                                ? 'Veuillez sélectionner un statut'
                                : null,
                          ),
                          const SizedBox(height: 20),
        
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 5,
                            decoration: InputDecoration(
                              labelText: 'Description',
                              alignLabelWithHint: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Veuillez entrer une description';
                              if (value.length < 16)
                                return 'Minimum 16 caractères';
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),
        
                          Center(
                            child: ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  if (isUpdateMode) {
                                    _modifierSignalement();
                                  } else {
                                    _showLocalisationSourceDialog(); // création
                                  }
                                }
                              },
                              child: Text(
                                buttonText,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, [
    int minLength = 1,
  ]) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration(label),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Veuillez entrer $label';
        if (value.length < minLength) return 'Minimum $minLength caractères';
        return null;
      },
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Future<void> _modifierSignalement() async {
    final provider = Provider.of<SignalementProvider>(context, listen: false);

    final modifie = signalement!.copyWith(
      titre: _titreController.text.trim(),
      pays: _paysController.text.trim(),
      ville: _villeController.text.trim(),
      description: _descriptionController.text.trim(),
      statut: _selectedStatut,
    );

    try {
      await provider.modifierSignalement(modifie);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Signalement modifié')));
      context.go('/');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  Future<void> _showLocalisationSourceDialog() async {
    final choix = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Choisir la source de la localisation"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.my_location),
              title: const Text('Utiliser ma position actuelle'),
              onTap: () => Navigator.pop(context, 'current'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Choisir sur la carte'),
              onTap: () => Navigator.pop(context, 'map'),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Annuler'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );

    LatLng? finalPosition;

    if (choix == 'current') {
      final geoPosition = Provider.of<LocationProvider>(
        context,
        listen: false,
      ).position;
      if (geoPosition != null) {
        finalPosition = LatLng(geoPosition.latitude, geoPosition.longitude);
        print(
          "Position actuelle : ${finalPosition.latitude}, ${finalPosition.longitude}",
        );
      }
    } else if (choix == 'map') {
      final selectedPosition = await context.push<LatLng>('/map');
      if (selectedPosition != null) {
        finalPosition = selectedPosition;
        print(
          "Position choisie sur la carte : ${finalPosition.latitude}, ${finalPosition.longitude}",
        );
      }
    }

    // Si position ok, on soumet le formulaire avec les coordonnées
    if (finalPosition != null) {
      await _submitForm(finalPosition.latitude, finalPosition.longitude);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Localisation non définie')));
    }
  }

  Future<void> _submitForm(double latitude, double longitude) async {
    if (!_formKey.currentState!.validate()) return;

    final user = Provider.of<myAuth.AuthProvider>(context, listen: false).user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur : utilisateur non connecté')),
      );
      context.push('/login');
      return;
    }

    final nouveauSignalement = Signalement(
      titre: _titreController.text.trim(),
      description: _descriptionController.text.trim(),
      pays: _paysController.text.trim(),
      ville: _villeController.text.trim(),
      latitude: latitude,
      longitude: longitude,
      auteurUid: user.uid,
      auteurDisplayName: user.displayName ?? 'Utilisateur inconnu',
      statut: _selectedStatut,
    );

    try {
      await Provider.of<SignalementProvider>(
        context,
        listen: false,
      ).ajouterSignalement(nouveauSignalement);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signalement ajouté avec succès')),
      );

      context.go('/'); // Fermer la page après ajout
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      print(e);
    }
  }
}

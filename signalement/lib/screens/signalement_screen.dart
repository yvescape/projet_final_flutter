import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../components/custom_app_bar.dart';
import '../models/signalement.dart';
import '../providers/signalement_provider.dart';
import '../providers/signet_provider.dart';
import '../utils/statut_signalement.dart';
import '../providers/auth_provider.dart' as myAuth;

class SignalementScreen extends StatefulWidget {
  final String signalementId;
  const SignalementScreen({super.key, required this.signalementId});

  @override
  State<SignalementScreen> createState() => _SignalementScreenState();
}

class _SignalementScreenState extends State<SignalementScreen> {
  Signalement? _signalement;
  bool _isLoading = true;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadSignalement();
  }

  Future<void> _loadSignalement() async {
    try {
      final provider = Provider.of<SignalementProvider>(context, listen: false);
      final result = await provider.getSignalementParId(widget.signalementId);

      if (mounted) {
        setState(() {
          _signalement = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<myAuth.AuthProvider>(context).user;
    final estAuteur = user != null && _signalement != null && user.uid == _signalement!.auteurUid;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const CustomAppBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _signalement == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Signalement non trouvé'),
                              TextButton(
                                onPressed: _loadSignalement,
                                child: const Text('Réessayer'),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(10.0),
                          child: Container(
                            padding: EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // En-tête avec titre et actions
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          _signalement!.titre,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (estAuteur) ...[
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            onPressed: () => context.replace(
                                              '/edit',
                                              extra: _signalement,
                                            ),
                                          ),
                                          IconButton(
                                            icon: _isDeleting
                                                ? const CircularProgressIndicator()
                                                : const Icon(Icons.delete),
                                            onPressed: _isDeleting
                                                ? null
                                                : () => _confirmAndDeleteSignalement(
                                                      context,
                                                      _signalement!.id,
                                                    ),
                                          ),
                                        ] else
                                          Consumer<SignetProvider>(
                                            builder: (context, signetProvider, _) {
                                              final isBookmarked = signetProvider.estDansSignets(_signalement!.id);
                                              return IconButton(
                                                icon: Icon(
                                                  isBookmarked
                                                      ? Icons.bookmark
                                                      : Icons.bookmark_outline,
                                                  color: isBookmarked ? Colors.deepPurple : null,
                                                ),
                                                onPressed: () async {
                                                  try {
                                                    if (isBookmarked) {
                                                      await signetProvider.supprimerSignet(_signalement!.id);
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(content: Text('Retiré des signets')),
                                                      );
                                                    } else {
                                                      await signetProvider.ajouterSignet(_signalement!.id);
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(content: Text('Ajouté aux signets')),
                                                      );
                                                    }
                                                  } catch (e) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('Erreur: ${e.toString()}')),
                                                    );
                                                  }
                                                },
                                              );
                                            },
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                            
                                // Localisation et statut
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${_signalement!.ville}, ${_signalement!.pays}',
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                      if (_signalement!.statut != StatutSignalement.aucun)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getStatutColor(_signalement!.statut)
                                                .withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            _getStatutText(_signalement!.statut),
                                            style: TextStyle(
                                              color: _getStatutColor(_signalement!.statut),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                            
                                // Description
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Text(
                                    _signalement!.description,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                            
                                // Images (à implémenter)
                                // if (_signalement!.images.isNotEmpty) ...[
                                //   SizedBox(
                                //     height: 150,
                                //     child: ListView.builder(
                                //       scrollDirection: Axis.horizontal,
                                //       itemCount: _signalement!.images.length,
                                //       itemBuilder: (context, index) => Padding(
                                //         padding: const EdgeInsets.only(right: 8),
                                //         child: Image.network(_signalement!.images[index]),
                                //       ),
                                //     ),
                                //   ),
                                //   const SizedBox(height: 16),
                                // ],
                            
                                // Métadonnées
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _signalement!.dateCreationFormatted,
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                      Text(
                                        _signalement!.auteurDisplayName,
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _signalement == null
            ? null
            : () {
                context.push(
                  '/map/view',
                  extra: _signalement,
                );
              },
        child: const Icon(Icons.location_on),
      ),
    );
  }

  Future<void> _confirmAndDeleteSignalement(BuildContext context, String signalementId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text(
            'Voulez-vous vraiment supprimer ce signalement ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        setState(() => _isDeleting = true);
        await Provider.of<SignalementProvider>(context, listen: false)
            .supprimerSignalement(signalementId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Signalement supprimé avec succès')),
          );
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de la suppression : ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isDeleting = false);
        }
      }
    }
  }

  String _getStatutText(StatutSignalement statut) {
    switch (statut) {
      case StatutSignalement.nonTraite:
        return 'Non traité';
      case StatutSignalement.enCours:
        return 'En cours';
      case StatutSignalement.resolu:
        return 'Terminé';
      case StatutSignalement.aucun:
        return '';
    }
  }

  Color _getStatutColor(StatutSignalement statut) {
    switch (statut) {
      case StatutSignalement.nonTraite:
        return Colors.red;
      case StatutSignalement.enCours:
        return Colors.orange;
      case StatutSignalement.resolu:
        return Colors.green;
      case StatutSignalement.aucun:
        return Colors.transparent;
    }
  }
}
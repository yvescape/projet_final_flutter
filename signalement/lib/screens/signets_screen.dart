import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../providers/signet_provider.dart';
import '../models/signalement.dart';
import '../components/custom_app_bar.dart';
import '../utils/statut_signalement.dart';

class SignetsScreen extends StatefulWidget {
  const SignetsScreen({super.key});

  @override
  State<SignetsScreen> createState() => _SignetsScreenState();
}

class _SignetsScreenState extends State<SignetsScreen> {
  @override
  void initState() {
    super.initState();
    _chargerSignets();
  }

  Future<void> _chargerSignets() async {
    final provider = Provider.of<SignetProvider>(context, listen: false);
    await provider.chargerMesSignets();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: CustomAppBar(
                onSearchChanged: (query) {
                  Provider.of<SignetProvider>(
                    context,
                    listen: false,
                  ).filtrerSignets(query);
                },
              ),
            ),
            Expanded(
              child: Consumer<SignetProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final signets = provider.signalementsSignets;

                  return RefreshIndicator(
                    onRefresh: _chargerSignets,
                    child: signets.isEmpty
                        ? const Center(
                            child: Text(
                              'Vous n\'avez créé aucun signet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(10),
                            itemCount: signets.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final s = signets[index];
                              return _buildSignalementItem(s, provider);
                            },
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignalementItem(Signalement s, SignetProvider provider) {
    return GestureDetector(
      onTap: () => context.push('/signalement/${s.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      s.titre,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.bookmark),
                        color: Colors.deepPurple,
                        onPressed: () {
                          _confirmerEtSupprimerSignet(context, s.id);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.location_on),
                        color: Colors.deepPurple,
                        onPressed: () {
                          context.push('/map/view', extra: s);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                s.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${s.ville}, ${s.pays}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  if (s.statut != StatutSignalement.aucun)
                    Text(
                      _getStatutText(s.statut),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatutColor(s.statut),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmerEtSupprimerSignet(
    BuildContext context,
    String signalementId,
  ) async {
    final provider = Provider.of<SignetProvider>(context, listen: false);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text(
          'Voulez-vous vraiment retirer ce signalement des signets ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await provider.supprimerSignet(signalementId);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Retiré des signets')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
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

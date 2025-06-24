import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../providers/signalement_provider.dart';
import '../models/signalement.dart';
import '../components/custom_app_bar.dart';
import '../utils/statut_signalement.dart';

class MesSignalementsScreen extends StatefulWidget {
  const MesSignalementsScreen({super.key});

  @override
  State<MesSignalementsScreen> createState() => _MesSignalementsScreenState();
}

class _MesSignalementsScreenState extends State<MesSignalementsScreen> {
  late final User? user;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    // Charger les données au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SignalementProvider>(context, listen: false).chargerSignalements();
    });
  }

  Future<void> _refreshSignalements() async {
    await Provider.of<SignalementProvider>(context, listen: false).chargerSignalements();
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
                onSearchChanged:  (query) {
                  Provider.of<SignalementProvider>(context, listen: false).filtrerSignalements(query);
                },
              ),
            ),
            Expanded(
              child: Consumer<SignalementProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Filtrer les signalements pour n'avoir que ceux de l'utilisateur connecté
                  final mesSignalements = provider.signalements
                      .where((s) => s.auteurUid == user?.uid)
                      .toList();

                  if (mesSignalements.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: _refreshSignalements,
                      child: ListView(
                        children: const [
                          SizedBox(height: 100),
                          Center(
                            child: Text(
                              'Vous n\'avez créé aucun signalement',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _refreshSignalements,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(10),
                      itemCount: mesSignalements.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final s = mesSignalements[index];
                        return _buildSignalementItem(s);
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

  Widget _buildSignalementItem(Signalement s) {
    return GestureDetector(
      onTap: () => context.push('/signalement/${s.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
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
                  IconButton(
                    icon: const Icon(Icons.location_on),
                    color: Colors.deepPurple,
                    onPressed: () {
                      context.push('/map/view', extra: s);
                    },
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

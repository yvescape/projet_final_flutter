import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../providers/signalement_provider.dart';
import '../providers/signet_provider.dart';
import '../utils/statut_signalement.dart';
import '../components/custom_app_bar.dart';
import '../models/signalement.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final User? user;
  // User? _lastUser;

  @override
  void initState() {
    super.initState();
    _chargerSignalements();

    user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<SignetProvider>(context, listen: false).chargerMesSignets();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final _currentUser = FirebaseAuth.instance.currentUser;
    
    if (_currentUser != null) {
      _chargerSignalements();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<SignetProvider>(context, listen: false).chargerMesSignets();
      });
    } else {
      _chargerSignalements();
    }
  }

  Future<void> _chargerSignalements() async {
    final provider = Provider.of<SignalementProvider>(context, listen: false);
    await provider.chargerTousLesSignalements();
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
                  Provider.of<SignalementProvider>(
                    context,
                    listen: false,
                  ).filtrerSignalements(query);
                },
              ),
            ),
            Expanded(
              child: Consumer2<SignalementProvider, SignetProvider>(
                builder: (context, signalementProvider, signetProvider, _) {
                  if (signalementProvider.isLoading ||
                      signetProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final signalements = signalementProvider.signalements;

                  return RefreshIndicator(
                    onRefresh: () async {
                      await signalementProvider.chargerTousLesSignalements();
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        await signetProvider.chargerMesSignets();
                      }
                    },
                    child: signalements.isEmpty
                        ? const Center(
                            child: Text(
                              'Aucun signalement trouvé',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(10),
                            itemCount: signalements.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final user = FirebaseAuth.instance.currentUser;
                              final s = signalements[index];
                              final signetIds = _getSignetIds(
                                signetProvider,
                              ); // ✅
                              final estSignet = signetIds.contains(s.id);
                              final estAuteur =
                                  user != null && s.auteurUid == user.uid;
                              return _buildSignalementItem(
                                s,
                                estSignet,
                                estAuteur,
                              );
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

  Widget _buildSignalementItem(Signalement s, bool estSignet, bool estAuteur) {
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
                      if (!estAuteur) _buildSignetButton(s.id),

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

  Set<String> _getSignetIds(SignetProvider provider) {
    final user = FirebaseAuth.instance.currentUser;
    return user != null
        ? provider.signalementsSignets.map((s) => s.id).toSet()
        : <String>{};
  }

  Widget _buildSignetButton(String signalementId) {
    final user = FirebaseAuth.instance.currentUser;

    // Si l'utilisateur n'est pas connecté, montrer un bouton qui redirige vers le login
    if (user == null) {
      return IconButton(
        icon: const Icon(Icons.bookmark_border, color: Colors.grey),
        onPressed: () => context.push('/login'),
      );
    }

    // Si l'utilisateur est connecté, consommer le provider et gérer l'état
    return Consumer<SignetProvider>(
      builder: (context, signetProvider, _) {
        final isSignet = signetProvider.estDansSignets(signalementId);

        return IconButton(
          icon: Icon(
            isSignet ? Icons.bookmark : Icons.bookmark_border,
            color: isSignet ? Colors.deepPurple : Colors.grey,
          ),
          onPressed: () async {
            try {
              if (isSignet) {
                await signetProvider.supprimerSignet(signalementId);
              } else {
                await signetProvider.ajouterSignet(signalementId);
              }

              if (!context.mounted) return; // Sécurise l'accès au context
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isSignet ? 'Signet supprimé' : 'Signet ajouté'),
                ),
              );
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erreur: ${e.toString()}')),
              );
            }
          },
        );
      },
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

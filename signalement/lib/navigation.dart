import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importez Firebase Auth

class RootScreen extends StatelessWidget {
  final Widget child;
  const RootScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    int currentIndex = _locationToTabIndex(location);
    final user = FirebaseAuth.instance.currentUser; // Vérifiez l'état de connexion

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: BottomNavigationBar(
          elevation: 10,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.deepPurple,
          unselectedItemColor: Colors.deepPurple,
          currentIndex: currentIndex,
          onTap: (index) async {
            // Gestion spéciale pour l'onglet Profil
            if (index == 4 && user == null) {
              context.go('/login');
              return;
            }

            switch (index) {
              case 0:
                context.go('/');
                break;
              case 1:
                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez vous connecter pour accéder à cette fonctionnalité')),
                  );
                  context.go('/login');
                } else {
                  context.go('/signets');
                }
                break;
              case 2:
                  context.go('/add');
                break;
              case 3:
                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez vous connecter pour accéder à cette fonctionnalité')),
                  );
                  context.go('/login');
                } else {
                  context.go('/mes_signalements');
                }
                break;
              case 4:
                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez vous connecter pour accéder à cette fonctionnalité')),
                  );
                  context.go('/login');
                } else {
                  context.go('/profile');
                }
                break;
            }
          },
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
            BottomNavigationBarItem(
              icon: const Icon(Icons.bookmark),
              label: 'Signets',
            ),
            BottomNavigationBarItem(
              icon: Icon(location == '/edit' ? Icons.edit : Icons.add_circle),
              label: (location == '/edit') ? 'Modifier' : 'Ajouter',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.list_alt),
              label: 'Mes signalements',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }

  int _locationToTabIndex(String location) {
    if (location == '/signets') return 1;
    if (location == '/add' || location == '/edit') return 2;
    if (location == '/mes_signalements') return 3;
    if (location == '/profile') return 4;
    return 0;
  }
}
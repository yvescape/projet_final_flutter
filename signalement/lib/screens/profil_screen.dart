import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../providers/auth_provider.dart' as myAuth;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  late User _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = Provider.of<myAuth.AuthProvider>(context, listen: false).user!;
  }

  Future<void> _signOut() async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<myAuth.AuthProvider>(context, listen: false).signOut();
      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePhoto() async {
    // TODO: Implémenter la logique de mise à jour de photo
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité de mise à jour de photo à implémenter'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ), 
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Section Photo de profil
            Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: _currentUser.photoURL != null
                          ? NetworkImage(_currentUser.photoURL!)
                          : null,
                      child: _currentUser.photoURL == null
                          ? const Icon(Icons.person, size: 60)
                          : null,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: _updatePhoto,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Modifier la photo',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Section Informations utilisateur
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow(
                      'Nom complet',
                      _currentUser.displayName ?? 'Non défini',
                    ),
                    const Divider(),
                    _buildInfoRow('Email', _currentUser.email ?? 'Non défini'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Boutons d'actions
            Column(
              children: [
                _buildActionButton(
                  icon: Icons.edit,
                  label: 'Modifier les informations',
                  onPressed: () => context.push('/profile/edit'),
                ),
                const SizedBox(height: 10),
                _buildActionButton(
                  icon: Icons.lock,
                  label: 'Modifier le mot de passe',
                  onPressed: () => context.push('/profile/change-password'),
                ),
                const SizedBox(height: 10),
                _buildActionButton(
                  icon: Icons.logout,
                  label: 'Déconnexion',
                  color: Colors.red,
                  textColor: Colors.white,
                  onPressed: _signOut,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            '$label : ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color color = Colors.white,
    Color textColor = Colors.black,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          foregroundColor: textColor,
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: color == Colors.white
                ? const BorderSide(color: Colors.grey)
                : BorderSide.none,
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}

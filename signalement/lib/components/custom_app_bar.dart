import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart' as myAuth;

class CustomAppBar extends StatelessWidget {
  final ValueChanged<String>? onSearchChanged;
  final bool showSearchField;
  final User? user;

  const CustomAppBar({
    super.key,
    this.onSearchChanged,
    this.showSearchField = true,
    this.user,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = Provider.of<myAuth.AuthProvider>(context).user;

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: theme.appBarTheme.backgroundColor ?? Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            if (user != null) _buildUserAvatar(context, user),
            if (showSearchField) _buildSearchField(context),
            _buildAuthButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar(BuildContext context, User user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: () => context.push('/profile'),
        child: CircleAvatar(
          radius: 15,
          child: user.photoURL == null
              ? const Icon(Icons.person, size: 20)
              : null,
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          height: 36,
          child: TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Recherche...',
              isDense: true,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthButton(BuildContext context) {
    final user = Provider.of<myAuth.AuthProvider>(context).user;

    return user == null
        ? IconButton(
            icon: const Icon(Icons.login, color: Colors.grey, size: 23),
            onPressed: () => context.go('/login'),
          )
        : IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey, size: 23),
            onPressed: () => _confirmerDeconnecter(context),
          );
  }

  Future<void> _signOut(BuildContext context) async {
    final auth = Provider.of<myAuth.AuthProvider>(context, listen: false);
    await auth.signOut();
      context.go('/login');
  }

  Future<void> _confirmerDeconnecter(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Se déconnecter',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _signOut(context);
    }
  }
}

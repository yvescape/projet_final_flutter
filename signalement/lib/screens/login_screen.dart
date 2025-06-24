import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart' as myAuth;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLoading = false;
  String? _messageErreur;
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          // Pour gérer le clavier
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Connexion',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),

                if (_messageErreur != null) ...[
                  Text(
                    _messageErreur!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                ],

                // Email input
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre email';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Email invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Mot de passe input
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Mot de Passe',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre mot de passe';
                    }
                    if (value.length < 6) {
                      return 'Minimum 6 caractères';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 25),

                // Boutons Retour & Connexion sur une ligne
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          context.go('/');
                        },
                        child: const Text('Retour'),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _submitForm();
                          }
                        },
                        child: const Text('Connexion'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Trois CircleAvatar sur une ligne
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircleAvatar(
                      radius: 25,
                      backgroundImage: AssetImage('assets/images/google.jpg'),
                    ),
                    SizedBox(width: 20),
                    CircleAvatar(
                      radius: 25,
                      backgroundImage: AssetImage('assets/images/facebook.png'),
                    ),
                    SizedBox(width: 20),
                    CircleAvatar(
                      radius: 25,
                      backgroundImage: AssetImage('assets/images/x.png'),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Textes "Mot de passe oublié" et "Inscription"
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        // TODO: action mot de passe oublié
                      },
                      child: const Text('Mot de passe oublié ?'),
                    ),
                    TextButton(
                      onPressed: () {
                        context.push('/register');
                      },
                      child: const Text('Inscription'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    // Traitement des données
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      isLoading = true;
      _messageErreur = null;
    });

    try {
      await Provider.of<myAuth.AuthProvider>(
        context,
        listen: false,
      ).signIn(email: email, password: password);

      
      context.go('/');
      
    } on FirebaseAuthException catch (e) {
      String message;

      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'Email ou mot de passe incorrect.';
      } else {
        message = 'Une erreur est survenue. Veuillez réessayer.';
      }

      setState(() {
        _messageErreur = message;
      });
      print('Erreur: ${e.toString()}');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}

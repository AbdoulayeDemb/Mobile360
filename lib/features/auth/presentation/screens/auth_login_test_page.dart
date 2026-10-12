import 'package:flutter/material.dart';

import '../../data/repositories/auth_repository.dart';

class AuthLoginTestPage extends StatefulWidget {
  const AuthLoginTestPage({super.key});

  @override
  State<AuthLoginTestPage> createState() => _AuthLoginTestPageState();
}

class _AuthLoginTestPageState extends State<AuthLoginTestPage> {
  final _formKey = GlobalKey<FormState>();
  final _telephoneController = TextEditingController();
  final _motDePasseController = TextEditingController();
  final _repository = AuthRepository();

  bool _loading = false;
  bool _obscurePassword = true;
  String? _message;
  bool _success = false;

  Future<void> _testerConnexion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final auth = await _repository.login(
        telephone: _telephoneController.text.trim(),
        motDePasse: _motDePasseController.text,
      );

      if (!mounted) return;

      setState(() {
        _success = true;
        _message =
            'Connexion réussie !\n'
            'Utilisateur : ${auth.prenom ?? ''} ${auth.nom ?? ''}\n'
            'Identifiant : ${auth.idUtilisateur ?? 'Non fourni'}\n'
            'Rôle : ${auth.role ?? 'Non fourni'}\n'
            'Jeton enregistré : oui';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _success = false;
        _message = 'Échec de la connexion : $error';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _telephoneController.dispose();
    _motDePasseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test de connexion citoyen')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.lock_outline, size: 56),
                  const SizedBox(height: 16),
                  const Text(
                    'Tester /api/auth/login',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _telephoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Téléphone',
                      hintText: 'Numéro du compte de test',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final telephone = value?.trim() ?? '';
                      if (!RegExp(r'^[0-9]{8,15}$').hasMatch(telephone)) {
                        return 'Saisis entre 8 et 15 chiffres.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _motDePasseController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Saisis le mot de passe du compte de test.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loading ? null : _testerConnexion,
                    child: Text(
                      _loading
                          ? 'Connexion en cours...'
                          : 'Tester la connexion',
                    ),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 20),
                    SelectableText(
                      _message!,
                      style: TextStyle(
                        color: _success
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

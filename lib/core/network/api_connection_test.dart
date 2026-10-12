import 'package:flutter/material.dart';

import 'api_service.dart';

class ApiConnectionTest extends StatefulWidget {
  const ApiConnectionTest({super.key});

  @override
  State<ApiConnectionTest> createState() => _ApiConnectionTestState();
}

class _ApiConnectionTestState extends State<ApiConnectionTest> {
  String message = 'Appuie sur le bouton pour tester l’API.';
  bool loading = false;

  Future<void> testApi() async {
    setState(() {
      loading = true;
      message = 'Connexion en cours...';
    });

    try {
      final result = await ApiService.testConnection();

      if (!mounted) return;

      setState(() {
        message = 'Réponse du serveur :\n$result';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        message = 'Échec de la connexion :\n$error';
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test API Alert360')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: loading ? null : testApi,
                child: Text(
                  loading ? 'Test en cours...' : 'Tester la connexion',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

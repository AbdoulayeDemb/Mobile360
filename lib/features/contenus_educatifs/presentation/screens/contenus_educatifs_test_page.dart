import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/contenu_educatif_provider.dart';

class ContenusEducatifsTestPage extends ConsumerWidget {
  const ContenusEducatifsTestPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contenusAsync = ref.watch(contenusEducatifsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test des contenus éducatifs'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: () => ref.invalidate(contenusEducatifsProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: contenusAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 40),
                const SizedBox(height: 12),
                const Text(
                  'Impossible de récupérer les contenus éducatifs.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(contenusEducatifsProvider),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (contenus) {
          if (contenus.isEmpty) {
            return const Center(
              child: Text('Aucun contenu éducatif disponible.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: contenus.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, index) {
              final contenu = contenus[index];

              return ListTile(
                leading: Icon(switch (contenu.format.toUpperCase()) {
                  'AUDIO' => Icons.headphones,
                  'VIDEO' => Icons.play_circle_outline,
                  'IMAGE' => Icons.image_outlined,
                  _ => Icons.school_outlined,
                }),
                title: Text(contenu.titre),
                subtitle: Text(
                  'Thème : ${contenu.theme}\n'
                  'Format : ${contenu.format}\n'
                  'Auteur : ${contenu.nomAuteur ?? 'Non renseigné'}',
                ),
                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }
}

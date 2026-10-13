import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/actualite_provider.dart';

class ActualitesTestPage extends ConsumerWidget {
  const ActualitesTestPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actualitesAsync = ref.watch(actualitesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test des actualités'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: () => ref.invalidate(actualitesProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: actualitesAsync.when(
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
                  'Impossible de récupérer les actualités.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(actualitesProvider),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (actualites) {
          if (actualites.isEmpty) {
            return const Center(child: Text('Aucune actualité disponible.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: actualites.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, index) {
              final actualite = actualites[index];

              return ListTile(
                leading: Icon(
                  actualite.estUrgent
                      ? Icons.warning_amber_rounded
                      : Icons.article_outlined,
                  color: actualite.estUrgent ? Colors.red : null,
                ),
                title: Text(actualite.titre),
                subtitle: Text(
                  actualite.corpsTexte,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: actualite.estUrgent
                    ? const Chip(label: Text('Urgent'))
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}

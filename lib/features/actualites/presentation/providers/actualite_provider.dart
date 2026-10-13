import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/actualite.dart';
import '../../data/repositories/actualite_repository.dart';

/// Fournisseur du repository des actualités.
final actualiteRepositoryProvider = Provider<ActualiteRepository>((ref) {
  return ActualiteRepository();
});

/// Récupère la liste des actualités depuis le backend.
final actualitesProvider = FutureProvider<List<Actualite>>((ref) {
  return ref.watch(actualiteRepositoryProvider).getActualites();
});

/// Récupère une actualité à partir de son identifiant.
final actualiteDetailProvider = FutureProvider.family<Actualite, int>((
  ref,
  idActualite,
) {
  return ref.watch(actualiteRepositoryProvider).getActualiteById(idActualite);
});

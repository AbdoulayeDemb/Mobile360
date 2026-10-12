import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/actualite.dart';
import '../../data/repositories/actualite_repository.dart';

final actualiteRepositoryProvider = Provider<ActualiteRepository>((ref) {
  return ActualiteRepository();
});

final actualitesProvider = FutureProvider<List<Actualite>>((ref) {
  return ref.watch(actualiteRepositoryProvider).getActualites();
});

final actualiteDetailProvider = FutureProvider.family<Actualite, int>((
  ref,
  idActualite,
) {
  return ref.watch(actualiteRepositoryProvider).getActualiteById(idActualite);
});

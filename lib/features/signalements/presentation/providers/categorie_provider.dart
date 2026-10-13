import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/categorie.dart';
import '../../data/repositories/categorie_repository.dart';

/// Fournit le repository des catégories.
final categorieRepositoryProvider = Provider<CategorieRepository>((ref) {
  return CategorieRepository();
});

/// Charge la liste des catégories depuis le backend.
final categoriesProvider = FutureProvider<List<Categorie>>((ref) {
  return ref.watch(categorieRepositoryProvider).getCategories();
});

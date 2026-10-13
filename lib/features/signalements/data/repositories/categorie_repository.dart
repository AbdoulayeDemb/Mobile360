import '../../../../core/errors/api_exception.dart';
import '../models/categorie.dart';
import '../services/categorie_service.dart';

class CategorieRepository {
  final CategorieService _categorieService;

  CategorieRepository({CategorieService? categorieService})
    : _categorieService = categorieService ?? CategorieService();

  Future<List<Categorie>> getCategories() async {
    try {
      final response = await _categorieService.getCategories();

      if (response is! List) {
        throw ApiException(
          message: 'Format de réponse invalide pour les catégories.',
        );
      }

      return response
          .map(
            (item) =>
                Categorie.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    } catch (error) {
      if (error is ApiException) rethrow;

      throw ApiException(message: 'Impossible de récupérer les catégories.');
    }
  }
}

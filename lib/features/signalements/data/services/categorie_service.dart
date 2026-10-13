import '../../../../core/network/api_service.dart';

class CategorieService {
  /// Récupère toutes les catégories de signalements.
  Future<dynamic> getCategories() {
    return ApiService.get('/api/categories');
  }
}

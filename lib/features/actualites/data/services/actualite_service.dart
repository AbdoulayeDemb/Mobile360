import '../../../../core/network/api_service.dart';

class ActualiteService {
  Future<dynamic> getActualites() {
    return ApiService.get('/api/actualites');
  }

  Future<dynamic> getActualiteById(int idActualite) {
    return ApiService.get('/api/actualites/$idActualite');
  }

  Future<dynamic> publierActualite({required Map<String, dynamic> data}) {
    return ApiService.post('/api/actualites', data: data);
  }

  Future<dynamic> modifierActualite({
    required int idActualite,
    required Map<String, dynamic> data,
  }) {
    return ApiService.put('/api/actualites/$idActualite', data: data);
  }

  Future<void> supprimerActualite(int idActualite) {
    return ApiService.delete('/api/actualites/$idActualite');
  }
}

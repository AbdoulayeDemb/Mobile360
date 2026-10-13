import '../../../../core/network/api_service.dart';

class ActualiteService {
  Future<dynamic> getActualites() {
    return ApiService.get('/api/actualites');
  }

  Future<dynamic> getActualiteById(int idActualite) {
    return ApiService.get('/api/actualites/$idActualite');
  }
}

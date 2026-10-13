import '../../../../core/network/api_service.dart';

class ContenuEducatifService {
  Future<dynamic> getContenusEducatifs() {
    return ApiService.get('/api/contenus');
  }

  Future<dynamic> getContenuEducatifById(int idContenu) {
    return ApiService.get('/api/contenus/$idContenu');
  }
}

import '../../../../core/network/api_service.dart';

class AgentNotificationService {
  Future<dynamic> getMesNotifications() {
    return ApiService.get('/api/notifications/mes');
  }

  Future<dynamic> marquerCommeLue(int idNotification) {
    return ApiService.patch('/api/notifications/$idNotification/lue');
  }
}

import '../../../../core/errors/api_exception.dart';
import '../models/agent_notification.dart';
import '../services/agent_notification_service.dart';

class AgentNotificationRepository {
  final AgentNotificationService _service;

  AgentNotificationRepository({AgentNotificationService? service})
    : _service = service ?? AgentNotificationService();

  Future<List<AgentNotification>> getMesNotifications() async {
    final response = await _service.getMesNotifications();

    if (response is! List) {
      throw ApiException(
        message: 'Format de réponse invalide pour les notifications.',
      );
    }

    return response.map((item) {
      if (item is! Map) {
        throw ApiException(message: 'Une notification reçue est invalide.');
      }

      return AgentNotification.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  Future<void> marquerCommeLue(int idNotification) async {
    await _service.marquerCommeLue(idNotification);
  }
}

import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationRepository {
  final NotificationService _notificationService;

  NotificationRepository(this._notificationService);

  Future<List<NotificationModel>> getMesNotifications() {
    return _notificationService.getMesNotifications();
  }

  Future<List<NotificationModel>> getNotificationsNonLues() {
    return _notificationService.getNotificationsNonLues();
  }

  Future<int> compterNonLues() {
    return _notificationService.compterNonLues();
  }

  Future<void> marquerCommeLue(int idNotification) {
    return _notificationService.marquerCommeLue(idNotification);
  }

  Future<void> marquerToutesCommeLues() {
    return _notificationService.marquerToutesCommeLues();
  }
}

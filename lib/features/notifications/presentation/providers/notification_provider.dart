import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/services/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(notificationServiceProvider));
});

final mesNotificationsProvider = FutureProvider<List<NotificationModel>>((ref) {
  return ref.watch(notificationRepositoryProvider).getMesNotifications();
});

final notificationsNonLuesProvider = FutureProvider<List<NotificationModel>>((
  ref,
) {
  return ref.watch(notificationRepositoryProvider).getNotificationsNonLues();
});

final nombreNotificationsNonLuesProvider = FutureProvider<int>((ref) {
  return ref.watch(notificationRepositoryProvider).compterNonLues();
});

/// À appeler après une action qui modifie les notifications.
void actualiserNotifications(WidgetRef ref) {
  ref.invalidate(mesNotificationsProvider);
  ref.invalidate(notificationsNonLuesProvider);
  ref.invalidate(nombreNotificationsNonLuesProvider);
}

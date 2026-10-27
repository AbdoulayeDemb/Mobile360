import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/agent_notification.dart';
import '../../data/repositories/agent_notification_repository.dart';

final agentNotificationRepositoryProvider =
    Provider<AgentNotificationRepository>((ref) {
      return AgentNotificationRepository();
    });

final agentNotificationsProvider =
    FutureProvider.autoDispose<List<AgentNotification>>((ref) async {
      final notifications = await ref
          .watch(agentNotificationRepositoryProvider)
          .getMesNotifications();

      return notifications
          .where(
            (notification) =>
                notification.type == 'PREUVE_VALIDEE' ||
                notification.type == 'PREUVE_REJETEE',
          )
          .toList();
    });

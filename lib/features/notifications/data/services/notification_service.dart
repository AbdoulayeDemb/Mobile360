import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../models/notification_model.dart';

class NotificationService {
  final Dio _dio = ApiClient.dio;

  // Toutes les notifications de l'utilisateur connecté
  Future<List<NotificationModel>> getMesNotifications() async {
    final response = await _dio.get('/api/notifications/mes');

    final data = response.data as List<dynamic>;

    return data
        .map(
          (item) => NotificationModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  // Notifications non lues
  Future<List<NotificationModel>> getNotificationsNonLues() async {
    final response = await _dio.get('/api/notifications/non-lues');

    final data = response.data as List<dynamic>;

    return data
        .map(
          (item) => NotificationModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  // Nombre de notifications non lues
  Future<int> compterNonLues() async {
    final response = await _dio.get('/api/notifications/non-lues/count');

    return (response.data['count'] as num).toInt();
  }

  // Marquer une notification comme lue
  Future<void> marquerCommeLue(int idNotification) async {
    await _dio.patch('/api/notifications/$idNotification/lue');
  }

  // Marquer toutes les notifications comme lues
  Future<void> marquerToutesCommeLues() async {
    await _dio.patch('/api/notifications/tout-lu');
  }
}

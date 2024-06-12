// lib/services/notification_service.dart
import '../models/notification.dart';

class NotificationService {
  Future<List<NotificationModel>> fetchNotifications() async {
    await Future.delayed(const Duration(seconds: 1)); // Simular retraso de red

    return [
      NotificationModel(
        title: 'Ausencia de Tensión',
        body: 'El compresor 1 esta apagado',
        timestamp: 'Oct 12, 2023 at 2:37 AM',
      ),
      NotificationModel(
        title: 'Tensión Restablecida',
        body: 'El compresor 1 esta encendido',
        timestamp: 'Oct 13, 2024 at 2:37 AM',
      ),
      NotificationModel(
        title: 'Ausencia de Tensión',
        body: 'El compresor 2 esta apagado',
        timestamp: 'Oct 12, 2023 at 2:37 AM',
      ),
      NotificationModel(
        title: 'Tensión Restablecida',
        body: 'El compresor 2 esta encendido',
        timestamp: 'Oct 13, 2024 at 2:37 AM',
      ),
      NotificationModel(
        title: 'Ausencia de Tensión',
        body: 'El compresor 3 esta apagado',
        timestamp: 'Oct 12, 2023 at 2:37 AM',
      ),
      NotificationModel(
        title: 'Tensión Restablecida',
        body: 'El compresor 3 esta encendido',
        timestamp: 'Oct 13, 2024 at 2:37 AM',
      ),
    ];
  }
}

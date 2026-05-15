import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  NotificationService._internal();

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // ── Alerta de postura incorrecta ──────────────────────────────────────────
  Future<void> showPostureAlert() async {
    const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'posture_alerts',
      'Alertes de Postura',
      channelDescription: 'Avisos quan la postura és incorrecta',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      icon: '@mipmap/ic_launcher',
    );
    const NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Postura incorrecta detectada',
      'Ajusta la teva posició per evitar lesions a l\'esquena.',
      notificationDetails,
      payload: 'alerta_postura',
    );
  }

  // ── Alerta de temps màxim assegut superat ─────────────────────────────────
  Future<void> showSittingTimeAlert(int minutsMaxim) async {
    const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'sitting_time_alerts',
      'Alertes de Temps Assegut',
      channelDescription: 'Avisos quan portes massa estona assegut',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails);

    await flutterLocalNotificationsPlugin.show(
      1, // ID diferent de la notificació de postura (0)
      '⏱️ És hora d\'aixecar-se!',
      'Portes més de $minutsMaxim minuts assegut. Fes una pausa i estira les cames.',
      notificationDetails,
      payload: 'alerta_temps',
    );
  }
}

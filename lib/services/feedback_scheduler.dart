import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../data/database_helper.dart';
import '../main.dart';

class FeedbackScheduler {
  static final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettings = InitializationSettings(android: androidSettings);

    await notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (resp) {
        final code = resp.payload;
        if (code != null) {
          navigatorKey.currentState?.pushNamed("/confirm", arguments: code);
        }
      },
    );
  }

  /// Notificación inmediata para prueba manual
  static Future<void> sendTestNotification(String code) async {
    await notifications.show(
      1001,
      "Recordatorio de prueba",
      "¿Cómo vas con tus medicamentos hoy?",
      const NotificationDetails(
        android: AndroidNotificationDetails(
          "test_channel",
          "Pruebas",
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: code,
    );
  }

  /// Programar feedback semanal 1–3 días en el futuro (ya lo tenías)
  static Future<void> scheduleWeeklyFeedback(String code) async {
    final reminders = await DBHelper.getReminders(code);
    if (reminders.isEmpty) return;

    final random = Random();
    final now = DateTime.now();

    final target = DateTime(
      now.year,
      now.month,
      now.day + (random.nextInt(3) + 1),
      10,
      0,
    );

    final tzTime = tz.TZDateTime.from(target, tz.local);

    await notifications.zonedSchedule(
      2025,
      "Recordatorio semanal 💚",
      "¿Cómo vas con tus medicamentos?",
      tzTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          "feedback_channel",
          "Recordatorios",
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: null,
      payload: code,
    );
  }

  /// 🔔 Programar 2 notificaciones de FEEDBACK para HOY
  /// Una a las 10:30 y otra a las 10:40 (ajusta si la hora ya pasó)
  static Future<void> scheduleTodayFeedbackTest(String code) async {
    final now = DateTime.now();

    DateTime t1 = DateTime(now.year, now.month, now.day, 10, 30);
    DateTime t2 = DateTime(now.year, now.month, now.day, 10, 40);

    // Si ya pasó 10:30, las movemos para unos minutos adelante para poder probar
    if (t1.isBefore(now)) {
      t1 = now.add(const Duration(minutes: 1));
    }
    if (t2.isBefore(t1)) {
      t2 = t1.add(const Duration(minutes: 10));
    }

    final tz1 = tz.TZDateTime.from(t1, tz.local);
    final tz2 = tz.TZDateTime.from(t2, tz.local);

    await notifications.zonedSchedule(
      3001,
      "¿Cómo vas con tus medicamentos?",
      "Cuéntanos cómo te ha ido hoy 💚",
      tz1,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          "feedback_channel",
          "Recordatorios",
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: null,
      payload: code,
    );

    await notifications.zonedSchedule(
      3002,
      "Seguimiento de tus medicamentos",
      "¿Has seguido tomando tus medicamentos?",
      tz2,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          "feedback_channel",
          "Recordatorios",
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: null,
      payload: code,
    );
  }
}

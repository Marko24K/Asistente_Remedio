
import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../data/database_helper.dart';
import '../main.dart';

class FeedbackScheduler {
  static final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  // ===============================================
  // INIT
  // ===============================================
  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettings = InitializationSettings(android: androidSettings);

    await notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (resp) async {
        final payload = resp.payload ?? "";

        // ---- DIFERIDA ----
        if (payload.startsWith("missed|")) {
          final parts = payload.split("|");
          final reminderId = int.tryParse(parts[1]) ?? 0;
          final code = parts[2];

          final reminder = await DBHelper.getReminderById(reminderId);
          if (reminder == null) return;

          navigatorKey.currentState?.pushNamed(
            "/confirm_missed",
            arguments: {
              "code": code,
              "reminderId": reminderId,
              "medication": reminder["medication"],
              "scheduledHour": reminder["hour"],
            },
          );
          return;
        }

        // ---- RECORDATORIO NORMAL ----
        if (payload.startsWith("due|")) {
          final parts = payload.split("|");
          final reminderId = int.tryParse(parts[1]) ?? 0;
          final code = parts[2];

          navigatorKey.currentState?.pushNamed(
            "/due_reminder",
            arguments: {"reminderId": reminderId, "code": code},
          );
        }
      },
    );
  }

  // ===============================================
  // NOTIFICACIÓN DIFERIDA
  // ===============================================
  static Future<void> scheduleDeferredForReminder({
    required int reminderId,
    required String patientCode,
    required String medication,
    required String scheduledHour,
  }) async {
    final random = Random();

    // Notificación entre 20 y 60 minutos después
    final future = DateTime.now().add(
      Duration(minutes: 20 + random.nextInt(40)),
    );

    final tzDate = tz.TZDateTime.from(future, tz.local);

    await notifications.zonedSchedule(
      4000 + reminderId,
      "¿Lo tomaste?",
      "Olvidaste marcar el $medication a las $scheduledHour, ¿lo tomaste?",
      tzDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          "feedback_channel",
          "Recordatorios diferidos",
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: "missed|$reminderId|$patientCode",
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: null,
    );
  }

  // ===============================================
  // NOTIFICACIÓN DE HORA EXACTA
  // ===============================================
  static Future<void> scheduleDueReminder({
    required int reminderId,
    required String code,
    required String medication,
    required String hour,
    required DateTime when,
  }) async {
    final tzDate = tz.TZDateTime.from(when, tz.local);

    await notifications.zonedSchedule(
      2000 + reminderId,
      "Es hora de tu medicamento",
      "Toca para marcar tu $medication",
      tzDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          "due_channel",
          "Recordatorios de hora exacta",
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: "due|$reminderId|$code",
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: null,
    );
  }
}

import 'dart:io' show Platform;
import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/database_helper.dart';
import '../main.dart';

class FeedbackScheduler {
  static final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  // ======================================================
  // INIT
  // ======================================================
  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettings = InitializationSettings(android: androidSettings);

    await notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse resp) async {
        final payload = resp.payload ?? "";

        // ---- NOTIFICACIÓN DIFERIDA ----
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

        // ---- NOTIFICACIÓN NORMAL ----
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

    // ----- Permisos Android -----
    if (Platform.isAndroid) {
      final androidPlugin = notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.requestExactAlarmsPermission();
    }

    // ----- Timezone -----
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation("America/Santiago"));
  }

  // ======================================================
  // NOTIFICACIÓN DIFERIDA
  // ======================================================
  static Future<void> scheduleDeferredForReminder({
    required int reminderId,
    required String patientCode,
    required String medication,
    required String scheduledHour,
  }) async {
    final random = Random();

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
          channelDescription:
              "Notificaciones cuando el usuario no confirma la toma",
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
      ),
      payload: "missed|$reminderId|$patientCode",
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: null,
    );
  }

  // ======================================================
  // NOTIFICACIÓN DE HORA EXACTA
  // ======================================================
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
          "Recordatorios a la hora exacta",
          channelDescription: "Recordatorios programados en la hora exacta",
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
      ),
      payload: "due|$reminderId|$code",
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: null,
    );
  }
}

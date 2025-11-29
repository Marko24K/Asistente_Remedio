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

    // ----- 1. CREAR CANALES -----
    final androidPlugin = notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'due_channel',
          'Recordatorios a la hora exacta',
          description: 'Recordatorios principales',
          importance: Importance.max,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'feedback_channel',
          'Recordatorios diferidos',
          description: 'Recordatorios si no se confirma la toma',
          importance: Importance.high,
        ),
      );
    }

    // ----- 2. inicializar plugin -----
    await notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse resp) async {
        final payload = resp.payload ?? "";

        if (payload.startsWith("missed|")) {
          final p = payload.split("|");
          final id = int.tryParse(p[1]) ?? 0;
          final code = p[2];

          final reminder = await DBHelper.getReminderById(id);
          if (reminder == null) return;

          navigatorKey.currentState?.pushNamed(
            "/confirm_missed",
            arguments: {
              "code": code,
              "reminderId": id,
              "medication": reminder["medication"],
              "scheduledHour": reminder["hour"],
            },
          );
        }

        if (payload.startsWith("due|")) {
          final p = payload.split("|");
          final id = int.tryParse(p[1]) ?? 0;
          final code = p[2];

          navigatorKey.currentState?.pushNamed(
            "/due_reminder",
            arguments: {"reminderId": id, "code": code},
          );
        }
      },
    );

    // ----- 3. Permisos Android -----
    if (Platform.isAndroid) {
      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.requestExactAlarmsPermission();
    }

    // ----- 4. Timezone -----
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation("America/Santiago"));
  }

  // ======================================================
  // DIFERIDA
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
      "Olvidaste marcar el $medication a las $scheduledHour",
      tzDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          "feedback_channel",
          "Recordatorios diferidos",
          channelDescription: "Si no confirmas la toma",
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: "missed|$reminderId|$patientCode",
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: null,
    );
  }

  // ======================================================
  // DUE (HORA EXACTA)
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
          channelDescription: "Recordatorios principales",
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      payload: "due|$reminderId|$code",
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: null,
    );
  }
}

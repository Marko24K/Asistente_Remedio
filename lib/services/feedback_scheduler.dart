import 'dart:math';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../data/database_helper.dart';
import '../main.dart';

class FeedbackScheduler {
  static final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();
  static bool _hasNotificationPermission = false;
  static bool _hasExactAlarmPermission = false;

  // ===============================================
  // INIT
  // ===============================================
  static Future<void> init() async {
    print('🔔 [INIT] Inicializando FeedbackScheduler...');

    const androidSettings = AndroidInitializationSettings(
      'notification_icon',
    );

    const initSettings = InitializationSettings(android: androidSettings);

    await notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (resp) async {
        print('👉 [NOTIF TAP] Usuario tocó notificación: ${resp.payload}');

        final payload = resp.payload ?? "";

        // ---- DIFERIDA ----
        if (payload.startsWith("missed|")) {
          final parts = payload.split("|");
          final reminderId = int.tryParse(parts[1]) ?? 0;
          final code = parts[2];

          final reminder = await DBHelper.getReminderById(reminderId);
          if (reminder == null) {
            print('❌ [ERROR] No se encontró reminder con ID: $reminderId');
            return;
          }

          print('✅ Abriendo ConfirmMissedScreen...');

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

          print('✅ Abriendo DueReminderScreen...');

          navigatorKey.currentState?.pushNamed(
            "/due_reminder",
            arguments: {"reminderId": reminderId, "code": code},
          );
        }
      },
    );

    print('✅ Notificaciones inicializadas');

    // Android 13+ permisos + canales
    if (Platform.isAndroid) {
      print('🤖 Configurando Android 13+...');

      final androidPlugin = notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        // Canales con importancia máxima para garantizar entrega
        const dueChannel = AndroidNotificationChannel(
          'due_channel',
          'Recordatorios de hora exacta',
          description: 'Notifica cuando es la hora exacta del medicamento',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
          enableLights: true,
        );

        const feedbackChannel = AndroidNotificationChannel(
          'feedback_channel',
          'Recordatorios diferidos',
          description: 'Preguntas sobre tomas no marcadas a la hora',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
          enableLights: true,
        );

        print('📍 Creando canales...');
        await androidPlugin.createNotificationChannel(dueChannel);
        await androidPlugin.createNotificationChannel(feedbackChannel);
        print('✅ Canales creados');

        print('🔐 Solicitando permisos...');
        _hasNotificationPermission =
            await androidPlugin.requestNotificationsPermission() ?? false;
        print('   POST_NOTIFICATIONS: $_hasNotificationPermission');

        _hasExactAlarmPermission =
            await androidPlugin.requestExactAlarmsPermission() ?? false;
        print('   SCHEDULE_EXACT_ALARM: $_hasExactAlarmPermission');

        if (!_hasNotificationPermission) {
          print('⚠️  ADVERTENCIA: Permiso POST_NOTIFICATIONS denegado');
        }
        if (!_hasExactAlarmPermission) {
          print('⚠️  ADVERTENCIA: Permiso SCHEDULE_EXACT_ALARM denegado');
        }
      } else {
        print(
          '❌ [ERROR] No se pudo obtener AndroidFlutterLocalNotificationsPlugin',
        );
      }
    }

    print('✅ FeedbackScheduler inicializado');
  }

  // ===============================================
  // DEBUG: Verificar notificaciones pendientes
  // ===============================================
  static Future<void> debugPendingNotifications() async {
    final pending = await notifications.pendingNotificationRequests();
    print('🔍 [DEBUG] Notificaciones pendientes: ${pending.length}');
    for (final notif in pending) {
      print('   - ID: ${notif.id}, Title: ${notif.title}, Scheduled: ${notif.body}');
    }
  }

  // ===============================================
  // VERIFICAR PERMISOS EN TIEMPO REAL
  // ===============================================
  static Future<void> _ensureChannelsAndPermissions() async {
    if (!Platform.isAndroid) return;
    
    final androidPlugin = notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    
    if (androidPlugin == null) return;
    
    // Recrear canales (idempotente, no causa conflicto)
    const dueChannel = AndroidNotificationChannel(
      'due_channel',
      'Recordatorios de hora exacta',
      description: 'Notifica cuando es la hora exacta del medicamento',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
      enableLights: true,
    );

    const feedbackChannel = AndroidNotificationChannel(
      'feedback_channel',
      'Recordatorios diferidos',
      description: 'Preguntas sobre tomas no marcadas a la hora',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
      enableLights: true,
    );

    try {
      await androidPlugin.createNotificationChannel(dueChannel);
      await androidPlugin.createNotificationChannel(feedbackChannel);
    } catch (e) {
      print('ℹ️  Canales ya existen: $e');
    }
    
    // Verificar permisos actuales
    _hasNotificationPermission =
        await androidPlugin.requestNotificationsPermission() ?? false;
    _hasExactAlarmPermission =
        await androidPlugin.requestExactAlarmsPermission() ?? false;
  }

  // ===============================================
  // CANCELAR NOTIFICACIONES PREVIAS
  // ===============================================
  static Future<void> _cancelPreviousNotification(int notificationId) async {
    try {
      await notifications.cancel(notificationId);
      print('🗑️  Notificación previa cancelada: $notificationId');
    } catch (e) {
      print('⚠️  No se pudo cancelar notificación anterior: $e');
    }
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
    // Asegurar canales y permisos antes de programar
    await _ensureChannelsAndPermissions();

    if (!_hasNotificationPermission) {
      print('⚠️  [DIFERIDA] Sin permiso POST_NOTIFICATIONS, abortando');
      return;
    }

    final notificationId = 4000 + reminderId;
    await _cancelPreviousNotification(notificationId);

    final random = Random();
    final future = DateTime.now().add(
      Duration(minutes: 20 + random.nextInt(40)),
    );

    final tzDate = tz.TZDateTime(
      tz.getLocation("America/Santiago"),
      future.year,
      future.month,
      future.day,
      future.hour,
      future.minute,
      future.second,
    );

    print('📌 [NOTIF DIFERIDA] Programando notificación diferida:');
    print('   ID: $notificationId');
    print('   Medicamento: $medication');
    print('   Fecha/Hora: $tzDate');
    print('   Permiso exacto: $_hasExactAlarmPermission');

    try {
      await notifications.zonedSchedule(
        notificationId,
        "¿Lo tomaste?",
        "Olvidaste marcar el $medication a las $scheduledHour, ¿lo tomaste?",
        tzDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            "feedback_channel",
            "Recordatorios diferidos",
            importance: Importance.max,
            priority: Priority.max,
          ),
        ),
        payload: "missed|$reminderId|$patientCode",
        androidScheduleMode: _hasExactAlarmPermission
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: null,
      );

      print('✅ Notificación diferida programada');
    } catch (e) {
      print('❌ [ERROR DIFERIDA] $e');
      print('   Reintentando con modo inexacto...');

      try {
        await notifications.zonedSchedule(
          notificationId,
          "¿Lo tomaste?",
          "Olvidaste marcar el $medication a las $scheduledHour, ¿lo tomaste?",
          tzDate,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              "feedback_channel",
              "Recordatorios diferidos",
              importance: Importance.max,
              priority: Priority.max,
            ),
          ),
          payload: "missed|$reminderId|$patientCode",
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: null,
        );
        print('✅ Notificación diferida programada (inexacto)');
      } catch (e2) {
        print('❌ [ERROR CRÍTICO DIFERIDA] $e2');
      }
    }
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
    // Asegurar canales y permisos antes de programar
    await _ensureChannelsAndPermissions();

    if (!_hasNotificationPermission) {
      print('⚠️  [DUE] Sin permiso POST_NOTIFICATIONS, abortando');
      return;
    }

    final notificationId = 2000 + reminderId;

    // Cancelar notificación anterior
    await _cancelPreviousNotification(notificationId);

    final tzDate = tz.TZDateTime(
      tz.getLocation("America/Santiago"),
      when.year,
      when.month,
      when.day,
      when.hour,
      when.minute,
      when.second,
    );

    print('📌 [NOTIF DUE] Programando notificación exacta:');
    print('   ID: $notificationId');
    print('   Medicamento: $medication');
    print('   Hora programada: $hour');
    print('   DateTime: $when');
    print('   TZDateTime: $tzDate');
    print('   Permiso exacto: $_hasExactAlarmPermission');

    // Si la hora ya pasó, no programar
    if (when.isBefore(DateTime.now())) {
      print('⚠️  La hora ya pasó, no se programa');
      return;
    }

    try {
      await notifications.zonedSchedule(
        notificationId,
        "Es hora de tu medicamento",
        "Toca para marcar tu $medication",
        tzDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            "due_channel",
            "Recordatorios de hora exacta",
            importance: Importance.max,
            priority: Priority.max,
            fullScreenIntent: true,
            color: const Color.fromARGB(255, 64, 145, 108),
            enableVibration: true,
            playSound: true,
            audioAttributesUsage: AudioAttributesUsage.alarm,
          ),
        ),
        payload: "due|$reminderId|$code",
        androidScheduleMode: _hasExactAlarmPermission
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: null,
      );

      print('✅ Notificación exacta programada');
    } catch (e) {
      print('❌ [ERROR DUE] $e');
      print('   Reintentando con modo inexacto...');

      try {
        await notifications.zonedSchedule(
          notificationId,
          "Es hora de tu medicamento",
          "Toca para marcar tu $medication",
          tzDate,
          NotificationDetails(
            android: AndroidNotificationDetails(
              "due_channel",
              "Recordatorios de hora exacta",
              importance: Importance.max,
              priority: Priority.max,
              fullScreenIntent: true,
              color: const Color.fromARGB(255, 64, 145, 108),
              enableVibration: true,
              playSound: true,
              audioAttributesUsage: AudioAttributesUsage.alarm,
            ),
          ),
          payload: "due|$reminderId|$code",
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: null,
        );
        print('✅ Notificación exacta programada (inexacto)');
      } catch (e2) {
        print('❌ [ERROR CRÍTICO DUE] $e2');
      }
    }
  }
}

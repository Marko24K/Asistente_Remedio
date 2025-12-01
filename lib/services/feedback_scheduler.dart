import 'dart:io' show Platform;
import 'dart:math';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../data/database_helper.dart';
import '../main.dart';
import 'device_optimization_helper.dart';
import 'notification_worker.dart';

class FeedbackScheduler {
  static final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  static const _dueChannelId = 'due_channel_v2';
  static const _feedbackChannelId = 'feedback_channel_v2';

  static bool _hasNotificationPermission = false;
  static bool _hasExactAlarmPermission = false;
  static bool _initialized = false;

  // ===============================================
  // INIT
  // ===============================================
  static Future<void> init() async {
    if (_initialized) {
      print('[INIT] FeedbackScheduler ya inicializado, ignorando...');
      return;
    }

    print('[INIT] Inicializando FeedbackScheduler...');

    // Inicializar WorkManager primero
    NotificationWorker.init();

    const androidSettings = AndroidInitializationSettings('notification_icon');
    const initSettings = InitializationSettings(android: androidSettings);

    await notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (resp) async {
        final payload = resp.payload ?? "";

        // Diferida
        if (payload.startsWith("missed|")) {
          final parts = payload.split("|");
          final reminderId = int.tryParse(parts[1]) ?? 0;
          final code = parts[2];

          final reminder = await DBHelper.getReminderById(reminderId);
          if (reminder == null) {
            print('[ERROR] No se encontró reminder con ID: $reminderId');
            return;
          }

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

        // Recordatorio normal
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

    print('[INIT] Notificaciones inicializadas');

    // Android 13+ permisos + canales
    if (Platform.isAndroid) {
      print('[INIT] Configurando Android 13+...');

      final androidPlugin = notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        const dueChannel = AndroidNotificationChannel(
          _dueChannelId,
          'Recordatorios de hora exacta',
          description: 'Notifica cuando es la hora exacta del medicamento',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
          enableLights: true,
          sound: RawResourceAndroidNotificationSound('pills'),
          audioAttributesUsage: AudioAttributesUsage.alarm,
        );

        const feedbackChannel = AndroidNotificationChannel(
          _feedbackChannelId,
          'Recordatorios diferidos',
          description: 'Preguntas sobre tomas no marcadas a la hora',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
          enableLights: true,
          sound: RawResourceAndroidNotificationSound('pills'),
          audioAttributesUsage: AudioAttributesUsage.alarm,
        );

        await androidPlugin.createNotificationChannel(dueChannel);
        await androidPlugin.createNotificationChannel(feedbackChannel);
        print('[INIT] Canales creados');

        _hasNotificationPermission =
            await androidPlugin.requestNotificationsPermission() ?? false;
        _hasExactAlarmPermission =
            await androidPlugin.requestExactAlarmsPermission() ?? false;

        if (!_hasNotificationPermission) {
          print('[INIT] ADVERTENCIA: Permiso POST_NOTIFICATIONS denegado');
        }
        if (!_hasExactAlarmPermission) {
          print('[INIT] ADVERTENCIA: Permiso SCHEDULE_EXACT_ALARM denegado');
        }
      } else {
        print(
          '[INIT] ERROR: No se pudo obtener AndroidFlutterLocalNotificationsPlugin',
        );
      }

      // Solicitar ignorar optimización de batería
      await _requestIgnoreBatteryOptimization();

      // Workaround Motorola
      print('[INIT] Verificando workarounds específicos de dispositivo...');
      await DeviceOptimizationHelper.applyMotorolaWorkaround();
    }

    _initialized = true;
    print('[INIT] FeedbackScheduler inicializado completamente');
  }

  // ===============================================
  // Solicitar ignorar optimización de batería
  // ===============================================
  static Future<void> _requestIgnoreBatteryOptimization() async {
    try {
      final intent = AndroidIntent(
        action: 'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
        data: 'package:com.example.asistente_remedio',
      );
      await intent.launch();
    } catch (e) {
      print('[BATTERY] No se pudo abrir configuración: $e');
    }
  }

  // ===============================================
  // DEBUG: Verificar notificaciones pendientes
  // ===============================================
  static Future<void> debugPendingNotifications() async {
    final pending = await notifications.pendingNotificationRequests();
    print('[DEBUG] Notificaciones pendientes: ${pending.length}');
    for (final notif in pending) {
      print(
        ' - ID: ${notif.id}, Title: ${notif.title}, Body: ${notif.body}, Payload: ${notif.payload}',
      );
    }
  }

  // ===============================================
  // Verificar canales y permisos
  // ===============================================
  static Future<void> _ensureChannelsAndPermissions() async {
    final androidPlugin = notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) {
      print('[ERROR] AndroidFlutterLocalNotificationsPlugin es null');
      return;
    }

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _dueChannelId,
        'Recordatorios de hora exacta',
        description: 'Recordatorios programados',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        sound: RawResourceAndroidNotificationSound('pills'),
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
    );

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _feedbackChannelId,
        'Recordatorios diferidos',
        description: 'Notificación si no tomaste el medicamento',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        sound: RawResourceAndroidNotificationSound('pills'),
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
    );

    if (!_hasNotificationPermission) {
      _hasNotificationPermission =
          await androidPlugin.requestNotificationsPermission() ?? false;
    }

    if (!_hasExactAlarmPermission) {
      _hasExactAlarmPermission =
          await androidPlugin.requestExactAlarmsPermission() ?? false;
    }
  }

  // ===============================================
  // Cancelar notificación previa
  // ===============================================
  static Future<void> _cancelPreviousNotification(int notificationId) async {
    try {
      await notifications.cancel(notificationId);
    } catch (e) {
      print('[CANCEL] No se pudo cancelar notificación anterior: $e');
    }
  }

  static Future<void> cancelNotification(int reminderId) async {
    await _cancelPreviousNotification(reminderId);
  }

  // ===============================================
  // Notificación diferida
  // ===============================================
  static Future<void> scheduleDeferredForReminder({
    required int reminderId,
    required String patientCode,
    required String medication,
    required String scheduledHour,
  }) async {
    await _ensureChannelsAndPermissions();

    if (!_hasNotificationPermission) {
      print('[DIFERIDA] Sin permiso POST_NOTIFICATIONS, abortando');
      return;
    }

    final notificationId = 4000 + reminderId;
    await _cancelPreviousNotification(notificationId);

    final random = Random();
    final delayMinutes = 20 + random.nextInt(40);
    final future = DateTime.now().add(Duration(minutes: delayMinutes));

    await NotificationWorker.scheduleNotification(
      id: notificationId,
      title: "¿Lo tomaste?",
      body: "$medication no fue tomado a las $scheduledHour",
      when: future,
      payload: "missed|$reminderId|$patientCode",
      sound: 'pills',
      channelId: _feedbackChannelId,
    );

    print('[DIFERIDA] Notificación diferida programada');
  }

  // ===============================================
  // Notificación de hora exacta
  // ===============================================
  static Future<void> scheduleDueReminder({
    required int reminderId,
    required String code,
    required String medication,
    required String hour,
    required DateTime when,
  }) async {
    await _ensureChannelsAndPermissions();

    if (!_hasNotificationPermission) {
      print("[DUE] Sin permiso POST_NOTIFICATIONS.");
      return;
    }

    final now = DateTime.now();
    if (when.isBefore(now)) {
      final fallback = now.add(const Duration(minutes: 1));
      print("[DUE] Hora pasada ($when). Reprogramando en 1 min: $fallback");
      when = fallback;
    }

    await NotificationWorker.scheduleNotification(
      id: reminderId,
      title: "¡Hora de tu medicamento!",
      body: "$medication a las $hour",
      when: when,
      payload: "due|$reminderId|$code",
      sound: 'pills',
      channelId: _dueChannelId,
    );

    print('[DUE] Notificación programada con WorkManager');
  }

  // ===============================================
  // Test inmediata
  // ===============================================
  static Future<void> testImmediateNotification() async {
    print('[TEST] Enviando notificación de prueba inmediata...');

    try {
      await notifications.show(
        9999,
        "🧪 Notificación de Prueba",
        "Si ves esto, el sistema de notificaciones funciona",
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _dueChannelId,
            'Recordatorios de hora exacta',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            enableVibration: true,
            enableLights: true,
            sound: RawResourceAndroidNotificationSound('pills'),
          ),
        ),
        payload: 'test',
      );
      print('[TEST] Notificación enviada');
    } catch (e) {
      print('[TEST] Error: $e');
    }
  }

  // ===============================================
  // Test programada 5s
  // ===============================================
  static Future<void> testScheduledNotification() async {
    print('[TEST] Programando notificación para 5 segundos...');

    await _ensureChannelsAndPermissions();

    if (!_hasNotificationPermission) {
      print('[TEST] Sin permiso POST_NOTIFICATIONS');
      return;
    }

    Future.delayed(const Duration(seconds: 5), () async {
      try {
        await notifications.show(
          9998,
          "🧪 Notificación Programada",
          "Programada para 5 segundos después",
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _dueChannelId,
              'Recordatorios de hora exacta',
              importance: Importance.max,
              priority: Priority.max,
              playSound: true,
              enableVibration: true,
              enableLights: true,
              sound: RawResourceAndroidNotificationSound('pills'),
            ),
          ),
        );
        print('[TEST] Notificación mostrada después de 5 segundos');
      } catch (e) {
        print('[TEST] Error mostrando notificación: $e');
      }
    });

    print('[TEST] Notificación programada (5s)');
  }
}

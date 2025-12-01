import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'dart:io';

const String notificationTaskId = 'notification_task_id';
const String dueChannelId = 'due_channel';
const String feedbackChannelId = 'feedback_channel';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == notificationTaskId && inputData != null) {
        
        final notifications = FlutterLocalNotificationsPlugin();

        await notifications.initialize(
          const InitializationSettings(
            android: AndroidInitializationSettings('notification_icon'),
          ),
        );

        // ========================
        //   LECTURA DE INPUT DATA
        // ========================
        final dynamic rawId = inputData['notificationId'];
        final int notificationId =
            rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 1;

        final String title = (inputData['title'] ?? 'Recordatorio').toString();
        final String body = (inputData['body'] ?? '').toString();
        final String payload = (inputData['payload'] ?? '').toString();
        final String sound = (inputData['sound'] ?? 'pills').toString();
        final String channelId = (inputData['channelId'] ?? dueChannelId).toString();

        final String soundName = sound.replaceAll('.mp3', '');

        final String channelName =
            channelId == feedbackChannelId
                ? 'Confirmación de medicamentos'
                : 'Recordatorios de hora exacta';

        // ========================
        //    CREAR CANAL ANDROID
        // ========================
        if (Platform.isAndroid) {
          final android = notifications
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();

          await android?.createNotificationChannel(
            AndroidNotificationChannel(
              channelId,
              channelName,
              importance: Importance.max,
              sound: RawResourceAndroidNotificationSound(soundName),
              audioAttributesUsage: AudioAttributesUsage.alarm,
            ),
          );
        }

        // ========================
        //     DETALLES ANDROID
        // ========================
        final androidDetails = AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'Notificaciones de medicamentos',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound(soundName),
          autoCancel: true,
          ongoing: false,
        );

        final details = NotificationDetails(android: androidDetails);

        await notifications.show(
          notificationId,
          title,
          body,
          details,
          payload: payload,
        );

        print('🔔 [WorkManager] Notificación mostrada: $title - $body');
      }

      return Future.value(true);

    } catch (e) {
      print('❌ [WorkManager Error] $e');
      return Future.value(false);
    }
  });
}

class NotificationWorker {
  static void init() {
    Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
    print('✅ [WorkManager] Inicializado');
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    required String payload,
    String sound = 'pills',
    String channelId = dueChannelId,
  }) async {
    try {
      final Duration delay = when.difference(DateTime.now());

      if (delay.inSeconds <= 0) {
        print('⚠️ Delay negativo → notificando inmediatamente');
        await _showNotificationImmediately(
          id,
          title,
          body,
          payload,
          sound,
          channelId,
        );
        return;
      }

      await Workmanager().registerOneOffTask(
        '${notificationTaskId}_$id',
        notificationTaskId,
        inputData: {
          'notificationId': id,
          'title': title,
          'body': body,
          'payload': payload,
          'sound': sound,
          'channelId': channelId,
        },
        initialDelay: Duration(minutes: delay.inMinutes),
        constraints: Constraints(
          requiresDeviceIdle: false,
          requiresCharging: false,
          networkType: NetworkType.notRequired,
        ),
      );

      print(
          '📋 [WorkManager] Notificación programada para $when (en ${delay.inMinutes} min)');

    } catch (e) {
      print('❌ [WorkManager Schedule Error] $e');
    }
  }

  static Future<void> cancelNotification(int id) async {
    try {
      await Workmanager().cancelByUniqueName('${notificationTaskId}_$id');
      print('❌ Notificación cancelada $id');
    } catch (e) {
      print('❌ Error cancelando notificación $e');
    }
  }

  static Future<void> cancelAllNotifications() async {
    try {
      await Workmanager().cancelAll();
      print('❌ Todas canceladas');
    } catch (e) {
      print('❌ Error cancelando todas $e');
    }
  }

  static Future<void> _showNotificationImmediately(
    int id,
    String title,
    String body,
    String payload,
    String sound,
    String channelId,
  ) async {
    try {
      final notifications = FlutterLocalNotificationsPlugin();
      final soundName = sound.replaceAll('.mp3', '');

      if (Platform.isAndroid) {
        final android = notifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        await android?.createNotificationChannel(
          AndroidNotificationChannel(
            channelId,
            channelId == feedbackChannelId
                ? 'Confirmación de medicamentos'
                : 'Recordatorios de hora exacta',
            importance: Importance.max,
            sound: RawResourceAndroidNotificationSound(soundName),
            audioAttributesUsage: AudioAttributesUsage.alarm,
          ),
        );
      }

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelId == feedbackChannelId
            ? 'Confirmación de medicamentos'
            : 'Recordatorios de hora exacta',
        sound: RawResourceAndroidNotificationSound(soundName),
        importance: Importance.max,
        priority: Priority.high,
        autoCancel: true,
        ongoing: false,
      );

      final details = NotificationDetails(android: androidDetails);

      await notifications.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );

      print('🔔 Notificación inmediata mostrada');

    } catch (e) {
      print('❌ Error en notificación inmediata $e');
    }
  }
}
  

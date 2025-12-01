import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../data/database_helper.dart';

/// Herramienta para debugging detallado de notificaciones
class NotificationDebugger {
  static Future<void> generateFullReport(
    FlutterLocalNotificationsPlugin notifications,
  ) async {
    print('\n');
    print('╔════════════════════════════════════════════════════╗');
    print('║        REPORTE COMPLETO DE NOTIFICACIONES          ║');
    print('╚════════════════════════════════════════════════════╝');

    await _reportPendingNotifications(notifications);
    await _reportRemindersInDatabase();

    print('\n');
  }

  static Future<void> _reportPendingNotifications(
    FlutterLocalNotificationsPlugin notifications,
  ) async {
    print('\n📋 NOTIFICACIONES PROGRAMADAS:');
    print('─' * 50);

    try {
      final pending = await notifications.pendingNotificationRequests();

      if (pending.isEmpty) {
        print('   ⚠️  NO HAY NOTIFICACIONES PROGRAMADAS');
        return;
      }

      print('   Total: ${pending.length} notificaciones\n');

      for (var i = 0; i < pending.length; i++) {
        final notif = pending[i];
        print('   [$i] ID: ${notif.id}');
        print('       Título: ${notif.title}');
        print('       Cuerpo: ${notif.body}');
        print('       Payload: ${notif.payload}');
        print('');
      }
    } catch (e) {
      print('   ❌ Error obteniendo notificaciones: $e');
    }
  }

  static Future<void> _reportRemindersInDatabase() async {
    print('\n🗄️  RECORDATORIOS EN BASE DE DATOS:');
    print('─' * 50);

    try {
      final reminders = await DBHelper.getReminders('A92KD7');

      if (reminders.isEmpty) {
        print('   ⚠️  NO HAY RECORDATORIOS EN BD');
        return;
      }

      print('   Total: ${reminders.length} recordatorios\n');

      for (var i = 0; i < reminders.length; i++) {
        final reminder = reminders[i];
        print('   [$i] ID: ${reminder['id']}');
        print('       Medicamento: ${reminder['medication']}');
        print('       Hora: ${reminder['hour']}');
        print('       Frecuencia: ${reminder['frequencyHours']}h');
        print('       Inicio: ${reminder['startDate']}');
        print('       Fin: ${reminder['endDate']}');
        print('       Próximo: ${reminder['nextTrigger']}');
        print('');
      }
    } catch (e) {
      print('   ❌ Error accediendo BD: $e');
    }
  }

  static void logNotificationScheduled(
    int id,
    String title,
    String body,
    DateTime when,
  ) {
    print('✅ [NOTIF_LOG] Programada:');
    print('   ID: $id');
    print('   Título: $title');
    print('   Cuerpo: $body');
    print('   Hora: $when');
  }

  static void logNotificationError(int id, String title, dynamic error) {
    print('❌ [NOTIF_LOG] Error:');
    print('   ID: $id');
    print('   Título: $title');
    print('   Error: $error');
  }

  static void logPermissionCheck(
    bool hasNotification,
    bool hasExactAlarm,
    bool hasDeferredScheduling,
  ) {
    print('\n🔐 [PERMISOS_LOG] Estado:');
    print('   POST_NOTIFICATIONS: ${hasNotification ? "✅" : "❌"}');
    print('   SCHEDULE_EXACT_ALARM: ${hasExactAlarm ? "✅" : "❌"}');
    print('   SCHEDULE_DEFERRED: ${hasDeferredScheduling ? "✅" : "❌"}');
  }
}

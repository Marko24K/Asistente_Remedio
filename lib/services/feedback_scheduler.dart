import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../data/database_helper.dart';
import 'package:asistente_remedio/screens/feedback_popup.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iOS = DarwinInitializationSettings();
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(android: android, iOS: iOS),
  );
}

// Lógica simplificada: si hay recordatorios activos y hoy es día elegido, muestra notificación
Future<void> maybeShowWeeklyFeedback(
  BuildContext context,
  String patientCode,
) async {
  final active = await DBHelper.getActiveRemindersForPatient(patientCode);
  if (active.isEmpty) return;

  final hoy = DateTime.now().weekday;
  final dias = [2, 3, 5]; // martes, miercoles, viernes
  // Alternativa: elegir aleatorio
  final rand = Random();
  final prob = rand.nextDouble();
  // control simple: 40% de probabilidad este dia si forma parte de dias
  if (!dias.contains(hoy) || prob > 0.6) return;

  // Mostrar directamente el popup
  Navigator.push(
    // ignore: use_build_context_synchronously
    context,
    MaterialPageRoute(
      builder: (_) => FeedbackPopupScreen(patientCode: patientCode),
      fullscreenDialog: true,
    ),
  );
}

import 'dart:async';
import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../services/feedback_scheduler.dart';
import '../services/audio_player_service.dart';

class DueReminderScreen extends StatefulWidget {
  /// Este map viene desde la notificación y normalmente contiene:
  /// { "reminderId": int, "code": String }
  final Map reminder;

  const DueReminderScreen({super.key, required this.reminder});

  @override
  State<DueReminderScreen> createState() => _DueReminderScreenState();
}

class _DueReminderScreenState extends State<DueReminderScreen> {
  bool marked = false;
  Timer? t;

  Map<String, dynamic>? r;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadReminder();
  }

  Future<void> _loadReminder() async {
    int? id = widget.reminder["id"] as int?;
    id ??= widget.reminder["reminderId"] as int?;

    if (id == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final dbReminder = await DBHelper.getReminderById(id);
    if (!mounted) return;

    if (dbReminder == null) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      r = dbReminder;
      loading = false;
    });

    _startTimer();
  }

  void _startTimer() {
    t = Timer(const Duration(minutes: 2), () async {
      if (!marked && r != null) {
        final freq = (r!["frequencyHours"] ?? 24) as int;
        final hour = r!["hour"] as String;
        final startDate = r!["startDate"] as String?;

        // Programar notificación diferida
        await FeedbackScheduler.scheduleDeferredForReminder(
          reminderId: r!["id"] as int,
          patientCode: r!["patientCode"] as String,
          medication: r!["medication"] as String,
          scheduledHour: hour,
        );

        // Calcular siguiente toma en función de la hora INICIAL
        final next = DBHelper.calculateNextTrigger(
          hour,
          freq,
          startDate: startDate,
        );

        await DBHelper.updateNextTriggerById(r!["id"] as int, next);

        // Programar la siguiente notificación a la hora exacta
        await FeedbackScheduler.scheduleDueReminder(
          reminderId: r!["id"] as int,
          code: r!["patientCode"] as String,
          medication: r!["medication"] as String,
          hour: hour,
          when: next,
        );
      }

      if (mounted) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading || r == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final reminder = r!;

    return Scaffold(
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 70),

            Text(
              "Es hora de tu medicamento\n${reminder["medication"]}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: () async {
                if (r == null) return;
                marked = true;

                final freq = (reminder["frequencyHours"] ?? 24) as int;
                final hour = reminder["hour"] as String;
                final startDate = reminder["startDate"] as String?;
                final reminderId = reminder["id"] as int;
                final code = reminder["patientCode"] as String;
                final puntos = 10;

                // Cancelar la notificación anterior
                await FeedbackScheduler.cancelNotification(reminderId);

                // Calcular siguiente toma en función de la hora INICIAL
                final next = DBHelper.calculateNextTrigger(
                  hour,
                  freq,
                  startDate: startDate,
                );

                // Actualizar nextTrigger en BD
                await DBHelper.updateNextTriggerById(reminderId, next);

                // Programar la siguiente notificación a la hora exacta
                await FeedbackScheduler.scheduleDueReminder(
                  reminderId: reminderId,
                  code: code,
                  medication: reminder["medication"] as String,
                  hour: hour,
                  when: next,
                );

                // Registrar en KPIs que se tomó a la hora
                await DBHelper.addKpi(
                  reminderId: reminderId,
                  code: code,
                  scheduledHour: hour,
                  tomo: true,
                  puntos: puntos,
                );

                // Sumar puntos por marcar a la hora
                await DBHelper.addPoints(puntos, code);

                // Reproducir sonido de éxito
                await AudioPlayerService.playSound('correct_ding.mp3');

                // Mostrar popup con puntos
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("¡Perfecto!"),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 60,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "+$puntos puntos",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text("Muy bien, a la hora exacta."),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("OK"),
                        ),
                      ],
                    ),
                  );

                  // Cerrar después de 2 segundos
                  await Future.delayed(const Duration(seconds: 2));
                  if (mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 14,
                ),
              ),
              child: const Text(
                "Marcar como tomado",
                style: TextStyle(fontSize: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

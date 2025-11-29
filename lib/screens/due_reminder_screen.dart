import 'dart:async';
import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../services/feedback_scheduler.dart';

class DueReminderScreen extends StatefulWidget {
  final Map reminder;

  const DueReminderScreen({super.key, required this.reminder});

  @override
  State<DueReminderScreen> createState() => _DueReminderScreenState();
}

class _DueReminderScreenState extends State<DueReminderScreen> {
  bool marked = false;
  Timer? t;

  @override
  void initState() {
    super.initState();

    // 2 minutos para marcar
    t = Timer(const Duration(minutes: 2), () async {
      if (!marked) {
        // Programar notificación diferida
        await FeedbackScheduler.scheduleDeferredForReminder(
          reminderId: widget.reminder["id"],
          patientCode: widget.reminder["patientCode"],
          medication: widget.reminder["medication"],
          scheduledHour: widget.reminder["hour"],
        );

        // Calcular siguiente toma
        final freq = widget.reminder["frequencyHours"];
        final hour = widget.reminder["hour"];
        final next = DBHelper.calculateNextTrigger(hour, freq);

        await DBHelper.updateNextTriggerById(widget.reminder["id"], next);
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
    final r = widget.reminder;

    return Scaffold(
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 70),

            Text(
              "Es hora de tu medicamento\n${r["medication"]}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: () async {
                marked = true;

                final freq = r["frequencyHours"];
                final hour = r["hour"];
                final next = DBHelper.calculateNextTrigger(hour, freq);

                await DBHelper.updateNextTriggerById(r["id"], next);

                await DBHelper.addPoints(10, r["patientCode"]);

                // ignore: use_build_context_synchronously
                if (mounted) Navigator.pop(context);
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

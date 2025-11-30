import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../services/feedback_scheduler.dart';

class ConfirmMissedScreen extends StatefulWidget {
  final String code;
  final int reminderId;
  final String medication;
  final String scheduledHour;

  const ConfirmMissedScreen({
    super.key,
    required this.code,
    required this.reminderId,
    required this.medication,
    required this.scheduledHour,
  });

  @override
  State<ConfirmMissedScreen> createState() => _ConfirmMissedScreenState();
}

class _ConfirmMissedScreenState extends State<ConfirmMissedScreen> {
  double yesScale = 1;
  double noScale = 1;

  void animateYes() {
    setState(() => yesScale = 0.9);
    Future.delayed(
      const Duration(milliseconds: 150),
      () => setState(() => yesScale = 1),
    );
  }

  void animateNo() {
    setState(() => noScale = 0.9);
    Future.delayed(
      const Duration(milliseconds: 150),
      () => setState(() => noScale = 1),
    );
  }

  Future<void> _registrarRespuesta(bool tomo) async {
    final puntos = tomo ? 15 : 5;

    // Registrar en KPIs
    await DBHelper.addKpi(
      reminderId: widget.reminderId,
      code: widget.code,
      scheduledHour: widget.scheduledHour,
      tomo: tomo,
      puntos: puntos,
    );

    // Sumar puntos al paciente
    await DBHelper.addPoints(puntos, widget.code);

    // Obtener el recordatorio para recalcular próxima toma
    final reminder = await DBHelper.getReminderById(widget.reminderId);
    if (reminder != null) {
      // Calcular siguiente toma en función de la hora INICIAL
      final next = DBHelper.calculateNextTrigger(
        reminder["hour"] as String,
        (reminder["frequencyHours"] ?? 24) as int,
        startDate: reminder["startDate"] as String?,
      );

      // Actualizar nextTrigger en BD
      await DBHelper.updateNextTriggerById(widget.reminderId, next);

      // Programar la próxima notificación de hora exacta
      await FeedbackScheduler.scheduleDueReminder(
        reminderId: widget.reminderId,
        code: widget.code,
        medication: reminder["medication"] as String,
        hour: reminder["hour"] as String,
        when: next,
      );
    }

    _mostrarPopup(tomo, puntos);
  }

  void _mostrarPopup(bool tomo, int puntos) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text(
          tomo ? "¡Gracias!" : "Gracias por avisar",
          textAlign: TextAlign.center,
        ),
        content: Text(
          tomo
              ? "Excelente \nHas ganado $puntos puntos."
              : "Gracias por tu honestidad \nHas ganado $puntos puntos.",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = 200.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text(
              "Olvidaste marcar el ${widget.medication}\na las ${widget.scheduledHour}, ¿lo tomaste?",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 40),

            // BOTÓN SÍ
            AnimatedScale(
              scale: yesScale,
              duration: const Duration(milliseconds: 150),
              child: GestureDetector(
                onTap: () async {
                  animateYes();
                  await _registrarRespuesta(true);
                },
                child: Container(
                  width: size,
                  height: size,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2E8B57),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.check, size: 90, color: Colors.white),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // BOTÓN NO
            AnimatedScale(
              scale: noScale,
              duration: const Duration(milliseconds: 150),
              child: GestureDetector(
                onTap: () async {
                  animateNo();
                  await _registrarRespuesta(false);
                },
                child: Container(
                  width: size,
                  height: size,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE57373),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.close, size: 90, color: Colors.white),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              "Selecciona una opción para continuar",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

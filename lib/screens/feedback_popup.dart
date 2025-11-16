import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import 'package:intl/intl.dart';

class FeedbackPopupScreen extends StatefulWidget {
  final String patientCode;
  const FeedbackPopupScreen({super.key, required this.patientCode});

  @override
  State<FeedbackPopupScreen> createState() => _FeedbackPopupScreenState();
}

class _FeedbackPopupScreenState extends State<FeedbackPopupScreen> {
  bool _answered = false;
  // ignore: unused_field
  int _points = 0;

  Future<void> _respond(bool yes) async {
    if (_answered) return;
    final fecha = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final puntos = yes ? 30 : 10; // regla definida
    await DBHelper.insertFeedback(
      widget.patientCode,
      fecha,
      yes ? 'si' : 'no',
      puntos,
    );
    final total = await DBHelper.getPoints(widget.patientCode);

    setState(() {
      _answered = true;
      _points = puntos;
    });

    // diálogo de confirmación amable
    showDialog(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (_) => AlertDialog(
        title: Text(yes ? '¡Excelente!' : 'Gracias por responder'),
        content: Text(
          yes
              ? '¡Muy bien! Ganaste $puntos puntos. Ahora tienes un total de $total puntos. 💚'
              : 'Gracias por responder. Ganaste $puntos puntos de honestidad. Total acumulado: $total.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // cierra diálogo
              Navigator.of(context).pop(); // cierra popup
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 30),
                const Text(
                  '¿Cómo te fue con tus medicamentos hasta el momento? 😊',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Selecciona una opción.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _respond(true),
                      icon: const Icon(Icons.check),
                      label: const Text('Sí, los tomé'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton.icon(
                      onPressed: () => _respond(false),
                      icon: const Icon(Icons.close),
                      label: const Text('No pude'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

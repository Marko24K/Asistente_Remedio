// ignore: dangling_library_doc_comments
/** 
import 'package:flutter/material.dart';
import '../data/database_helper.dart';

class WeeklyCheckScreen extends StatelessWidget {
  final String titulo;
  final int pacienteId;

  const WeeklyCheckScreen({
    super.key,
    required this.titulo,
    required this.pacienteId,
  });

  Future<void> _guardarRespuesta(BuildContext context, bool respuesta) async {
    final db = await DBHelper.database;

    int puntos = respuesta ? 30 : 10;

    await db.insert('feedback_semana', {
      'paciente_id': pacienteId,
      'fecha': DateTime.now().toIso8601String(),
      'respuesta': respuesta ? 'si' : 'no',
      'puntos': puntos,
      'synced': 0,
    });

    // Mensaje amable
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(respuesta ? '¡Bien hecho!' : 'Gracias por responder'),
        content: Text(
          respuesta
              ? 'Estás cuidando tu salud 👏💚'
              : 'No pasa nada, mañana es una nueva oportunidad 🌿',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Continuar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Recordatorio")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "¿Cómo te ha ido con tus medicamentos hasta ahora?",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            _buildOption(
              context,
              label: "Sí",
              color: Colors.green,
              icon: Icons.check,
              onTap: () => _guardarRespuesta(context, true),
            ),
            const SizedBox(height: 20),
            _buildOption(
              context,
              label: "No",
              color: Colors.red,
              icon: Icons.close,
              onTap: () => _guardarRespuesta(context, false),
            ),
            const SizedBox(height: 20),
            const Text(
              "Selecciona una opción para continuar",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 170,
        height: 170,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
*/

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ReminderDetailScreen extends StatelessWidget {
  final String name;
  final String dose;
  final String type;
  final String hour;
  final String note;

  const ReminderDetailScreen({
    super.key,
    required this.name,
    required this.dose,
    required this.type,
    required this.hour,
    required this.note,
  });

  IconData _getIcon() {
    final t = type.toLowerCase();
    if (t.contains("inye")) return FontAwesomeIcons.syringe;
    if (t.contains("líq") || t.contains("jarabe") || t.contains("liq")) {
      return FontAwesomeIcons.prescriptionBottle;
    }
    if (t.contains("caps")) return FontAwesomeIcons.capsules;
    if (t.contains("got")) return FontAwesomeIcons.eyeDropper;
    if (t.contains("past") || t.contains("tabl")) {
      return FontAwesomeIcons.pills;
    }
    return FontAwesomeIcons.pills;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Detalle del recordatorio",
          style: TextStyle(color: Colors.black87),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icono + nombre
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: Color(0xFFE4F3E9),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: FaIcon(_getIcon(), size: 36, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 22),

              // Secciones grandes y separadas
              _sectionBlock(
                title: "Dosis",
                value: dose.isEmpty ? "-" : dose,
                icon: Icons.medication,
              ),
              _sectionBlock(
                title: "Tipo",
                value: type.isEmpty ? "-" : type,
                icon: Icons.category,
              ),
              _sectionBlock(
                title: "Próxima toma",
                value: hour,
                icon: Icons.schedule,
              ),
              _sectionBlock(
                title: "Notas",
                value: note.isEmpty ? "Sin notas" : note,
                icon: Icons.notes,
                multiline: true,
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF40916C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Volver",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionBlock({
    required String title,
    required String value,
    required IconData icon,
    bool multiline = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: multiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 26, color: const Color(0xFF2D6A4F)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

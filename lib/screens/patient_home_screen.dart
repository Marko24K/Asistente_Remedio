import 'package:asistente_remedio/services/feedback_scheduler.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../data/database_helper.dart';
import 'reminder_details_screen.dart';
import 'points_screen.dart';

class PatientHomeScreen extends StatefulWidget {
  final String patientCode;

  const PatientHomeScreen({super.key, required this.patientCode});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  List<Map<String, dynamic>> reminders = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadReminders();
  }

  Future<void> loadReminders() async {
    final data = await DBHelper.getReminders(widget.patientCode);

    reminders = data.map((r) {
      final nextTrigger = r['nextTrigger'] != null
          ? DateTime.tryParse(r['nextTrigger'].toString())
          : null;

      return {
        'name': r['medication'] ?? "Medicamento",
        'dose': r['dose'] ?? '',
        'type': r['type'] ?? '',
        'hour': r['hour'] ?? '--:--',
        'notes': r['notes'] ?? '',
        'nextTrigger': nextTrigger,
      };
    }).toList();

    // ordenar por próxima toma
    reminders.sort((a, b) {
      final ta = a['nextTrigger'] as DateTime?;
      final tb = b['nextTrigger'] as DateTime?;
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      return ta.compareTo(tb);
    });

    setState(() => loading = false);
  }

  IconData _getIcon(String? type) {
    final t = (type ?? "").toLowerCase();

    if (t.contains("inyeccion")) return FontAwesomeIcons.syringe;
    if (t.contains("líquido") || t.contains("jarabe")) {
      return FontAwesomeIcons.prescriptionBottle;
    }
    if (t.contains("capsulas")) return FontAwesomeIcons.capsules;
    if (t.contains("gotas")) return FontAwesomeIcons.eyeDropper;
    if (t.contains("pastillas") || t.contains("tabletas")) {
      return FontAwesomeIcons.pills;
    }

    return FontAwesomeIcons.pills;
  }

  String _formatHour(DateTime? t, String fallback) {
    if (t == null) return fallback;
    return "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F4),

      bottomNavigationBar: _bottomNav(),

      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Título centrado
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE4F3E9),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Text(
                  "AsistenteRemedios",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B4332),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : reminders.isEmpty
                    ? _emptyState()
                    : _remindersList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Lista de recordatorios ----------
  Widget _remindersList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "Todos los recordatorios",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.green.shade100,
              child: Text(
                reminders.length.toString(),
                style: TextStyle(
                  color: Colors.green.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            FeedbackScheduler.sendTestNotification(widget.patientCode);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            "Probar notificación",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        Expanded(
          child: ListView.builder(
            itemCount: reminders.length,
            itemBuilder: (_, i) => _reminderCard(reminders[i]),
          ),
        ),
      ],
    );
  }

  Widget _reminderCard(Map<String, dynamic> r) {
    final next = r['nextTrigger'] as DateTime?;
    final nextFormatted = _formatHour(next, r['hour']);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F7F3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReminderDetailScreen(
                name: r['name'],
                dose: r['dose'],
                type: r['type'],
                hour: nextFormatted,
                note: r['notes'],
              ),
            ),
          );
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // icono
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: FaIcon(
                  _getIcon(r['type']),
                  size: 22,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // texto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r['name'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Dosis: ${r['dose']}  •  Tipo: ${r['type']}",
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Próxima: $nextFormatted",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Text(
        "No tienes recordatorios aún",
        style: TextStyle(fontSize: 18, color: Colors.black54),
      ),
    );
  }

  // ---------- NAV INFERIOR ----------
  Widget _bottomNav() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          _navButton(
            icon: FontAwesomeIcons.pills,
            label: "Remedios",
            active: true,
            onTap: () {},
          ),
          _navButton(
            icon: FontAwesomeIcons.star,
            label: "Puntos",
            active: false,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => PointsScreen(code: widget.patientCode),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _navButton({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              icon,
              size: 22,
              color: active ? Colors.green.shade800 : Colors.grey.shade600,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.green.shade800 : Colors.grey.shade600,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

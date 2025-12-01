// lib/screens/patient_home_screen.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../data/database_helper.dart';
import '../services/feedback_scheduler.dart';
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
  bool _schedulingDone = false;

  @override
  void initState() {
    super.initState();
    loadReminders();
  }

  Future<void> loadReminders() async {
    print('📋 [HOME_LOAD] Cargando recordatorios para: ${widget.patientCode}');
    final data = await DBHelper.getReminders(widget.patientCode);
    print('   Total recordatorios en BD: ${data.length}');

    final now = DateTime.now();

    reminders = [];

    for (final r in data) {
      DateTime? next;

      if (r["nextTrigger"] != null) {
        next = DateTime.tryParse(r["nextTrigger"].toString());
      }

      print('📌 Procesando: ${r["medication"]} (ID: ${r["id"]})');

      // si no hay nextTrigger o quedó atrás → recalcular usando hora inicial + startDate
      if (next == null || next.isBefore(now)) {
        print('   ⚠️  nextTrigger nulo o pasado, recalculando...');
        next = DBHelper.calculateNextTrigger(
          r["hour"] as String,
          (r["frequencyHours"] ?? 24) as int,
          startDate: r["startDate"] as String?,
        );

        print('   ✅ Nuevo nextTrigger: $next');
        await DBHelper.updateNextTriggerById(r["id"] as int, next);
      } else {
        print('   ✅ nextTrigger válido: $next');
      }

      // SOLO programar si NO se ha hecho ya en esta sesión
      if (!_schedulingDone) {
        print('   📞 Programando notificación...');
        await FeedbackScheduler.scheduleDueReminder(
          reminderId: r["id"] as int,
          code: r["patientCode"] as String,
          medication: r["medication"] as String,
          hour: r["hour"] as String,
          when: next,
        );
      }

      reminders.add({
        "id": r["id"],
        "patientCode": r["patientCode"],
        "medication": r["medication"],
        "dose": r["dose"],
        "type": r["type"],
        "hour": r["hour"],
        "notes": r["notes"] ?? "",
        "startDate": r["startDate"] ?? "",
        "endDate": r["endDate"] ?? "",
        "frequencyHours": r["frequencyHours"] ?? 24,
        "nextTrigger": next,
      });
    }

    _schedulingDone = true;
    print('✅ Pantalla de inicio cargada (${reminders.length} recordatorios)');

    // DEBUG: Verificar notificaciones pendientes
    await FeedbackScheduler.debugPendingNotifications();

    setState(() => loading = false);
  }

  String _formatHour(DateTime? dt, String fallback) {
    if (dt == null) return fallback;
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }

  IconData _getIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains("inyec")) return FontAwesomeIcons.syringe;
    if (t.contains("líq") || t.contains("jarabe")) {
      return FontAwesomeIcons.prescriptionBottle;
    }
    if (t.contains("caps")) return FontAwesomeIcons.capsules;
    return FontAwesomeIcons.pills;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      bottomNavigationBar: _bottomNav(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              // Header con botón de test
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.circle, color: Colors.green, size: 12),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F4EA),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Text(
                          "Asistente Remedios",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B4332),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Botón de test
                  GestureDetector(
                    onLongPress: () async {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("🧪 Testing"),
                          content: const Text("¿Qué deseas probar?"),
                          actions: [
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                await FeedbackScheduler.testImmediateNotification();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Notificación inmediata enviada',
                                    ),
                                  ),
                                );
                              },
                              child: const Text("Notif Inmediata"),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                await FeedbackScheduler.testScheduledNotification();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Notificación en 5 seg'),
                                  ),
                                );
                              },
                              child: const Text("Notif 5 seg"),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "🧪",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red.shade800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  "Todos los recordatorios",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Spacer(),
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Colors.green.shade100,
                                  child: Text(
                                    reminders.length.toString(),
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            Expanded(
                              child: reminders.isEmpty
                                  ? const Center(
                                      child: Text(
                                        "Sin recordatorios por ahora",
                                        style: TextStyle(
                                          fontSize: 17,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: reminders.length,
                                      itemBuilder: (_, i) =>
                                          _buildReminderTile(reminders[i]),
                                    ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReminderTile(Map<String, dynamic> r) {
    final DateTime? next = r["nextTrigger"];
    final now = DateTime.now();
    final isLate = next != null && next.isBefore(now);

    final nextHour = _formatHour(next, r["hour"] ?? "--:--");

    return GestureDetector(
      onTap: () async {
        final changed = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ReminderDetailScreen(reminder: r)),
        );

        if (changed == true) {
          setState(() => loading = true);
          await loadReminders();
        }
      },

      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFE6F4EA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white,
              child: FaIcon(
                _getIcon(r["type"] ?? ""),
                size: 20,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r["medication"] ?? "Medicamento",
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Dosis: ${r["dose"] ?? ""} • Tipo: ${r["type"] ?? ""}",
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  isLate
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE57373),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "No marcada $nextHour",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        )
                      : Text(
                          "Próxima: $nextHour",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade800,
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

  Widget _bottomNav() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          _navItem(
            icon: FontAwesomeIcons.pills,
            label: "Remedios",
            active: true,
            onTap: () {},
          ),
          _navItem(
            icon: FontAwesomeIcons.star,
            label: "Puntos",
            active: false,
            onTap: () {
              Navigator.push(
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

  Widget _navItem({
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

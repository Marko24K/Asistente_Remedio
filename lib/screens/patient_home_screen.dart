import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../data/database_helper.dart';
import 'reminder_details_screen.dart';

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
    loadRemindersFromDB();
  }

  Future<void> loadRemindersFromDB() async {
    final data = await DBHelper.getReminders();

    reminders = data.map((r) {
      return {
        'name': r['medication'] ?? "Medicamento",
        'time': r['time'] ?? "--:--",
        'dose': r['dose'] ?? '',
        'type': r['type'] ?? '',
        'notes': r['notes'] ?? '',
      };
    }).toList();

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            children: [
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4EA),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  child: const Text(
                    "AsistenteRemedios",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Color(0xFF1B4332),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

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
                      : reminders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.notifications_none,
                                size: 50,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 10),
                              Text(
                                "Sin recordatorios por ahora",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                "Tu cuidador los añadirá pronto",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: reminders.length,
                          itemBuilder: (context, i) {
                            final r = reminders[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE6F4EA),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ReminderDetailScreen(
                                      name: r['name'],
                                      dose: r['dose'],
                                      type: r['type'],
                                      hour: r['time'],
                                      note: r['notes'],
                                    ),
                                  ),
                                ),
                                leading: CircleAvatar(
                                  radius: 22,
                                  backgroundColor: Colors.white,
                                  child: FaIcon(
                                    _getIcon(r['type']),
                                    size: 20,
                                    color: Colors.black87,
                                  ),
                                ),
                                title: Text(
                                  r['name'],
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  "Hora: ${r['time']}",
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(dynamic t) {
    final type = (t ?? "").toString().toLowerCase();

    if (type.contains("inye")) return FontAwesomeIcons.syringe;
    if (type.contains("líq") || type.contains("jarabe")) {
      return FontAwesomeIcons.prescriptionBottle;
    }
    if (type.contains("caps")) return FontAwesomeIcons.capsules;

    return FontAwesomeIcons.pills;
  }
}

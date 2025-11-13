import 'dart:io';
import 'package:asistente_remedio/screens/patient_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CaregiverDashboardScreen extends StatefulWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  State<CaregiverDashboardScreen> createState() =>
      _CaregiverDashboardScreenState();
}

class _CaregiverDashboardScreenState extends State<CaregiverDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await _showExitDialog(context);
        if (shouldExit == true) {
          if (Platform.isAndroid) {
            SystemNavigator.pop();
          } else {
            exit(0);
          }
          return true;
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text(
            "AsistenteRemedios",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B4332),
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE6E6E6)),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// --- ENCABEZADO (como en la imagen)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            "Pacientes",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B4332),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFFD8F3DC),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.people_alt_outlined,
                                  color: Color(0xFF1B4332),
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  "2",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1B4332),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF74C69D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 12,
                          ),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Función de crear paciente"),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.person_add_alt_1_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: const Text(
                          "Crear paciente",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  /// --- TARJETAS DE PACIENTES
                  _PatientCard(
                    name: "María López",
                    age: 78,
                    reminders: 3,
                    nextTaken: 1,
                    nextMissed: 1,
                    icon: Icons.elderly_woman_outlined,
                  ),
                  _PatientCard(
                    name: "Carlos Pérez",
                    age: 82,
                    reminders: 2,
                    nextTaken: 1,
                    nextMissed: 0,
                    icon: Icons.elderly_outlined,
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF40916C),
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_outlined),
              label: 'Pacientes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              label: 'Ajustes',
            ),
          ],
          currentIndex: 0,
          onTap: (index) {
            if (index == 1) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Pantalla de ajustes en desarrollo"),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  /// --- Diálogo de salida ---
  Future<bool?> _showExitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Deseas salir de la aplicación?"),
        content: const Text("Se cerrará completamente AsistenteRemedios."),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF40916C),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Salir"),
          ),
        ],
      ),
    );
  }
}

/// --- Tarjeta de Paciente ---
class _PatientCard extends StatelessWidget {
  final String name;
  final int age;
  final int reminders;
  final int nextTaken;
  final int nextMissed;
  final IconData icon;

  const _PatientCard({
    required this.name,
    required this.age,
    required this.reminders,
    required this.nextTaken,
    required this.nextMissed,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F5EE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD8F3DC)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF74C69D),
          radius: 24,
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        title: Text(
          "$name - $age años",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B4332),
          ),
        ),
        subtitle: Text(
          "$reminders recordatorios\nPróximos: 1 · Tomado: $nextTaken · No tomado: $nextMissed",
          style: const TextStyle(fontSize: 13, color: Colors.black87),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          color: Color(0xFF1B4332),
          size: 16,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PatientDetailsScreen()),
          );
        },
      ),
    );
  }
}

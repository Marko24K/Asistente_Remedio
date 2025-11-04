import 'package:flutter/material.dart';

class CaregiverDashboardScreen extends StatelessWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBFA),
      appBar: AppBar(
        title: const Text(
          "Pacientes a cargo",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B4332),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // 🔹 elimina la flecha
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _PatientCard(
            name: "Ana Pérez",
            reminders: 3,
            time: "08:00",
            condition: "Diabetes tipo 2",
            image: "assets/images/paciente1.png",
          ),
          _PatientCard(
            name: "Luis Romero",
            reminders: 2,
            time: "14:00",
            condition: "Hipertensión",
            image: "assets/images/paciente2.png",
          ),
          _PatientCard(
            name: "María López",
            reminders: 4,
            time: "21:00",
            condition: "Artritis",
            image: "assets/images/paciente3.png",
          ),
        ],
      ),

      // 🔹 Barra inferior de navegación (sin icono de alertas)
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
    );
  }
}

class _PatientCard extends StatelessWidget {
  final String name;
  final int reminders;
  final String time;
  final String condition;
  final String image;

  const _PatientCard({
    required this.name,
    required this.reminders,
    required this.time,
    required this.condition,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 28, backgroundImage: AssetImage(image)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Condición principal: $condition",
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9F5EC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "$reminders recordatorios",
                        style: const TextStyle(
                          color: Color(0xFF1B4332),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Próximo $time",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

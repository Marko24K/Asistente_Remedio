import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'reminder_details_screen.dart';

class PatientHomeScreen extends StatelessWidget {
  const PatientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reminders = [
      {
        'name': 'Paracetamol 500mg',
        'dose': '1 tableta',
        'type': 'Pastilla',
        'next': '08:00',
        'status': 'pending',
      },
      {
        'name': 'Insulina Rápida',
        'dose': '6 U',
        'type': 'Inyección',
        'next': '12:30',
        'status': 'pending',
      },
      {
        'name': 'Jarabe Tos',
        'dose': '10 ml',
        'type': 'Líquido',
        'next': '07:10',
        'status': 'missed',
      },
      {
        'name': 'Vitamina D',
        'dose': '1 cápsula',
        'type': 'Cápsula',
        'next': '20:00',
        'status': 'pending',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Encabezado centrado
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4EA),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: Colors.green, size: 12),
                      SizedBox(width: 8),
                      Text(
                        "AsistenteRemedios",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF1B4332),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 🔹 Contenedor principal
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Encabezado interno
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Todos los recordatorios",
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            reminders.length.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Lista de recordatorios
                    Column(
                      children: reminders.map((reminder) {
                        final isMissed = reminder['status'] == 'missed';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F4EA),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            onTap: () {
                              // 🔸 Navegar a detalle
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ReminderDetailScreen(
                                    name: reminder['name']!,
                                    dose: reminder['dose']!,
                                    type: reminder['type']!,
                                    hour: reminder['next']!,
                                    note:
                                        'Tomar con agua, después de las comidas. ddsfsdf sdfsdfsdfsdffssssssssssssssssss',
                                  ),
                                ),
                              );
                            },
                            leading: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: FaIcon(
                                  _getIcon(reminder['type']!),
                                  color: Colors.black87,
                                  size: 18,
                                ),
                              ),
                            ),
                            title: Text(
                              reminder['name']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.5,
                                color: Colors.black87,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Dosis: ${reminder['dose']}  •  Tipo: ${reminder['type']}",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                isMissed
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade100,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          "No marcada ${reminder['next']}",
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      )
                                    : Text(
                                        "Próxima: ${reminder['next']}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: Colors.black87,
                                        ),
                                      ),
                              ],
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // 🔹 Barra inferior
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _BottomButton(
                      icon: FontAwesomeIcons.pills,
                      label: 'Remedios',
                      active: true,
                    ),
                    _BottomButton(icon: FontAwesomeIcons.star, label: 'Puntos'),
                    _BottomButton(
                      icon: FontAwesomeIcons.gear,
                      label: 'Configuración',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pastilla':
        return FontAwesomeIcons.pills;
      case 'inyección':
        return FontAwesomeIcons.syringe;
      case 'líquido':
        return FontAwesomeIcons.prescriptionBottle;
      case 'cápsula':
        return FontAwesomeIcons.capsules;
      default:
        return FontAwesomeIcons.pills;
    }
  }
}

class _BottomButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _BottomButton({
    Key? key,
    required this.icon,
    required this.label,
    this.active = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final activeColor = Colors.green.shade600;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FaIcon(icon, color: active ? activeColor : Colors.grey, size: 20),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: active ? activeColor : Colors.grey,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

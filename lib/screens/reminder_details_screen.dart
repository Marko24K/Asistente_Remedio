import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ReminderDetailScreen extends StatefulWidget {
  final String name;
  final String dose;
  final String type;
  final String hour;
  final String note;

  const ReminderDetailScreen({
    Key? key,
    required this.name,
    required this.dose,
    required this.type,
    required this.hour,
    required this.note,
  }) : super(key: key);

  @override
  State<ReminderDetailScreen> createState() => _ReminderDetailScreenState();
}

class _ReminderDetailScreenState extends State<ReminderDetailScreen>
    with TickerProviderStateMixin {
  bool _expandedNote = false;

  @override
  Widget build(BuildContext context) {
    const double sectionSpacing = 18.0;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Recordatorio en progreso',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Tarjeta principal
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icono + nombre
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F4EA),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: FaIcon(
                            FontAwesomeIcons.pills,
                            size: 18,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${widget.dose} • ${widget.type}",
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Hora programada
                  _buildInfoRow("Hora programada", widget.hour),
                  const SizedBox(height: 10),
                  Divider(color: Colors.grey.shade200, thickness: 1),

                  const SizedBox(height: 18),

                  // Ventana recomendada
                  _buildInfoRow("Ventana recomendada", "07:50 – 08:10"),
                  const SizedBox(height: 10),
                  Divider(color: Colors.grey.shade200, thickness: 1),

                  const SizedBox(height: 18),

                  // Nota con truncado y ver mas
                  const Text(
                    "Nota",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // AnimatedSize para animar la expansión
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: ConstrainedBox(
                      constraints: _expandedNote
                          ? const BoxConstraints()
                          : const BoxConstraints(maxHeight: 44),
                      child: Text(
                        widget.note,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                        softWrap: true,
                        overflow: TextOverflow.fade,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Ver más / Ver menos
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _expandedNote = !_expandedNote;
                      });
                    },
                    child: Text(
                      _expandedNote ? "Ver menos" : "Ver más",
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),
                  Divider(color: Colors.grey.shade200, thickness: 1),
                ],
              ),
            ),

            SizedBox(height: sectionSpacing),

            // Bloque estado
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4EA),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: const Row(
                children: [
                  Icon(Icons.access_time, color: Colors.green, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Recordatorio en progreso\nDeslice para confirmar cuando haya tomado la dosis",
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 14.5,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: sectionSpacing),

            // Botón deslizable (visual)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4EA),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12.withOpacity(0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.double_arrow,
                        color: Colors.green,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "Deslice para confirmar toma",
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: sectionSpacing),

            // Posponer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4EA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.alarm, color: Colors.black87, size: 20),
                    SizedBox(width: 10),
                    Text(
                      "Posponer",
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: sectionSpacing),

            // Omitir dosis
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade400,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.close_rounded, color: Colors.white, size: 22),
                    SizedBox(width: 10),
                    Text(
                      "Omitir dosis",
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // Helper que muestra título y valor
  Widget _buildInfoRow(String title, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../data/database_helper.dart';
import 'points_screen.dart';
import 'patient_home_screen.dart';

class ConfirmScreen extends StatefulWidget {
  final String code;

  const ConfirmScreen({super.key, required this.code});

  @override
  State<ConfirmScreen> createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends State<ConfirmScreen>
    with SingleTickerProviderStateMixin {
  double yesScale = 1.0;
  double noScale = 1.0;

  final AudioPlayer _player = AudioPlayer();

  Future<void> _playSound(String file) async {
    await _player.stop(); // detener sonido previo
    await _player.play(AssetSource("sounds/$file"));
  }

  void _animateYes() {
    setState(() => yesScale = 0.90);
    Future.delayed(const Duration(milliseconds: 120), () {
      setState(() => yesScale = 1.0);
    });
  }

  void _animateNo() {
    setState(() => noScale = 0.90);
    Future.delayed(const Duration(milliseconds: 120), () {
      setState(() => noScale = 1.0);
    });
  }

  void _showPopup(BuildContext context, String msg, bool isYes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titlePadding: const EdgeInsets.only(top: 20),
        title: Icon(
          isYes ? Icons.check_circle : Icons.warning_rounded,
          color: isYes ? Colors.green : Colors.red,
          size: 55,
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Text(
            msg,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => PatientHomeScreen(patientCode: widget.code),
                ),
                (_) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              "Volver",
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => PointsScreen(code: widget.code),
                ),
                (_) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              "Puntos",
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double size = 165;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),

      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),

            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  /// =============================
                  /// TEXTO SUPERIOR
                  /// =============================
                  const Text(
                    "¿Has tomado tus\nmedicamentos hasta el momento?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// =============================
                  /// BOTÓN SÍ (SOLO ÍCONO)
                  /// =============================
                  AnimatedScale(
                    scale: yesScale,
                    duration: const Duration(milliseconds: 150),
                    child: GestureDetector(
                      onTap: () async {
                        _animateYes();
                        _playSound("correct-ding.mp3");
                        await DBHelper.addPoints(15, widget.code);

                        _showPopup(
                          // ignore: use_build_context_synchronously
                          context,
                          "¡Excelente trabajo! 🟢\nHas ganado 15 puntos.",
                          true,
                        );
                      },
                      child: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.25),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 70,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// =============================
                  /// BOTÓN NO (SOLO ÍCONO)
                  /// =============================
                  AnimatedScale(
                    scale: noScale,
                    duration: const Duration(milliseconds: 150),
                    child: GestureDetector(
                      onTap: () async {
                        _animateNo();
                        _playSound("confirm-no.mp3");
                        await DBHelper.addPoints(5, widget.code);

                        _showPopup(
                          // ignore: use_build_context_synchronously
                          context,
                          "Gracias por tu sinceridad, no te preocupes vuelve a intentarlo 🔴\nHas ganado 5 puntos.",
                          false,
                        );
                      },
                      child: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          color: Colors.red.shade400,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.25),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 70,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 35),

                  /// =============================
                  /// TEXTO INFERIOR
                  /// =============================
                  const Text(
                    "Selecciona una opción para continuar",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

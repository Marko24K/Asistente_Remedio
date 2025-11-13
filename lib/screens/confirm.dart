import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class ReminderDetailScreen extends StatefulWidget {
  final String medicineName;
  final String dose;
  final String time;

  const ReminderDetailScreen({
    super.key,
    required this.medicineName,
    required this.dose,
    required this.time,
  });

  @override
  State<ReminderDetailScreen> createState() => _ReminderDetailScreenState();
}

class _ReminderDetailScreenState extends State<ReminderDetailScreen>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  double _slideValue = 0.0;
  bool _completed = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  static const double sliderWidth = 260.0;
  static const double thumbSize = 60.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _playSuccessSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/tono-mensaje-3.mp3'));
    } catch (_) {}
  }

  void _onSlideUpdate(DragUpdateDetails details) {
    if (!_completed) {
      setState(() {
        _slideValue += details.primaryDelta!;
        _slideValue = _slideValue.clamp(0.0, sliderWidth - thumbSize);
      });
    }
  }

  void _onSlideEnd(DragEndDetails details) {
    if (_slideValue >= sliderWidth - thumbSize - 10 && !_completed) {
      // completado
      setState(() {
        _slideValue = sliderWidth - thumbSize;
        _completed = true;
      });

      _playSuccessSound();
      _animationController.forward();

      Future.delayed(const Duration(milliseconds: 1000), () {
        Navigator.push(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (_) => const ConfirmScreen()),
        );
      });
    } else {
      // vuelve al inicio
      setState(() {
        _slideValue = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Recordatorio",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B4332),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B4332)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información del medicamento
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.medicineName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B4332),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Dosis: ${widget.dose} | Hora: ${widget.time}",
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 50),

              // Slider personalizado
              Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: _completed ? thumbSize : sliderWidth,
                  height: 70,
                  decoration: BoxDecoration(
                    color: _completed
                        ? const Color(0xFF40916C)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(35),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // Fondo verde que se llena progresivamente
                      if (!_completed)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          width: _slideValue + thumbSize / 2,
                          height: 70,
                          decoration: BoxDecoration(
                            color: const Color(0xFF40916C),
                            borderRadius: BorderRadius.circular(35),
                          ),
                        ),

                      // Texto central
                      if (!_completed)
                        const Center(
                          child: Text(
                            "Desliza para confirmar la toma",
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                      // Botón deslizante o icono final
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 150),
                        left: _completed
                            ? (sliderWidth / 2) - (thumbSize / 2)
                            : _slideValue,
                        top: 5,
                        child: GestureDetector(
                          onHorizontalDragUpdate: _onSlideUpdate,
                          onHorizontalDragEnd: _onSlideEnd,
                          child: _completed
                              ? ScaleTransition(
                                  scale: _scaleAnimation,
                                  child: Container(
                                    width: thumbSize,
                                    height: thumbSize,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Color(0xFF40916C),
                                      size: 32,
                                    ),
                                  ),
                                )
                              : Container(
                                  width: thumbSize,
                                  height: thumbSize,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.3),
                                        blurRadius: 6,
                                        offset: const Offset(2, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_ios,
                                    color: Color(0xFF40916C),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Botones adicionales
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Recordatorio pospuesto"),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Color(0xFF40916C)),
                      ),
                      child: const Text(
                        "Posponer",
                        style: TextStyle(
                          color: Color(0xFF40916C),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Dosis omitida")),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text(
                        "Omitir dosis",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ConfirmScreen extends StatelessWidget {
  const ConfirmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Confirmación",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B4332),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Color(0xFF40916C),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 50),
            ),
            const SizedBox(height: 24),
            const Text(
              "¡Medicación confirmada!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B4332),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Se ha registrado que el paciente\n tomó su medicamento correctamente.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF40916C),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Volver al inicio",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import 'patient_home_screen.dart';

class PatientLoginScreen extends StatefulWidget {
  const PatientLoginScreen({super.key});

  @override
  State<PatientLoginScreen> createState() => _PatientLoginScreenState();
}

class _PatientLoginScreenState extends State<PatientLoginScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;

  Future<void> _submitCode() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final code = _codeController.text.trim();

    if (code.isEmpty || code.length < 4) {
      setState(() {
        _errorMessage = "Ingrese un código válido";
        _loading = false;
      });
      return;
    }

    final patient = await DBHelper.getPatient(code);

    if (!mounted) return;

    if (patient != null) {
      // Si existe → navegar a Home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => PatientHomeScreen(patientCode: code)),
      );
    } else {
      // No existe en BD
      setState(() {
        _errorMessage = "Código no encontrado";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F4),
      appBar: AppBar(
        title: const Text("Ingresar código"),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black87,
      ),

      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const SizedBox(height: 10),

            const Text(
              "Ingresa el código asignado por tu cuidador",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                color: Colors.black87,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 35),

            TextField(
              controller: _codeController,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: "Ejemplo: A92KD7",
                errorText: _errorMessage,
                hintStyle: const TextStyle(fontSize: 20, color: Colors.black38),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 10,
                ),
              ),
              style: const TextStyle(
                fontSize: 26,
                letterSpacing: 3,
                fontWeight: FontWeight.w600,
              ),
              maxLength: 8,
            ),

            const SizedBox(height: 20),

            _loading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _submitCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF40916C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "INGRESAR",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../services/sync_service.dart';
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

    if (code.isEmpty) {
      setState(() {
        _errorMessage = "Ingrese un código válido";
        _loading = false;
      });
      return;
    }

    final exists = await SyncService().syncPatientByCode(code);

    if (!mounted) return;

    if (exists) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => PatientHomeScreen(patientCode: code)),
      );
    } else {
      setState(() {
        _errorMessage = "Código no encontrado";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ingresar código")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Ingresa el código asignado por tu cuidador",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _codeController,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Ejemplo: 4D8K92",
                errorText: _errorMessage,
              ),
              style: const TextStyle(fontSize: 22, letterSpacing: 3),
              maxLength: 8,
            ),
            const SizedBox(height: 20),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _submitCode,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                    ),
                    child: const Text(
                      "INGRESAR",
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

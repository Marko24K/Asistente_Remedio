import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/database_helper.dart';
import 'patient_home_screen.dart';

class PatientLoginScreen extends StatefulWidget {
  const PatientLoginScreen({super.key});

  @override
  State<PatientLoginScreen> createState() => _PatientLoginScreenState();
}

class _PatientLoginScreenState extends State<PatientLoginScreen> {
  final TextEditingController _code = TextEditingController();
  bool loading = false;
  String? error;

  Future<void> _login() async {
    setState(() {
      loading = true;
      error = null;
    });

    final code = _code.text.trim().toUpperCase();

    if (code.isEmpty) {
      setState(() {
        error = "Ingrese un código válido";
        loading = false;
      });
      return;
    }

    // ✅ Validación offline usando SQLite
    final paciente = await DBHelper.getPatient(code);

    if (paciente == null) {
      setState(() {
        error = "Código no encontrado";
        loading = false;
      });
      return;
    }

    // ✅ Guardar login persistente
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("patientCode", code);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => PatientHomeScreen(patientCode: code)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ingresar código")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              "Ingresa el código asignado por tu cuidador",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),

            TextField(
              controller: _code,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 3),
              decoration: InputDecoration(
                errorText: error,
                hintText: "A92KD7",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLength: 8,
            ),

            const SizedBox(height: 20),

            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 14,
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

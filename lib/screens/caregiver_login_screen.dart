import 'package:flutter/material.dart';
import 'caregiver_dashboard_screen.dart';

class CaregiverLoginScreen extends StatefulWidget {
  const CaregiverLoginScreen({super.key});

  @override
  State<CaregiverLoginScreen> createState() => _CaregiverLoginScreenState();
}

class _CaregiverLoginScreenState extends State<CaregiverLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool isRegistering = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isRegistering ? "Registrar Cuidador" : "Iniciar Sesión"),
        backgroundColor: const Color(0xFF40916C),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Correo electrónico",
                ),
                validator: (value) =>
                    value!.isEmpty ? "Ingrese un correo válido" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Contraseña"),
                obscureText: true,
                validator: (value) =>
                    value!.isEmpty ? "Ingrese una contraseña" : null,
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CaregiverDashboardScreen(),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF40916C),
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  isRegistering ? "Registrar" : "Ingresar",
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  setState(() => isRegistering = !isRegistering);
                },
                child: Text(
                  isRegistering
                      ? "¿Ya tienes cuenta? Inicia sesión"
                      : "¿No tienes cuenta? Regístrate",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// lib/screens/welcome_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'role_selection_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _loading = false;

  Future<void> _start() async {
    setState(() => _loading = true);

    // 1) Inicializar notificaciones y pedir permiso
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    // 2) Inicializar catálogo de medicamentos si está vacío
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'asistente_remedios.db');
    final db = await openDatabase(path);

    final count = Sqflite.firstIntValue(
      await db.rawQuery("SELECT COUNT(*) FROM medicamentos"),
    );

    if (count == 0) {
      final data = await rootBundle.loadString(
        "assets/medicamentos/medicamentos_cl.json",
      );
      final List<dynamic> lista = jsonDecode(data);
      for (var nombre in lista) {
        await db.insert("medicamentos", {"nombre": nombre});
      }
    }

    // 3) Marcar que ya se mostró la bienvenida
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('welcomeSeen', true);

    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Image.asset('assets/images/presentacion.png', height: 320),
              const SizedBox(height: 28),
              const Text(
                "¡Bienvenido a\nAsistenteRemedios!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D6A4F),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Tu apoyo diario para mantener la adherencia a tus tratamientos.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, color: Colors.grey[700]),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _loading ? null : _start,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF40916C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "COMENZAR",
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

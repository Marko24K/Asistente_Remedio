import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'medicamento_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _loading = false;

  Future<void> _inicializarApp() async {
    setState(() => _loading = true);

    //  Pedir permisos de notificaciones
    final android = const AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notifications.initialize(InitializationSettings(android: android));
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    // Cargar medicamentos desde JSON a SQLite (solo una vez)
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'asistente_remedios.db');
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute(
          'CREATE TABLE medicamentos(id INTEGER PRIMARY KEY, nombre TEXT)',
        );
      },
    );

    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM medicamentos'),
    );
    if (count == 0) {
      final data = await rootBundle.loadString(
        'assets/medicamentos/medicamentos_cl.json',
      );
      final List<dynamic> lista = jsonDecode(data);
      for (var nombre in lista) {
        await db.insert('medicamentos', {'nombre': nombre});
      }
    }

    //  Pequeño retardo visual
    await Future.delayed(const Duration(milliseconds: 800));

    //  Navegar al flujo principal
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MedicamentoScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),

              // Imagen principal
              Image.asset(
                'assets/images/presentacion.png',
                height: 500,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 40),
              const Text(
                '¡Bienvenido a\nAsistenteRemedios!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D6A4F),
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),
              Text(
                'Convierte tu rutina de medicamentos\nen una experiencia simple y motivadora.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Botón principal
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _loading ? null : _inicializarApp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF40916C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                    shadowColor: const Color(0xFF40916C),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'COMENZAR',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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

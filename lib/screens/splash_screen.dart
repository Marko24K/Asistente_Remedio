import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'medicamento_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _initApp();
  }

  Future<void> _initApp() async {
    await _pedirPermisos();
    await _cargarMedicamentos();
    await Future.delayed(const Duration(seconds: 2)); // animación visible
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MedicamentoScreen()),
    );
  }

  Future<void> _pedirPermisos() async {
    final android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notifications.initialize(InitializationSettings(android: android));
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> _cargarMedicamentos() async {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: Tween(begin: 0.9, end: 1.1).animate(_controller),
              child: const Icon(
                Icons.medication_liquid,
                color: Colors.teal,
                size: 100,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "AsistenteRemedios",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const CircularProgressIndicator(color: Colors.teal),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../screens/role_selection_screen.dart';
import '../data/database_helper.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  // ---------------------------------------------------------
  // Comprobar si ya se mostró la pantalla de bienvenida
  // ---------------------------------------------------------
  Future<void> _checkFirstLaunch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    bool shown = prefs.getBool("welcomeSeen") ?? false;

    if (shown) {
      // Ir directo
      Future.microtask(() {
        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
        );
      });
    }
  }

  // ---------------------------------------------------------
  // Inicialización completa
  // ---------------------------------------------------------
  Future<void> _initializeApp() async {
    setState(() => _loading = true);

    // Pedir permisos de notificaciones
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notifications.initialize(
      const InitializationSettings(android: android),
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    // Cargar medicamentos desde JSON SOLO SI NO EXISTEN
    await _loadMedicamentosIfNeeded();

    // Guardar bandera de que ya se vio
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool("welcomeSeen", true);

    await DBHelper.insertOrUpdatePatientLocal({
      "code": "A92KD7",
      "name": "Juan Topo",
      "points": 0,
    });

    await DBHelper.insertReminder({
      "patientCode": "A92KD7",
      "medId": 1, // ← ID del medicamento
      "dose": "1 tableta",
      "type": "pastilla",
      "hour": "08:00",
      "notes": "Tomar con agua",
      "duration": 30,
      "frequencyHours": 12,
      "startDate": DateTime.now().toIso8601String(),
      "endDate": DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      "nextTrigger": DateTime.now()
          .add(const Duration(hours: 1))
          .toIso8601String(),
    });
    await DBHelper.insertReminder({
      "patientCode": "A92KD7",
      "medId": 2, // ← ID del medicamento
      "dose": "1 ml",
      "type": "líquido",
      "hour": "10:00",
      "notes": "Tomar con agua",
      "duration": 30,
      "frequencyHours": 12,
      "startDate": DateTime.now().toIso8601String(),
      "endDate": DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      "nextTrigger": DateTime.now()
          .add(const Duration(hours: 1))
          .toIso8601String(),
    });
    // Pequeño delay visual
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
    );
  }

  // ---------------------------------------------------------
  // Cargar medicamentos desde JSON solo la primera vez
  // ---------------------------------------------------------
  Future<void> _loadMedicamentosIfNeeded() async {
    // Inicializar la BD correctamente
    await DBHelper.initDB();
    final db = await DBHelper.database;

    // Verificar si ya existe la tabla y si tiene datos
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM medicamentos'),
    );

    if (count != null && count > 0) {
      // ignore: avoid_print
      print("Medicamentos ya cargados.");
      return;
    }

    // ignore: avoid_print
    print("Cargando medicamentos desde el JSON...");

    // Leer el JSON
    final jsonString = await rootBundle.loadString(
      'assets/medicamentos/medicamentos_cl.json',
    );
    final List<dynamic> content = jsonDecode(jsonString);

    for (var nombre in content) {
      await DBHelper.insertMedicamento(nombre);
    }
  }

  // ---------------------------------------------------------
  // UI
  // ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),

                child: Padding(
                  padding: const EdgeInsets.all(24.0),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),

                      // Imagen
                      SizedBox(
                        height: 300,
                        child: Image.asset(
                          'assets/images/presentacion.png',
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(height: 30),

                      const Text(
                        '¡Bienvenido a\nAsistenteRemedios!',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D6A4F),
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      Text(
                        'Convierte tu rutina de medicamentos en una experiencia\nsimple, clara y motivadora.',
                        style: TextStyle(
                          fontSize: 17,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 40),

                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _initializeApp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF40916C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 5,
                          ),
                          child: _loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'COMENZAR',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

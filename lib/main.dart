// lib/main.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'data/database_helper.dart';
import 'services/feedback_scheduler.dart';

import 'screens/welcome_screen.dart';
import 'screens/patient_login.dart';
import 'screens/patient_home_screen.dart';
import 'screens/due_reminder_screen.dart';
import 'screens/confirm_missed_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DBHelper.initDB();

  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation("America/Santiago"));

  await FeedbackScheduler.init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool loading = true;
  bool welcomeSeen = false;
  String? savedCode;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    welcomeSeen = prefs.getBool('welcomeSeen') ?? false;
    savedCode = prefs.getString('patientCode');
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    Widget startScreen;
    if (!welcomeSeen) {
      startScreen = const WelcomeScreen();
    } else if (savedCode != null) {
      startScreen = PatientHomeScreen(patientCode: savedCode!);
    } else {
      startScreen = const PatientLoginScreen();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      title: 'Asistente Remedios',
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF40916C)),
      ),

      routes: {"/login": (_) => const PatientLoginScreen()},

      onGenerateRoute: (settings) {
        if (settings.name == "/due_reminder") {
          final args = settings.arguments as Map;
          return MaterialPageRoute(
            builder: (_) => DueReminderScreen(reminder: args),
          );
        }

        if (settings.name == "/confirm_missed") {
          final args = settings.arguments as Map;
          return MaterialPageRoute(
            builder: (_) => ConfirmMissedScreen(
              code: args["code"],
              reminderId: args["reminderId"],
              medication: args["medication"],
              scheduledHour: args["scheduledHour"],
            ),
          );
        }

        return null;
      },

      home: startScreen,
    );
  }
}

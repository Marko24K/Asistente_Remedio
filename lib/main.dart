import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'screens/welcome_screen.dart';
import 'screens/confirm.dart';
import 'services/feedback_scheduler.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  tz.initializeTimeZones();

  await FeedbackScheduler.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Asistente Remedios',
      theme: ThemeData(scaffoldBackgroundColor: Colors.white),
      home: const WelcomeScreen(),

      routes: {
        "/confirm": (context) {
          final code = ModalRoute.of(context)!.settings.arguments as String;
          return ConfirmScreen(code: code);
        },
      },
    );
  }
}

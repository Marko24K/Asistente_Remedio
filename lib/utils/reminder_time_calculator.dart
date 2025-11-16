import 'package:intl/intl.dart';

class ReminderCalculator {
  static DateTime calculateNextReminder({
    required String baseTime,
    required String frequency,
    required DateTime startDate,
  }) {
    final now = DateTime.now();
    final timeParts = baseTime.split(":");

    DateTime scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );

    if (frequency.toLowerCase().contains("cada")) {
      // ejemplo: "cada 8 horas"
      final hours = int.parse(frequency.replaceAll(RegExp(r'[^0-9]'), ""));
      while (scheduled.isBefore(now)) {
        scheduled = scheduled.add(Duration(hours: hours));
      }
      return scheduled;
    }

    // Frecuencia diaria por defecto
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(Duration(days: 1));
    }

    return scheduled;
  }

  static String format(DateTime time) {
    return DateFormat("HH:mm").format(time);
  }
}

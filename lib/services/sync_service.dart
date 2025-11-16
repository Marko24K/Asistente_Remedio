import '../data/database_helper.dart';
import 'firestore_service.dart';

class SyncService {
  final FirestoreService _fs = FirestoreService();

  // Trae paciente por código, guarda local y trae recordatorios
  Future<bool> syncPatientByCode(String code) async {
    final docRef = _fs.db.collection('patients').doc(code);
    final doc = await docRef.get();
    if (!doc.exists) return false;

    final data = doc.data()!;
    data['code'] = code;

    // Guarda paciente localmente
    await DBHelper.insertOrUpdatePatientLocal({
      'code': data['code'],
      'name': data['name'] ?? data['nombre'],
      'points': data['points'] ?? 0,
    });

    // Obtener recordatorios remotos y guardarlos localmente
    final reminders = await _fs.getRemindersForPatient(code);
    for (var r in reminders) {
      await DBHelper.insertOrUpdateReminderLocal(r, code);
    }

    return true;
  }
}

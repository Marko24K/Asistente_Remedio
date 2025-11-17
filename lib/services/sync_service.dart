/*import '../data/database_helper.dart';
import 'firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SyncService {
  final FirestoreService _fs = FirestoreService();

  /// 🔥 Sincroniza paciente usando Firestore REAL
  Future<bool> syncPatientByCode(String patientId) async {
    final user = FirebaseAuth.instance.currentUser;


    if (user == null) return false;

    final caregiverId = "caregiver123";
    

    // Obtener doc del paciente en Firestore
    final doc = await _fs.getPatient(caregiverId, patientId);

    if (!doc.exists) return false;

    final data = doc.data()!;
    data['code'] = patientId;

    // Guardar en SQLite local
    await DBHelper.insertOrUpdatePatientLocal({
      'code': patientId,
      'name': data['name'],
      'points': data['points'] ?? 0,
    });

    // Obtener recordatorios del paciente
    final reminders = await _fs.db
      .collection('patients')
      .doc(code)
      .collection("reminders")
      .get();

    for (var r in reminders) {
      await DBHelper.insertOrUpdateReminderLocal(r, patientId);
    }

    return true;
  }
}
*/
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  FirebaseFirestore get db => _db;

  ///  Obtener datos del paciente por código
  Future<DocumentSnapshot<Map<String, dynamic>>> getPatient(String code) {
    return _db.collection("patients").doc(code).get();
  }

  /// 🔥 Obtener lista de recordatorios del paciente
  Future<List<Map<String, dynamic>>> getReminders(String code) async {
    final snap = await _db
        .collection("patients")
        .doc(code)
        .collection("reminders")
        .get();

    return snap.docs.map((doc) {
      final data = doc.data();
      return {
        "id": doc.id,
        "medication":
            data["medication"] ?? data["medicamento"] ?? data["name"] ?? "",
        "time": data["time"] ?? data["hora"] ?? "",
        "frequency": data["frequency"] ?? "",
        "status": data["status"] ?? "active",
        "notes": data["notes"] ?? "",
      };
    }).toList();
  }
}

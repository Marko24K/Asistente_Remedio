import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Getter público para usar Firestore fuera
  FirebaseFirestore get db => _db;

  Future<String> generarCodigo() async {
    final random = Random();
    return "AM-${100000 + random.nextInt(899999)}";
  }

  Future<String> crearPaciente(String nombre) async {
    String code = await generarCodigo();

    await _db.collection("pacientes").doc(code).set({
      "nombre": nombre,
      "codigo": code,
      "puntos": 0,
      "createdAt": DateTime.now(),
    });

    return code;
  }

  /// Devuelve lista de recordatorios del paciente (cada map incluye 'id' con el docId)
  Future<List<Map<String, dynamic>>> getRemindersForPatient(
    String patientCode,
  ) async {
    final snapshot = await _db
        .collection('patients')
        .doc(patientCode)
        .collection('reminders')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      // incluye el id del documento para referencia remota
      return {
        'id': doc.id,
        'medication':
            data['medication'] ??
            data['medicationName'] ??
            data['medicamento'] ??
            '',
        'time': data['time'] ?? data['hora'] ?? '',
        'frequency': data['frequency'] ?? data['frecuencia'] ?? '',
        'startDate': data['startDate'] ?? data['fechaInicio'] ?? '',
        'endDate': data['endDate'] ?? data['fechaFin'] ?? '',
        'status': data['status'] ?? 'active',
        'notes': data['notes'] ?? data['note'] ?? '',
      };
    }).toList();
  }

  Future<void> crearRecordatorio(
    String codigoPaciente,
    String medicamento,
    String hora,
  ) async {
    await _db
        .collection("pacientes")
        .doc(codigoPaciente)
        .collection("recordatorios")
        .add({
          "medicamento": medicamento,
          "hora": hora,
          "confirmado": false,
          "createdAt": DateTime.now(),
        });
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

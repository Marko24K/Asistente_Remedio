import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;

  // -------------------- INIT --------------------
  static Future<void> initDB() async {
    if (_db != null) return;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'asistente_remedios.db');

    _db = await openDatabase(
      path,
      version: 2, // aumenta versión si cambias estructura
      onCreate: (db, _) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldV, newV) async {
        await _createTables(db);
      },
    );
  }

  static Future<void> _createTables(Database db) async {
    // Pacientes
    await db.execute('''
      CREATE TABLE IF NOT EXISTS patients (
        code TEXT PRIMARY KEY,
        name TEXT,
        points INTEGER,
        totalPoints INTEGER
      );
    ''');

    // Medicamentos (solo nombre)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS medicamentos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT
      );
    ''');

    // Recordatorios
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patientCode TEXT,
        medId INTEGER,
        dose TEXT,
        type TEXT,
        hour TEXT,
        notes TEXT,
        duration INTEGER,
        frequencyHours INTEGER,
        startDate TEXT,
        endDate TEXT,
        nextTrigger TEXT
      );
    ''');
  }

  static Future<Database> get database async {
    if (_db != null) return _db!;
    await initDB();
    return _db!;
  }

  // -------------------- PACIENTES --------------------
  static Future<void> insertOrUpdatePatientLocal(
    Map<String, dynamic> data,
  ) async {
    final db = await database;
    await db.insert(
      "patients",
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<Map<String, dynamic>?> getPatient(String code) async {
    final db = await database;
    final res = await db.query(
      "patients",
      where: "code = ?",
      whereArgs: [code],
    );
    return res.isNotEmpty ? res.first : null;
  }

  static Future<int> getPoints(String code) async {
    final p = await getPatient(code);
    return p?["points"] ?? 0;
  }

  static Future<void> addPoints(int value, String code) async {
    final db = await database;
    final p = await getPatient(code);
    int current = p?["points"] ?? 0;
    int total = p?["totalPoints"] ?? 0;

    int updated = current + value;
    if (updated < 0) updated = 0;

    if (value > 0) {
      total += value; // solo sumamos al total cuando gana puntos
    }

    await db.update(
      "patients",
      {"points": updated, "totalPoints": total},
      where: "code = ?",
      whereArgs: [code],
    );
  }

  // -------------------- MEDICAMENTOS --------------------
  static Future<String?> getMedicamentoNombre(int id) async {
    final db = await database;
    final res = await db.query(
      "medicamentos",
      where: "id = ?",
      whereArgs: [id],
    );
    return res.isNotEmpty ? res.first["nombre"] as String : null;
  }

  // Insert masivo cuando cargues el JSON
  static Future<void> insertMedicamento(String nombre) async {
    final db = await database;
    await db.insert("medicamentos", {"nombre": nombre});
  }

  // -------------------- RECORDATORIOS --------------------
  static Future<void> insertReminder(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert("reminders", data);
  }

  static Future<List<Map<String, dynamic>>> getReminders(String code) async {
    final db = await database;

    final res = await db.query(
      "reminders",
      where: "patientCode = ?",
      whereArgs: [code],
      orderBy: "hour ASC",
    );

    // Resolver nombre del medicamento por medId
    List<Map<String, dynamic>> finalList = [];

    for (var r in res) {
      int? medId = r["medId"] as int?;

      String? nombre = medId != null ? await getMedicamentoNombre(medId) : null;

      finalList.add({...r, "medication": nombre ?? "Medicamento"});
    }

    return finalList;
  }
}

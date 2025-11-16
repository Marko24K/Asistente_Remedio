import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }

  static Future<void> insertOrUpdatePatientLocal(Map<String, dynamic> p) async {
    final database = await DBHelper.db;
    await database.insert('pacientes_local', {
      'code': p['code'] ?? p['codigo'] ?? '',
      'name': p['name'] ?? p['nombre'] ?? '',
      'points': p.containsKey('points') ? (p['points'] ?? 0) : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Obtiene recordatorios activos para un paciente (usa codigo_acceso en tabla pacientes)
  static Future<List<Map<String, dynamic>>> getActiveRemindersForPatient(
    String patientCode,
  ) async {
    final database = await DBHelper.db;

    // Buscar paciente por codigo_acceso (o codigo)
    final pacienteRows = await database.query(
      'pacientes',
      where: 'codigo_acceso = ? OR codigo = ?',
      whereArgs: [patientCode, patientCode],
      limit: 1,
    );

    if (pacienteRows.isEmpty) return [];

    final pacienteId = pacienteRows.first['id'] as int;

    // Si tienes tabla recordatorios_local, preferirla; sino usar recordatorios JOIN medicamentos
    // Intentamos primero recordatorios_local
    try {
      final localRows = await database.query(
        'recordatorios_local',
        where: 'patient_code = ? AND status = ?',
        whereArgs: [patientCode, 'active'],
        orderBy: 'time ASC',
      );

      if (localRows.isNotEmpty) {
        // Normalizar estructura esperada por UI
        return localRows.map((r) {
          return {
            'id': r['id'],
            'remote_id': r['remote_id'],
            'name': r['medication'] ?? '',
            'dose': r['dose'] ?? '',
            'type': r['type'] ?? 'Pastilla',
            'time': r['time'] ?? '',
            'notes': r['notes'] ?? '',
            'status': r['status'] ?? 'active',
            'patient_code': r['patient_code'],
          };
        }).toList();
      }
    } catch (e) {
      // si la tabla no existe o falla, continuamos al query por defecto
    }

    // Si no existe recordatorios_local o está vacío, usamos recordatorios (relacionado a medicamentos)
    final rows = await database.rawQuery(
      """
      SELECT r.id, r.hora as time, r.dosis as dose, r.frecuencia as frequency,
             m.nombre AS medication
      FROM recordatorios r
      LEFT JOIN medicamentos m ON m.id = r.medicamento_id
      WHERE r.paciente_id = ? AND (r.fecha_fin IS NULL OR r.fecha_fin = '' OR r.fecha_fin >= date('now'))
      ORDER BY r.hora ASC
    """,
      [pacienteId],
    );

    return rows.map((row) {
      return {
        'id': row['id'],
        'remote_id': null,
        'name': row['medication'] ?? '',
        'dose': row['dose'] ?? '',
        'type': 'Medicamento',
        'time': row['time'] ?? '',
        'notes': '',
        'status': 'active',
        'patient_code': patientCode,
      };
    }).toList();
  }

  /// Inserta un registro de feedback (respuesta semanal) y actualiza puntos totales
  static Future<void> insertFeedback(
    String patientCode,
    String fecha,
    String respuesta,
    int puntos,
  ) async {
    final database = await DBHelper.db;

    // 1) Obtener paciente id
    final pacienteRows = await database.query(
      'pacientes',
      where: 'codigo_acceso = ? OR codigo = ?',
      whereArgs: [patientCode, patientCode],
      limit: 1,
    );

    if (pacienteRows.isEmpty) {
      // Si no existe paciente, no hacemos nada
      return;
    }

    final pacienteId = pacienteRows.first['id'] as int;

    // 2) Insertar en feedback_semana (tabla existente en tu esquema)
    await database.insert('feedback_semana', {
      'paciente_id': pacienteId,
      'fecha': fecha,
      'respuesta': respuesta,
      'puntos': puntos,
      'synced': 0,
    });

    // 3) Actualizar/insertar puntos_totales
    final ptRows = await database.query(
      'puntos_totales',
      where: 'paciente_id = ?',
      whereArgs: [pacienteId],
      limit: 1,
    );

    if (ptRows.isEmpty) {
      await database.insert('puntos_totales', {
        'paciente_id': pacienteId,
        'total_puntos': puntos,
        'ultimo_update': DateTime.now().toIso8601String(),
        'synced': 0,
      });
    } else {
      await database.rawUpdate(
        'UPDATE puntos_totales SET total_puntos = total_puntos + ?, ultimo_update = ? WHERE paciente_id = ?',
        [puntos, DateTime.now().toIso8601String(), pacienteId],
      );
    }
  }

  /// Obtiene puntos actuales del paciente (puntos_totales). Devuelve 0 si no hay registro.
  static Future<int> getPoints(String patientCode) async {
    final database = await DBHelper.db;

    final pacienteRows = await database.query(
      'pacientes',
      where: 'codigo_acceso = ? OR codigo = ?',
      whereArgs: [patientCode, patientCode],
      limit: 1,
    );

    if (pacienteRows.isEmpty) return 0;

    final pacienteId = pacienteRows.first['id'] as int;

    final ptRows = await database.query(
      'puntos_totales',
      where: 'paciente_id = ?',
      whereArgs: [pacienteId],
      limit: 1,
    );

    if (ptRows.isEmpty) return 0;
    return (ptRows.first['total_puntos'] ?? 0) as int;
  }

  static Future<void> insertOrUpdateReminderLocal(
    Map<String, dynamic> r,
    String pacienteCode,
  ) async {
    final database = await DBHelper.db;

    // 1️⃣ Obtener ID de paciente local
    final paciente = await database.query(
      'pacientes',
      where: 'codigo_acceso = ?',
      whereArgs: [pacienteCode],
      limit: 1,
    );

    if (paciente.isEmpty) return;

    final pacienteId = paciente.first['id'];

    // 2️⃣ Obtener o crear medicamento
    final medName = r['medication'] ?? '';
    var med = await database.query(
      'medicamentos',
      where: 'nombre = ?',
      whereArgs: [medName],
      limit: 1,
    );

    int medicamentoId;

    if (med.isEmpty) {
      medicamentoId = await database.insert('medicamentos', {
        'nombre': medName,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    } else {
      medicamentoId = med.first['id'] as int;
    }

    // 3️⃣ Insertar recordatorio local
    await database.insert('recordatorios', {
      'paciente_id': pacienteId,
      'medicamento_id': medicamentoId,
      'hora': r['time'] ?? '',
      'frecuencia': r['frequency'] ?? '',
      'fecha_inicio': r['startDate'] ?? '',
      'fecha_fin': r['endDate'] ?? '',
      'synced': 1,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getReminders({
    int? pacienteId,
  }) async {
    final database = await DBHelper.db;

    final List<Map<String, dynamic>> result = await database.rawQuery("""
      SELECT r.id, r.dosis, r.frecuencia, r.hora, r.fecha_inicio, r.fecha_fin,
             m.nombre AS medicamento
      FROM recordatorios r
      JOIN medicamentos m ON m.id = r.medicamento_id
      ${pacienteId != null ? "WHERE r.paciente_id = ?" : ""}
      ORDER BY r.hora ASC
    """, pacienteId != null ? [pacienteId] : []);

    return result.map((row) {
      return {
        'id': row['id'],
        'name': row['medicamento'],
        'dose': row['dosis'] ?? "",
        'type': "Medicamento", // UI necesita algo
        'next': row['hora'],
        'status': 'pending', // temporal hasta marcar confirmación
      };
    }).toList();
  }

  static Future<Database> initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'asistente_remedios.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute("""
          CREATE TABLE cuidadores (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            telefono TEXT,
            email TEXT UNIQUE,
            codigo_vinculacion TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
          );
        """);

        await db.execute("""
          CREATE TABLE pacientes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            edad INTEGER,
            diagnostico TEXT,
            codigo_acceso TEXT UNIQUE NOT NULL,
            cuidador_id INTEGER,
            synced INTEGER DEFAULT 0,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY(cuidador_id) REFERENCES cuidadores(id)
          );
        """);

        await db.execute("""
          CREATE TABLE medicamentos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL
          );
        """);

        await db.execute("""
          CREATE TABLE recordatorios (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            paciente_id INTEGER NOT NULL,
            medicamento_id INTEGER NOT NULL,
            dosis TEXT,
            frecuencia TEXT,
            hora TEXT,
            fecha_inicio TEXT,
            fecha_fin TEXT,
            synced INTEGER DEFAULT 0,
            FOREIGN KEY(paciente_id) REFERENCES pacientes(id),
            FOREIGN KEY(medicamento_id) REFERENCES medicamentos(id)
          );
        """);

        await db.execute("""
          CREATE TABLE feedback_semana (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            paciente_id INTEGER NOT NULL,
            fecha TEXT NOT NULL,
            respuesta TEXT NOT NULL,
            puntos INTEGER NOT NULL,
            synced INTEGER DEFAULT 0,
            FOREIGN KEY(paciente_id) REFERENCES pacientes(id)
          );
        """);

        await db.execute("""
          CREATE TABLE puntos_totales (
            paciente_id INTEGER PRIMARY KEY,
            total_puntos INTEGER DEFAULT 0,
            ultimo_update TEXT DEFAULT CURRENT_TIMESTAMP,
            synced INTEGER DEFAULT 0,
            FOREIGN KEY(paciente_id) REFERENCES pacientes(id)
          );
        """);
      },
    );
  }
}

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
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

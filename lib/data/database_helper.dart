import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;

  static Database? _database;
  DBHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String dbPath = await getDatabasesPath();
    String path = join(dbPath, 'asistente_remedios.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE usuario (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        tipo TEXT CHECK(tipo IN ('adulto_mayor','administrador')) NOT NULL,
        edad INTEGER,
        telefono TEXT,
        correo TEXT,
        configuracion_tema TEXT DEFAULT 'claro',
        tamano_texto INTEGER DEFAULT 1,
        sincronizado INTEGER DEFAULT 0
      );

      CREATE TABLE medicamentos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        categoria TEXT,
        descripcion TEXT
      );

      CREATE TABLE recordatorios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL,
        medicamento_id INTEGER NOT NULL,
        creado_por INTEGER,
        dosis TEXT,
        hora TEXT,
        frecuencia INTEGER,
        activo INTEGER DEFAULT 1,
        notas TEXT,
        FOREIGN KEY (usuario_id) REFERENCES usuario(id),
        FOREIGN KEY (medicamento_id) REFERENCES medicamentos(id),
        FOREIGN KEY (creado_por) REFERENCES usuario(id)
      );

      CREATE TABLE adherencia (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recordatorio_id INTEGER NOT NULL,
        fecha TEXT NOT NULL,
        hora_confirmacion TEXT,
        tomado INTEGER DEFAULT 0,
        puntos_ganados INTEGER DEFAULT 0,
        confirmado_por INTEGER,
        FOREIGN KEY (recordatorio_id) REFERENCES recordatorios(id),
        FOREIGN KEY (confirmado_por) REFERENCES usuario(id)
      );

      CREATE TABLE trivias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pregunta TEXT NOT NULL,
        opcion_a TEXT,
        opcion_b TEXT,
        opcion_c TEXT,
        respuesta_correcta INTEGER,
        explicacion TEXT
      );

      CREATE TABLE trivias_resueltas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trivia_id INTEGER NOT NULL,
        usuario_id INTEGER NOT NULL,
        respondida_por INTEGER,
        fecha TEXT,
        correcta INTEGER,
        puntos_ganados INTEGER DEFAULT 0,
        FOREIGN KEY (trivia_id) REFERENCES trivias(id),
        FOREIGN KEY (usuario_id) REFERENCES usuario(id),
        FOREIGN KEY (respondida_por) REFERENCES usuario(id)
      );

      CREATE TABLE puntos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL,
        total INTEGER DEFAULT 0,
        ultima_actualizacion TEXT,
        FOREIGN KEY (usuario_id) REFERENCES usuario(id)
      );

      CREATE TABLE retroalimentacion (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL,
        semana TEXT,
        adherencia_promedio REAL,
        trivias_correctas INTEGER,
        puntos_obtenidos INTEGER,
        comentario TEXT,
        FOREIGN KEY (usuario_id) REFERENCES usuario(id)
      );
    ''');
  }
}

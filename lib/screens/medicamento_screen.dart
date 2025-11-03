import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class MedicamentoScreen extends StatefulWidget {
  const MedicamentoScreen({super.key});

  @override
  State<MedicamentoScreen> createState() => _MedicamentoScreenState();
}

class _MedicamentoScreenState extends State<MedicamentoScreen> {
  late Database _database;
  List<Map<String, dynamic>> _medicamentos = [];
  List<Map<String, dynamic>> _filtrados = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _abrirBaseDatos();
  }

  Future<void> _abrirBaseDatos() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'asistente_remedios.db');
    _database = await openDatabase(path);
    final data = await _database.query('medicamentos', orderBy: 'nombre');
    setState(() {
      _medicamentos = data;
      _filtrados = data;
      _cargando = false;
    });
  }

  void _filtrar(String query) {
    setState(() {
      _filtrados = _medicamentos
          .where(
            (m) => m['nombre'].toString().toLowerCase().contains(
              query.toLowerCase(),
            ),
          )
          .toList();
    });
  }

  void _seleccionarMedicamento(Map<String, dynamic> med) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Seleccionaste ${med['nombre']}. Aquí podrías agregar un recordatorio.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
    // Aquí podrías navegar a una pantalla de creación de recordatorios:
    // Navigator.push(context, MaterialPageRoute(builder: (_) => CrearRecordatorioScreen(med: med)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Medicamento'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _abrirBaseDatos,
            tooltip: 'Actualizar lista',
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    onChanged: _filtrar,
                    decoration: const InputDecoration(
                      hintText: 'Buscar medicamento...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Expanded(
                  child: _filtrados.isEmpty
                      ? const Center(
                          child: Text(
                            'No se encontraron medicamentos',
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filtrados.length,
                          itemBuilder: (context, index) {
                            final med = _filtrados[index];
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              child: ListTile(
                                title: Text(med['nombre']),
                                leading: const Icon(
                                  Icons.medication_outlined,
                                  color: Colors.teal,
                                ),
                                trailing: const Icon(Icons.add_circle_outline),
                                onTap: () => _seleccionarMedicamento(med),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

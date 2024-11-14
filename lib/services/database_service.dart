import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    return openDatabase(
      join(await getDatabasesPath(), 'app_database.db'),
      onCreate: (db, version) async {
        await db.execute(
          "CREATE TABLE diaryEntries(id INTEGER PRIMARY KEY AUTOINCREMENT, rating INTEGER, details TEXT, date TEXT)",
        );
        await db.execute(
          "CREATE TABLE settings(id INTEGER PRIMARY KEY, selectedChartType TEXT)",
        );
      },
      version: 1,
    );
  }

  // Método para obter todas as entradas do diário
  Future<List<Map<String, dynamic>>> getDiaryEntries() async {
    final db = await database;
    return await db.query('diaryEntries', orderBy: "date DESC");
  }

  // Método para inserir uma nova entrada no diário
  Future<void> insertDiaryEntry(Map<String, dynamic> entry) async {
    final db = await database;
    await db.insert(
      'diaryEntries',
      entry,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Método para deletar uma entrada do diário com base no ID
  Future<void> deleteDiaryEntry(int id) async {
    final db = await database;
    await db.delete(
      'diaryEntries',
      where: "id = ?",
      whereArgs: [id],
    );
  }

  // Métodos de tipo de gráfico, já adicionados anteriormente
  Future<String?> getSelectedChartType() async {
    final db = await database;
    final result = await db.query('settings', limit: 1);
    if (result.isNotEmpty) {
      return result.first['selectedChartType'] as String?;
    }
    return null;
  }

  Future<void> saveSelectedChartType(String chartType) async {
    final db = await database;
    await db.insert(
      'settings',
      {'id': 1, 'selectedChartType': chartType},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

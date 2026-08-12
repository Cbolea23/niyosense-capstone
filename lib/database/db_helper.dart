import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/grading_log.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('niyosense_local.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE grading_logs (
        uuid TEXT PRIMARY KEY,
        user_id INTEGER NOT NULL,
        image_path TEXT NOT NULL,
        audio_path TEXT NOT NULL,
        visual_pred TEXT NOT NULL,
        audio_pred TEXT NOT NULL,
        final_stage TEXT NOT NULL,
        confidence REAL NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertScan(GradingLog log) async {
    final db = await instance.database;
    return await db.insert('grading_logs', log.toMap());
  }

  Future<List<GradingLog>> getUnsyncedLogs() async {
    final db = await instance.database;
    final result = await db.query(
      'grading_logs',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
    return result.map((json) => GradingLog.fromMap(json)).toList();
  }

  Future<int> markAsSynced(String uuid) async {
    final db = await instance.database;
    return await db.update(
      'grading_logs',
      {'is_synced': 1},
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
  }
}
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/grading_log.dart';
import '../models/batch_session.dart';

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
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
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
        created_at TEXT NOT NULL,
        batch_id TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE batch_sessions (
        batch_id TEXT PRIMARY KEY,
        farmer_name TEXT NOT NULL,
        mature_price REAL NOT NULL DEFAULT 12.0,
        premature_price REAL NOT NULL DEFAULT 7.0,
        reject_price REAL NOT NULL DEFAULT 0.0,
        created_at TEXT NOT NULL,
        is_closed INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE grading_logs ADD COLUMN batch_id TEXT');
      } catch (_) {}
      await db.execute('''
        CREATE TABLE IF NOT EXISTS batch_sessions (
          batch_id TEXT PRIMARY KEY,
          farmer_name TEXT NOT NULL,
          mature_price REAL NOT NULL DEFAULT 12.0,
          premature_price REAL NOT NULL DEFAULT 7.0,
          reject_price REAL NOT NULL DEFAULT 0.0,
          created_at TEXT NOT NULL,
          is_closed INTEGER NOT NULL DEFAULT 0
        )
      ''');
    }
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

  // --- Batch Session Methods ---

  Future<int> createBatchSession(BatchSession session) async {
    final db = await instance.database;
    return await db.insert(
      'batch_sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<BatchSession?> getActiveBatchSession() async {
    final db = await instance.database;
    final result = await db.query(
      'batch_sessions',
      where: 'is_closed = ?',
      whereArgs: [0],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (result.isNotEmpty) {
      return BatchSession.fromMap(result.first);
    }
    return null;
  }

  Future<List<BatchSession>> getAllBatchSessions() async {
    final db = await instance.database;
    final result = await db.query(
      'batch_sessions',
      orderBy: 'created_at DESC',
    );
    return result.map((json) => BatchSession.fromMap(json)).toList();
  }

  Future<int> closeBatchSession(String batchId) async {
    final db = await instance.database;
    return await db.update(
      'batch_sessions',
      {'is_closed': 1},
      where: 'batch_id = ?',
      whereArgs: [batchId],
    );
  }

  Future<BatchSummary> getBatchSummary(BatchSession session) async {
    final db = await instance.database;
    final logs = await db.query(
      'grading_logs',
      where: 'batch_id = ?',
      whereArgs: [session.batchId],
    );

    int matureCount = 0;
    int prematureCount = 0;
    int rejectCount = 0;

    for (var log in logs) {
      final stage = (log['final_stage'] as String? ?? '').toUpperCase();
      if (stage.contains('MATURE') && !stage.contains('PREMATURE')) {
        matureCount++;
      } else if (stage.contains('PREMATURE') || stage.contains('MALAUHOG')) {
        prematureCount++;
      } else {
        rejectCount++;
      }
    }

    final int total = logs.length;
    final double payout = (matureCount * session.maturePrice) +
        (prematureCount * session.prematurePrice) +
        (rejectCount * session.rejectPrice);

    return BatchSummary(
      session: session,
      totalScans: total,
      matureCount: matureCount,
      prematureCount: prematureCount,
      rejectCount: rejectCount,
      totalPayout: payout,
    );
  }
}
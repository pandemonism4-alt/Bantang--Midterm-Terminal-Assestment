import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task_model.dart';

/// Singleton SQLite database helper.
/// Manages the local 'tasks' table for offline-first storage.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  static const String _dbName = 'strm_local.db';
  static const int _dbVersion = 1;
  static const String _tableTasks = 'tasks';

  /// Returns the singleton [Database], opening it if needed.
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableTasks (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        title       TEXT    NOT NULL,
        description TEXT    NOT NULL,
        priority    TEXT    NOT NULL DEFAULT 'medium',
        synced      INTEGER NOT NULL DEFAULT 0,
        userId      TEXT    NOT NULL,
        createdAt   TEXT    NOT NULL,
        firestoreId TEXT
      )
    ''');
  }

  // ─── INSERT ──────────────────────────────────────────────────────────────

  /// Inserts a new task and returns its generated [id].
  Future<int> insertTask(TaskModel task) async {
    try {
      final db = await database;
      return await db.insert(
        _tableTasks,
        task.toSqliteMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw Exception('Failed to save task locally: $e');
    }
  }

  // ─── QUERY ───────────────────────────────────────────────────────────────

  /// Returns all tasks for [userId], newest first.
  Future<List<TaskModel>> getTasksByUser(String userId) async {
    try {
      final db = await database;
      final maps = await db.query(
        _tableTasks,
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'createdAt DESC',
      );
      return maps.map(TaskModel.fromSqliteMap).toList();
    } catch (e) {
      throw Exception('Failed to load local tasks: $e');
    }
  }

  /// Returns only unsynced tasks (synced = 0) for [userId].
  Future<List<TaskModel>> getUnsyncedTasks(String userId) async {
    try {
      final db = await database;
      final maps = await db.query(
        _tableTasks,
        where: 'userId = ? AND synced = 0',
        whereArgs: [userId],
      );
      return maps.map(TaskModel.fromSqliteMap).toList();
    } catch (e) {
      throw Exception('Failed to load unsynced tasks: $e');
    }
  }

  // ─── UPDATE ──────────────────────────────────────────────────────────────

  /// Marks a task as synced and stores the Firestore document ID.
  Future<void> markAsSynced(int localId, String firestoreId) async {
    try {
      final db = await database;
      await db.update(
        _tableTasks,
        {'synced': 1, 'firestoreId': firestoreId},
        where: 'id = ?',
        whereArgs: [localId],
      );
    } catch (e) {
      throw Exception('Failed to mark task as synced: $e');
    }
  }

  // ─── DELETE ──────────────────────────────────────────────────────────────

  /// Deletes a task by its local [id].
  Future<void> deleteTask(int id) async {
    try {
      final db = await database;
      await db.delete(_tableTasks, where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  /// Closes the database connection. Call on app dispose.
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
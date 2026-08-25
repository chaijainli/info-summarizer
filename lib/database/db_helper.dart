import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/record_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _database;

  DatabaseHelper._();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'info_summarizer.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            summary TEXT,
            category TEXT DEFAULT '其他',
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE custom_categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL,
            keywords TEXT NOT NULL DEFAULT ''
          )
        ''');
      },
    );
  }

  Future<int> insertRecord(InfoRecord record) async {
    final db = await database;
    return await db.insert('records', record.toMap());
  }

  Future<List<InfoRecord>> getAllRecords() async {
    final db = await database;
    final maps = await db.query('records', orderBy: 'created_at DESC');
    return maps.map((map) => InfoRecord.fromMap(map)).toList();
  }

  Future<InfoRecord?> getRecordById(int id) async {
    final db = await database;
    final maps = await db.query('records', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return InfoRecord.fromMap(maps.first);
    }
    return null;
  }

  Future<List<InfoRecord>> getRecordsByCategory(String category) async {
    final db = await database;
    final maps = await db.query(
      'records',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => InfoRecord.fromMap(map)).toList();
  }

  Future<List<InfoRecord>> searchRecords(String keyword) async {
    final db = await database;
    final maps = await db.query(
      'records',
      where: 'title LIKE ? OR content LIKE ? OR summary LIKE ?',
      whereArgs: ['%$keyword%', '%$keyword%', '%$keyword%'],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => InfoRecord.fromMap(map)).toList();
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await database;
    return await db.rawQuery(
      'SELECT category, COUNT(*) as count FROM records GROUP BY category ORDER BY count DESC'
    );
  }

  Future<void> deleteRecord(int id) async {
    final db = await database;
    await db.delete('records', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> addCustomCategory(String name, String keywords) async {
    final db = await database;
    await db.insert(
      'custom_categories',
      {'name': name, 'keywords': keywords},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getCustomCategories() async {
    final db = await database;
    return await db.query('custom_categories');
  }
}
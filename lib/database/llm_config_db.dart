import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/llm_config_model.dart';

class LlmConfigDb {
  static final LlmConfigDb instance = LlmConfigDb._();
  static Database? _database;

  LlmConfigDb._();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'llm_config.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE llm_config (
            id INTEGER PRIMARY KEY,
            provider TEXT NOT NULL DEFAULT 'openai',
            base_url TEXT NOT NULL,
            api_key TEXT NOT NULL,
            model_name TEXT NOT NULL,
            temperature REAL NOT NULL DEFAULT 0.3,
            max_tokens INTEGER NOT NULL DEFAULT 200,
            enabled INTEGER NOT NULL DEFAULT 0,
            system_prompt TEXT
          )
        ''');
      },
    );
  }

  Future<void> saveConfig(LlmConfig config) async {
    final db = await database;
    await db.delete('llm_config');
    await db.insert('llm_config', config.toMap());
  }

  Future<LlmConfig> getConfig() async {
    final db = await database;
    final maps = await db.query('llm_config');
    if (maps.isNotEmpty) {
      return LlmConfig.fromMap(maps.first);
    }
    return LlmConfig.empty();
  }

  Future<bool> isEnabled() async {
    final config = await getConfig();
    return config.enabled;
  }
}
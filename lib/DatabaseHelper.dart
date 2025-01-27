import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'search.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE recent_searches (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            query TEXT UNIQUE
          )
        ''');
      },
    );
  }

  Future<void> insertSearch(String query) async {
    final db = await database;
    await db.insert(
      'recent_searches',
      {'query': query.toLowerCase()}, // Store queries in lowercase to handle case insensitivity
      conflictAlgorithm: ConflictAlgorithm.ignore, // Avoid duplication
    );
  }

  Future<List<String>> getRecentSearches() async {
    final db = await database;
    final result = await db.query(
      'recent_searches',
      columns: ['query'],
      orderBy: 'id DESC', // Fetch in reverse order of insertion
    );
    return result.map((row) => row['query'] as String).toList();
  }
}

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/artist.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'artist.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE artists(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            username TEXT NOT NULL,
            image TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertArtist(Artist artist) async {
    final db = await database;
    await db.insert(
      'artists',
      artist.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Artist>> getArtists() async {
    final db = await database;
    final result = await db.query('artists');
    return result.map((map) => Artist.fromMap(map)).toList();
  }

  Future<void> updateArtist(Artist artist) async {
    final db = await database;
    await db.update(
      'artists',
      {
        'name': artist.name,
        'username': artist.username,
        'image': artist.image,
      },
      where: 'id = ?',
      whereArgs: [artist.id],
    );
  }

  Future<void> deleteArtist(int id) async {
    final db = await database;
    await db.delete(
      'artists',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

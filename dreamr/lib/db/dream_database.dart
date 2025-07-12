import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class Dream {
  final int id;
  final String title;
  final String text;
  final String? imagePath;
  final String createdAt;
  final bool imagePending;

  Dream({
    required this.id,
    required this.title,
    required this.text,
    this.imagePath,
    required this.createdAt,
    required this.imagePending,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'text': text,
      'image_path': imagePath,
      'created_at': createdAt,
      'image_pending': imagePending ? 1 : 0,
    };
  }

  static Dream fromMap(Map<String, dynamic> map) {
    return Dream(
      id: map['id'],
      title: map['title'],
      text: map['text'],
      imagePath: map['image_path'],
      createdAt: map['created_at'],
      imagePending: map['image_pending'] == 1,
    );
  }
}

class DreamDatabase {
  static final DreamDatabase _instance = DreamDatabase._internal();
  factory DreamDatabase() => _instance;
  DreamDatabase._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    return await _initDb();
  }

  Future<Database> _initDb() async {
    Directory docsDir = await getApplicationDocumentsDirectory();
    String path = join(docsDir.path, 'dreams.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE dreams (
        id INTEGER PRIMARY KEY,
        title TEXT,
        text TEXT,
        image_path TEXT,
        created_at TEXT,
        image_pending INTEGER
      )
    ''');
  }

  Future<void> insertOrUpdateDream(Dream dream) async {
    final db = await database;
    await db.insert(
      'dreams',
      dream.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Dream>> getAllDreams() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('dreams', orderBy: 'created_at DESC');
    return maps.map((map) => Dream.fromMap(map)).toList();
  }

  Future<List<Dream>> getDreamsWithMissingImages() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('dreams', where: 'image_pending = ?', whereArgs: [1]);
    return maps.map((map) => Dream.fromMap(map)).toList();
  }

  Future<void> updateDreamImagePath(int id, String imagePath) async {
    final db = await database;
    await db.update(
      'dreams',
      {'image_path': imagePath, 'image_pending': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

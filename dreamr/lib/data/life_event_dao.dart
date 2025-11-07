// data/life_event_dao.dart
import 'dart:async';
import 'package:dreamr/models/life_event.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class LifeEventDao {
  static final LifeEventDao _instance = LifeEventDao._internal();
  factory LifeEventDao() => _instance;
  LifeEventDao._internal();

  Database? _db;

  Future<Database> _open() async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'dreamr.db');
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS life_events (
            id INTEGER PRIMARY KEY,
            user_id INTEGER NOT NULL,
            occurred_at TEXT NOT NULL,
            title TEXT NOT NULL,
            details TEXT,
            tags TEXT,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_life_events_occurred_at ON life_events(occurred_at DESC)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_life_events_user_id ON life_events(user_id)');
      },
      onOpen: (db) async {
        // Make sure the table exists even if we're opening an existing database
        await db.execute('''
          CREATE TABLE IF NOT EXISTS life_events (
            id INTEGER PRIMARY KEY,
            user_id INTEGER NOT NULL,
            occurred_at TEXT NOT NULL,
            title TEXT NOT NULL,
            details TEXT,
            tags TEXT,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  Map<String, Object?> _toMap(LifeEvent event) => {
    'id': event.id,
    'user_id': event.userId,
    'occurred_at': event.occurredAt.toIso8601String(),
    'title': event.title,
    'details': event.details,
    'tags': event.tags?.join(','),
    'created_at': event.createdAt.toIso8601String(),
  };

  LifeEvent _fromMap(Map<String, Object?> m) {
    List<String>? parseTags(String? tags) {
      if (tags == null || tags.isEmpty) return null;
      return tags.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }

    return LifeEvent(
      id: (m['id'] as num).toInt(),
      userId: (m['user_id'] as num?)?.toInt() ?? 0,
      occurredAt: DateTime.parse((m['occurred_at'] as String)),
      title: (m['title'] as String?) ?? '',
      details: m['details'] as String?,
      tags: parseTags(m['tags'] as String?),
      createdAt: DateTime.parse((m['created_at'] as String)),
    );
  }

  Future<void> upsertMany(List<LifeEvent> events) async {
    final db = await _open();
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final event in events) {
        batch.insert(
          'life_events',
          _toMap(event),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> upsert(LifeEvent event) async {
    final db = await _open();
    await db.insert(
      'life_events',
      _toMap(event),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<LifeEvent>> getAll() async {
    final db = await _open();
    final rows = await db.query(
      'life_events',
      orderBy: 'occurred_at DESC', // Show most recent events first
    );
    return rows.map(_fromMap).toList();
  }

  Future<void> delete(int id) async {
    final db = await _open();
    await db.delete(
      'life_events',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<LifeEvent?> getById(int id) async {
    final db = await _open();
    final rows = await db.query(
      'life_events',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (rows.isEmpty) return null;
    return _fromMap(rows.first);
  }
}
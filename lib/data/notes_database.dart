import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/note.dart';

class NotesDatabase {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'notes.db');
    return await openDatabase(
      path,
      version: 5,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            remoteKey TEXT,
            userId TEXT,
            title TEXT,
            content TEXT,
            createdAt TEXT,
            updatedAt TEXT
          )
        ''');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_notes_userId ON notes(userId);');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_notes_remoteKey ON notes(remoteKey);');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE notes ADD COLUMN userId TEXT;');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE notes ADD COLUMN remoteId INTEGER;');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_notes_remoteId ON notes(remoteId);');
        }
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE notes ADD COLUMN remoteKey TEXT;');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_notes_remoteKey ON notes(remoteKey);');
        }
        if (oldVersion < 5) {
        }
      },
    );
  }

  static Future<int> insertNote(Note note) async {
    final db = await database;
    return await db.insert('notes', note.toJson());
  }

  static Future<List<Note>> getNotesForUser(String userId) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT n.* FROM notes n
      WHERE n.userId = ?
        AND NOT EXISTS (
          SELECT 1 FROM notes m
          WHERE m.userId = n.userId
            AND m.title = n.title
            AND m.content = n.content
            AND m.createdAt = n.createdAt
            AND m.remoteKey IS NOT NULL
            AND n.remoteKey IS NULL
        )
      ORDER BY n.createdAt DESC
    ''', [userId]);
    return maps.map((json) => Note.fromJson(json)).toList();
  }

  static Future<int> updateNote(Note note) async {
    final db = await database;
    return await db.update('notes', note.toJson(), where: 'id = ?', whereArgs: [note.id]);
  }

  static Future<int> deleteNote(int id) async {
    final db = await database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }


  static Future<Note?> getByRemoteKey(String remoteKey) async {
    final db = await database;
    final maps = await db.query('notes', where: 'remoteKey = ?', whereArgs: [remoteKey], limit: 1);
    if (maps.isEmpty) return null;
    return maps.map((e) => Note.fromJson(e)).first;
  }

  static Future<void> upsertFromFirestore(Note remoteNote) async {
    final existing = remoteNote.remoteKey != null ? await getByRemoteKey(remoteNote.remoteKey!) : null;
    if (existing != null) {
      final updated = Note(
        id: existing.id,
        remoteKey: remoteNote.remoteKey,
        userId: remoteNote.userId,
        title: remoteNote.title,
        content: remoteNote.content,
        createdAt: remoteNote.createdAt,
        updatedAt: remoteNote.updatedAt,
      );
      await updateNote(updated);
      return;
    }

    final db = await database;
    final candidates = await db.query(
      'notes',
      where:
          'userId = ? AND remoteKey IS NULL AND title = ? AND content = ? AND createdAt = ?',
      whereArgs: [
        remoteNote.userId,
        remoteNote.title,
        remoteNote.content,
        remoteNote.createdAt.toIso8601String(),
      ],
      limit: 1,
    );
    if (candidates.isNotEmpty) {
      final local = Note.fromJson(candidates.first);
      final merged = Note(
        id: local.id,
        remoteKey: remoteNote.remoteKey,
        userId: remoteNote.userId,
        title: remoteNote.title,
        content: remoteNote.content,
        createdAt: remoteNote.createdAt,
        updatedAt: remoteNote.updatedAt,
      );
      await updateNote(merged);
    } else {
      await insertNote(remoteNote);
    }
  }
}

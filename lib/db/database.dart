import 'dart:async';
import 'package:flutter/material.dart';
import 'package:notysafe/db/types.dart';
import 'package:notysafe/utils/encryption.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    debugPrint('Initializing database');

    String path = await getDatabasesPath();
    path = join(path, 'notysafe.db');

    debugPrint('Database path: $path');

    //deleteDatabase(path);

    return await openDatabase(path, version: 1, onOpen: _createDatabase);
  }

  Future<int> nextNoteId() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT MAX(id) FROM notes',
    );

    return maps[0]['MAX(id)'] == null ? 1 : maps[0]['MAX(id)'] + 1;
  }

  Future<void> _createDatabase(Database db) async {
    debugPrint('Opening database');

    await db.execute('''
        CREATE TABLE IF NOT EXISTS notes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          content TEXT NOT NULL,
          date TEXT NOT NULL,
          isEncrypted INTEGER NOT NULL DEFAULT 0
        )
      ''');
  }

  Future<List<Note>> getNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('notes');

    return List.generate(maps.length, (i) {
      return Note(
        id: maps[i]['id'],
        title: maps[i]['title'],
        content: maps[i]['content'],
        date: maps[i]['date'],
        isEncrypted: maps[i]['isEncrypted'] == 1,
      );
    });
  }

  Future<void> insertNote(Note note) async {
    final db = await database;
    await db.insert('notes', {
      'title': note.title,
      'content': note.content,
      'date': note.date,
      'isEncrypted': note.isEncrypted ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateNote(Note note) async {
    final db = await database;

    if (note.isEncrypted) {
      debugPrint('Encrypted note, updating content');

      final encryptedContent = await EncryptionHelper.encrypt(
        note.content,
        'note_${note.id}',
      );
      await db.update(
        'notes',
        {
          'title': note.title,
          'content': encryptedContent,
          'date': note.date,
          'isEncrypted': note.isEncrypted ? 1 : 0,
        },
        where: 'id = ?',
        whereArgs: [note.id],
      );
    } else {
      await db.update(
        'notes',
        {
          'title': note.title,
          'content': note.content,
          'date': note.date,
          'isEncrypted': note.isEncrypted ? 1 : 0,
        },
        where: 'id = ?',
        whereArgs: [note.id],
      );
    }
  }

  void updateNoteSync(Note note) async {
    final db = await database;

    if (note.isEncrypted) {
      debugPrint('Encrypted note, updating content');

      final encryptedContent = await EncryptionHelper.encrypt(
        note.content,
        'note_${note.id}',
      );
      await db.update(
        'notes',
        {
          'title': note.title,
          'content': encryptedContent,
          'date': note.date,
          'isEncrypted': note.isEncrypted ? 1 : 0,
        },
        where: 'id = ?',
        whereArgs: [note.id],
      );
    } else {
      await db.update(
        'notes',
        {
          'title': note.title,
          'content': note.content,
          'date': note.date,
          'isEncrypted': note.isEncrypted ? 1 : 0,
        },
        where: 'id = ?',
        whereArgs: [note.id],
      );
    }
  }

  Future<void> deleteNote(int id) async {
    final db = await database;
    await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    debugPrint('Closing database');

    final db = await database;
    db.close();
  }
}

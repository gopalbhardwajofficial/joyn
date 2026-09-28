import 'dart:convert';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../presentation/label_editor_screen.dart'; // for SavedLabel model

class LabelDatabase {
  static final LabelDatabase instance = LabelDatabase._init();
  static Database? _db;

  LabelDatabase._init();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB('joyn_labels.db');
    return _db!;
  }

  Future<Database> _initDB(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE labels (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        widthMm REAL NOT NULL,
        heightMm REAL NOT NULL,
        isCircle INTEGER NOT NULL,
        elements TEXT NOT NULL,
        canvasBgValue INTEGER NOT NULL,
        gridStyle TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        thumbnailPath TEXT
      )
    ''');
  }

  // ───────────────── CRUD ─────────────────

  Future<String> insertOrUpdate(SavedLabel label) async {
    final db = await database;
    final data = {
      'id': label.id,
      'name': label.name,
      'widthMm': label.widthMm,
      'heightMm': label.heightMm,
      'isCircle': label.isCircle ? 1 : 0,
      'elements': jsonEncode(label.elements),
      'canvasBgValue': label.canvasBgValue,
      'gridStyle': label.gridStyle,
      'createdAt': label.createdAt.toIso8601String(),
      'updatedAt': label.updatedAt.toIso8601String(),
      'thumbnailPath': label.thumbnailPath,
    };

    await db.insert(
      'labels',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return label.id;
  }

  Future<List<SavedLabel>> getAll() async {
    final db = await database;
    final maps = await db.query('labels', orderBy: 'updatedAt DESC');

    return maps.map((m) {
      return SavedLabel(
        id: m['id'] as String,
        name: m['name'] as String,
        widthMm: (m['widthMm'] as num).toDouble(),
        heightMm: (m['heightMm'] as num).toDouble(),
        isCircle: (m['isCircle'] as int) == 1,
        elements: (jsonDecode(m['elements'] as String) as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        canvasBgValue: m['canvasBgValue'] as int,
        gridStyle: m['gridStyle'] as String,
        createdAt: DateTime.parse(m['createdAt'] as String),
        updatedAt: DateTime.parse(m['updatedAt'] as String),
        thumbnailPath: m['thumbnailPath'] as String?,
      );
    }).toList();
  }

  Future<SavedLabel?> getById(String id) async {
    final db = await database;
    final maps = await db.query('labels', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;

    final m = maps.first;
    return SavedLabel(
      id: m['id'] as String,
      name: m['name'] as String,
      widthMm: (m['widthMm'] as num).toDouble(),
      heightMm: (m['heightMm'] as num).toDouble(),
      isCircle: (m['isCircle'] as int) == 1,
      elements: (jsonDecode(m['elements'] as String) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      canvasBgValue: m['canvasBgValue'] as int,
      gridStyle: m['gridStyle'] as String,
      createdAt: DateTime.parse(m['createdAt'] as String),
      updatedAt: DateTime.parse(m['updatedAt'] as String),
      thumbnailPath: m['thumbnailPath'] as String?,
    );
  }

  Future<void> delete(String id) async {
    final db = await database;
    await db.delete('labels', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> rename(String id, String newName) async {
    final db = await database;
    await db.update(
      'labels',
      {
        'name': newName,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<String> duplicate(String id) async {
    final src = await getById(id);
    if (src == null) throw Exception('Label not found');

    final now = DateTime.now();
    final newId = 'label_${now.millisecondsSinceEpoch}';

    final copy = SavedLabel(
      id: newId,
      name: '${src.name} (Copy)',
      widthMm: src.widthMm,
      heightMm: src.heightMm,
      isCircle: src.isCircle,
      elements: List<Map<String, dynamic>>.from(src.elements),
      canvasBgValue: src.canvasBgValue,
      gridStyle: src.gridStyle,
      createdAt: now,
      updatedAt: now,
      thumbnailPath: src.thumbnailPath,
    );

    await insertOrUpdate(copy);
    return newId;
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('labels');
  }
}
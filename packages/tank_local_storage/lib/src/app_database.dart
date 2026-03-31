import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// {@template app_database}
/// SQLite database for the Fish Tank Tracker app.
/// {@endtemplate}
class AppDatabase {
  /// {@macro app_database}
  AppDatabase({Database? database}) : _database = database;

  Database? _database;

  /// Returns the database instance, opening it if necessary.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _open();
    return _database!;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'fish_tank_tracker.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tank_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            scientific_name TEXT,
            type TEXT NOT NULL,
            image_path TEXT NOT NULL,
            notes TEXT,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE water_parameters (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ph REAL,
            ammonia REAL,
            nitrite REAL,
            nitrate REAL,
            temperature REAL,
            gh REAL,
            kh REAL,
            recorded_at TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Migrations go here when schema changes.
        // Example:
        // if (oldVersion < 2) {
        //   await db.execute('ALTER TABLE tank_entries ADD COLUMN ...');
        // }
      },
    );
  }

  /// Closes the database.
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}

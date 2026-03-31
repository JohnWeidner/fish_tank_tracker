import 'dart:async';
import 'dart:io';

import 'package:tank_local_storage/src/app_database.dart';
import 'package:tank_repository/tank_repository.dart';

/// {@template local_tank_repository}
/// SQLite-backed implementation of [TankRepository].
/// {@endtemplate}
class LocalTankRepository extends TankRepository {
  /// {@macro local_tank_repository}
  LocalTankRepository({required AppDatabase database}) : _database = database;

  final AppDatabase _database;
  final _controller = StreamController<List<TankEntry>>.broadcast();

  @override
  Stream<List<TankEntry>> watchEntries() async* {
    yield await _fetchEntries();
    yield* _controller.stream;
  }

  @override
  Future<int> addEntry({
    required TankEntryType type,
    required String imagePath,
    String name = '',
    String? scientificName,
  }) async {
    final db = await _database.database;
    final id = await db.insert('tank_entries', {
      'name': name,
      'scientific_name': scientificName,
      'type': type.name,
      'image_path': imagePath,
      'created_at': DateTime.now().toIso8601String(),
    });
    await _notify();
    return id;
  }

  @override
  Future<void> updateEntry({
    required int id,
    required String name,
    String? scientificName,
    TankEntryType? type,
    String? imagePath,
  }) async {
    final db = await _database.database;
    final values = <String, Object?>{
      'name': name,
      'scientific_name': scientificName,
    };
    if (type != null) {
      values['type'] = type.name;
    }
    if (imagePath != null) {
      values['image_path'] = imagePath;
    }
    await db.update(
      'tank_entries',
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
    await _notify();
  }

  @override
  Future<void> deleteEntry(int id) async {
    final db = await _database.database;
    // Fetch the entry to get the image path before deleting.
    final rows = await db.query(
      'tank_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
    await db.delete('tank_entries', where: 'id = ?', whereArgs: [id]);
    // Clean up the image file.
    if (rows.isNotEmpty) {
      final imagePath = rows.first['image_path'] as String?;
      if (imagePath != null) {
        final file = File(imagePath);
        if (file.existsSync()) {
          await file.delete();
        }
      }
    }
    await _notify();
  }

  Future<List<TankEntry>> _fetchEntries() async {
    final db = await _database.database;
    final rows = await db.query(
      'tank_entries',
      orderBy: 'created_at DESC',
    );
    return rows.map(_rowToEntry).toList();
  }

  TankEntry _rowToEntry(Map<String, dynamic> row) {
    return TankEntry(
      id: row['id'] as int,
      name: row['name'] as String,
      scientificName: row['scientific_name'] as String?,
      type: TankEntryType.values.byName(row['type'] as String),
      imagePath: row['image_path'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  Future<void> _notify() async {
    _controller.add(await _fetchEntries());
  }

  /// Disposes resources.
  void dispose() {
    _controller.close();
  }
}

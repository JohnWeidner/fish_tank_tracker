import 'dart:async';

import 'package:tank_local_storage/src/app_database.dart';
import 'package:water_repository/water_repository.dart';

/// {@template local_water_repository}
/// SQLite-backed implementation of [WaterRepository].
/// {@endtemplate}
class LocalWaterRepository extends WaterRepository {
  /// {@macro local_water_repository}
  LocalWaterRepository({required AppDatabase database}) : _database = database;

  final AppDatabase _database;
  final _controller = StreamController<List<WaterParameters>>.broadcast();

  @override
  Stream<List<WaterParameters>> watchReadings() async* {
    yield await _fetchReadings();
    yield* _controller.stream;
  }

  @override
  Future<int> addReading({
    double? ph,
    double? ammonia,
    double? nitrite,
    double? nitrate,
    double? temperature,
    double? gh,
    double? kh,
  }) async {
    final db = await _database.database;
    final id = await db.insert('water_parameters', {
      'ph': ph,
      'ammonia': ammonia,
      'nitrite': nitrite,
      'nitrate': nitrate,
      'temperature': temperature,
      'gh': gh,
      'kh': kh,
      'recorded_at': DateTime.now().toIso8601String(),
    });
    await _notify();
    return id;
  }

  @override
  Future<void> deleteReading(int id) async {
    final db = await _database.database;
    await db.delete('water_parameters', where: 'id = ?', whereArgs: [id]);
    await _notify();
  }

  Future<List<WaterParameters>> _fetchReadings() async {
    final db = await _database.database;
    final rows = await db.query(
      'water_parameters',
      orderBy: 'recorded_at DESC',
    );
    return rows.map(_rowToParameters).toList();
  }

  WaterParameters _rowToParameters(Map<String, dynamic> row) {
    return WaterParameters(
      id: row['id'] as int,
      ph: row['ph'] as double?,
      ammonia: row['ammonia'] as double?,
      nitrite: row['nitrite'] as double?,
      nitrate: row['nitrate'] as double?,
      temperature: row['temperature'] as double?,
      gh: row['gh'] as double?,
      kh: row['kh'] as double?,
      recordedAt: DateTime.parse(row['recorded_at'] as String),
    );
  }

  Future<void> _notify() async {
    _controller.add(await _fetchReadings());
  }

  /// Disposes the stream controller.
  ///
  /// Currently not called — the repository is a singleton that lives for the
  /// app's lifetime, and the OS reclaims resources on exit. If the repository
  /// becomes scoped (e.g., per-user after adding auth), call this from a
  /// lifecycle observer or when the scope ends.
  void dispose() {
    _controller.close();
  }
}

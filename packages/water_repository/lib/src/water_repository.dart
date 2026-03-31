import 'package:water_repository/water_repository.dart';

/// {@template water_repository}
/// Repository interface for managing water parameter readings.
/// {@endtemplate}
abstract class WaterRepository {
  /// Returns a stream of all water parameter readings,
  /// ordered by most recent first.
  Stream<List<WaterParameters>> watchReadings();

  /// Adds a new water parameter reading and returns the generated id.
  Future<int> addReading({
    double? ph,
    double? ammonia,
    double? nitrite,
    double? nitrate,
    double? temperature,
    double? gh,
    double? kh,
  });

  /// Deletes a water parameter reading by id.
  Future<void> deleteReading(int id);
}

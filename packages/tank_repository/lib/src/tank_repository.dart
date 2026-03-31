import 'package:tank_repository/tank_repository.dart';

/// {@template tank_repository}
/// Repository interface for managing tank entries.
/// {@endtemplate}
abstract class TankRepository {
  /// Returns a stream of all tank entries.
  Stream<List<TankEntry>> watchEntries();

  /// Adds a new tank entry and returns the generated id.
  Future<int> addEntry({
    required TankEntryType type,
    required String imagePath,
    String name = '',
    String? scientificName,
  });

  /// Updates the name, optional scientific name, type, or image of an entry.
  Future<void> updateEntry({
    required int id,
    required String name,
    String? scientificName,
    TankEntryType? type,
    String? imagePath,
  });

  /// Deletes a tank entry by id.
  Future<void> deleteEntry(int id);
}

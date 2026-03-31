import 'package:equatable/equatable.dart';
import 'package:tank_repository/src/models/optional.dart';

/// The type of tank inhabitant.
enum TankEntryType {
  /// Fish, shrimp, snails, etc.
  livestock,

  /// Aquatic plants.
  plant,
}

/// A single tank inhabitant entry with photo and identification.
class TankEntry extends Equatable {
  /// Creates a [TankEntry].
  const TankEntry({
    required this.id,
    required this.type,
    required this.imagePath,
    required this.createdAt,
    this.name = '',
    this.scientificName,
  });

  /// Unique identifier.
  final int id;

  /// Common name (e.g. "Neon Tetra"). Empty string means unidentified.
  final String name;

  /// Whether this entry has a name assigned.
  bool get hasName => name.isNotEmpty;

  /// Optional scientific/Latin name.
  final String? scientificName;

  /// Whether this is livestock or a plant.
  final TankEntryType type;

  /// Local file path to the photo.
  final String imagePath;

  /// When this entry was created.
  final DateTime createdAt;

  /// Creates a copy with the given fields replaced.
  ///
  /// Wrap [scientificName] in [Optional] to distinguish between "not provided"
  /// and "set to null":
  /// ```dart
  /// entry.copyWith(scientificName: Optional(null))     // clear it
  /// entry.copyWith(scientificName: Optional('Danio'))   // set it
  /// entry.copyWith()                                    // don't change
  /// ```
  TankEntry copyWith({
    String? name,
    Optional<String?>? scientificName,
    TankEntryType? type,
    String? imagePath,
  }) {
    return TankEntry(
      id: id,
      name: name ?? this.name,
      scientificName: scientificName != null
          ? scientificName.value
          : this.scientificName,
      type: type ?? this.type,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        scientificName,
        type,
        imagePath,
        createdAt,
      ];
}

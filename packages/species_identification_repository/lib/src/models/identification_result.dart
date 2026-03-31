import 'package:equatable/equatable.dart';

/// The result of an AI species identification.
class IdentificationResult extends Equatable {
  /// Creates an [IdentificationResult].
  const IdentificationResult({
    required this.commonName,
    required this.type,
    this.scientificName,
  });

  /// Common English name (e.g. "Neon Tetra").
  final String commonName;

  /// Optional scientific/Latin name.
  final String? scientificName;

  /// Whether this is "livestock" or "plant".
  final String type;

  @override
  List<Object?> get props => [commonName, scientificName, type];
}

import 'package:equatable/equatable.dart';

/// A single water parameter reading with timestamp.
class WaterParameters extends Equatable {
  /// Creates a [WaterParameters].
  const WaterParameters({
    required this.id,
    required this.recordedAt,
    this.ph,
    this.ammonia,
    this.nitrite,
    this.nitrate,
    this.temperature,
    this.gh,
    this.kh,
  });

  /// Unique identifier.
  final int id;

  /// pH level (typical: 6.0 - 8.5).
  final double? ph;

  /// Ammonia in ppm (ideal: 0.0).
  final double? ammonia;

  /// Nitrite in ppm (ideal: 0.0).
  final double? nitrite;

  /// Nitrate in ppm (typical: 0 - 40).
  final double? nitrate;

  /// Temperature in Fahrenheit (typical: 72 - 82).
  final double? temperature;

  /// General hardness in dGH (typical: 4 - 12).
  final double? gh;

  /// Carbonate hardness in dKH (typical: 3 - 10).
  final double? kh;

  /// When this reading was recorded.
  final DateTime recordedAt;

  @override
  List<Object?> get props => [
        id,
        ph,
        ammonia,
        nitrite,
        nitrate,
        temperature,
        gh,
        kh,
        recordedAt,
      ];
}

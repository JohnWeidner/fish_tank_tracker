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

  /// Whether the pH is outside the safe range (6.0 – 8.5).
  bool get isPhWarning => ph != null && (ph! < 6.0 || ph! > 8.5);

  /// Whether ammonia is above safe levels (should be 0).
  bool get isAmmoniaWarning => ammonia != null && ammonia! > 0;

  /// Whether nitrite is above safe levels (should be 0).
  bool get isNitriteWarning => nitrite != null && nitrite! > 0;

  /// Whether nitrate is above typical levels (> 40 ppm).
  bool get isNitrateWarning => nitrate != null && nitrate! > 40;

  /// Whether temperature is outside the typical range (68 – 86 °F).
  bool get isTemperatureWarning =>
      temperature != null && (temperature! < 68 || temperature! > 86);

  /// Whether general hardness is outside the typical range (3 – 15 dGH).
  bool get isGhWarning => gh != null && (gh! < 3 || gh! > 15);

  /// Whether carbonate hardness is outside the typical range (2 – 12 dKH).
  bool get isKhWarning => kh != null && (kh! < 2 || kh! > 12);

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

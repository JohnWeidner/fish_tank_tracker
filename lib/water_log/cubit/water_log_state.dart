import 'package:water_repository/water_repository.dart';

/// The state of the water log feature.
sealed class WaterLogState {
  const WaterLogState();
}

/// The water log is loading.
class WaterLogLoading extends WaterLogState {
  /// Creates a [WaterLogLoading].
  const WaterLogLoading();
}

/// The water log has loaded.
class WaterLogLoaded extends WaterLogState {
  /// Creates a [WaterLogLoaded].
  const WaterLogLoaded({required this.readings});

  /// All water parameter readings, most recent first.
  final List<WaterParameters> readings;
}

/// The water log failed to load.
class WaterLogFailure extends WaterLogState {
  /// Creates a [WaterLogFailure].
  const WaterLogFailure(this.message);

  /// The error message.
  final String message;
}

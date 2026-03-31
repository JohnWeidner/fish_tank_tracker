import 'dart:async';

import 'package:fish_tank_tracker/water_log/cubit/water_log_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:water_repository/water_repository.dart';

/// {@template water_log_cubit}
/// Manages the state of the water log feature.
/// {@endtemplate}
class WaterLogCubit extends Cubit<WaterLogState> {
  /// {@macro water_log_cubit}
  WaterLogCubit({required WaterRepository waterRepository})
      : _waterRepository = waterRepository,
        super(const WaterLogLoading());

  final WaterRepository _waterRepository;
  StreamSubscription<List<WaterParameters>>? _subscription;

  /// Starts watching water parameter readings.
  void load() {
    _subscription?.cancel();
    _subscription = _waterRepository.watchReadings().listen(
      (readings) {
        emit(WaterLogLoaded(readings: readings));
      },
      onError: (Object error) {
        emit(WaterLogFailure(error.toString()));
      },
    );
  }

  /// Adds a new water parameter reading.
  Future<void> addReading({
    double? ph,
    double? ammonia,
    double? nitrite,
    double? nitrate,
    double? temperature,
    double? gh,
    double? kh,
  }) async {
    await _waterRepository.addReading(
      ph: ph,
      ammonia: ammonia,
      nitrite: nitrite,
      nitrate: nitrate,
      temperature: temperature,
      gh: gh,
      kh: kh,
    );
  }

  /// Deletes a water parameter reading.
  Future<void> deleteReading(int id) async {
    await _waterRepository.deleteReading(id);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

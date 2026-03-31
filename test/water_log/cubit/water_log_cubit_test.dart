import 'package:bloc_test/bloc_test.dart';
import 'package:fish_tank_tracker/water_log/cubit/water_log_cubit.dart';
import 'package:fish_tank_tracker/water_log/cubit/water_log_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:water_repository/water_repository.dart';

class MockWaterRepository extends Mock implements WaterRepository {}

void main() {
  late MockWaterRepository mockWaterRepository;

  setUp(() {
    mockWaterRepository = MockWaterRepository();
  });

  final testReadings = [
    WaterParameters(
      id: 1,
      ph: 7,
      ammonia: 0,
      nitrite: 0,
      nitrate: 20,
      temperature: 78,
      gh: 8,
      kh: 5,
      recordedAt: DateTime(2026),
    ),
  ];

  group('WaterLogCubit', () {
    blocTest<WaterLogCubit, WaterLogState>(
      'emits [WaterLogLoaded] when load succeeds',
      build: () {
        when(() => mockWaterRepository.watchReadings())
            .thenAnswer((_) => Stream.value(testReadings));
        return WaterLogCubit(waterRepository: mockWaterRepository);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<WaterLogLoaded>()
            .having((s) => s.readings.length, 'readings count', 1),
      ],
    );

    blocTest<WaterLogCubit, WaterLogState>(
      'emits [WaterLogFailure] when load fails',
      build: () {
        when(() => mockWaterRepository.watchReadings())
            .thenAnswer((_) => Stream.error(Exception('db error')));
        return WaterLogCubit(waterRepository: mockWaterRepository);
      },
      act: (cubit) => cubit.load(),
      expect: () => [isA<WaterLogFailure>()],
    );

    blocTest<WaterLogCubit, WaterLogState>(
      'addReading calls repository',
      build: () {
        when(() => mockWaterRepository.watchReadings())
            .thenAnswer((_) => Stream.value(testReadings));
        when(
          () => mockWaterRepository.addReading(
            ph: any(named: 'ph'),
            ammonia: any(named: 'ammonia'),
            nitrite: any(named: 'nitrite'),
            nitrate: any(named: 'nitrate'),
            temperature: any(named: 'temperature'),
            gh: any(named: 'gh'),
            kh: any(named: 'kh'),
          ),
        ).thenAnswer((_) async => 1);
        return WaterLogCubit(waterRepository: mockWaterRepository);
      },
      act: (cubit) => cubit.addReading(ph: 7.2),
      verify: (_) {
        verify(
          () => mockWaterRepository.addReading(ph: 7.2),
        ).called(1);
      },
    );

    blocTest<WaterLogCubit, WaterLogState>(
      'deleteReading calls repository',
      build: () {
        when(() => mockWaterRepository.watchReadings())
            .thenAnswer((_) => Stream.value(testReadings));
        when(() => mockWaterRepository.deleteReading(any()))
            .thenAnswer((_) async {});
        return WaterLogCubit(waterRepository: mockWaterRepository);
      },
      act: (cubit) => cubit.deleteReading(1),
      verify: (_) {
        verify(() => mockWaterRepository.deleteReading(1)).called(1);
      },
    );
  });
}

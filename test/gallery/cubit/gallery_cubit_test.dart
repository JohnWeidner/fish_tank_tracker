import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:fish_tank_tracker/gallery/cubit/gallery_cubit.dart';
import 'package:fish_tank_tracker/gallery/cubit/gallery_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tank_repository/tank_repository.dart';

class MockTankRepository extends Mock implements TankRepository {}

void main() {
  late MockTankRepository mockTankRepository;

  setUpAll(() {
    registerFallbackValue(TankEntryType.livestock);
  });

  setUp(() {
    mockTankRepository = MockTankRepository();
  });

  final testEntries = [
    TankEntry(
      id: 1,
      name: 'Neon Tetra',
      type: TankEntryType.livestock,
      imagePath: '/images/1.jpg',
      createdAt: DateTime(2026),
    ),
    TankEntry(
      id: 2,
      name: 'Java Fern',
      type: TankEntryType.plant,
      imagePath: '/images/2.jpg',
      createdAt: DateTime(2026),
    ),
  ];

  group('GalleryCubit', () {
    blocTest<GalleryCubit, GalleryState>(
      'emits [GalleryLoaded] when load succeeds',
      build: () {
        when(() => mockTankRepository.watchEntries())
            .thenAnswer((_) => Stream.value(testEntries));
        return GalleryCubit(tankRepository: mockTankRepository);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<GalleryLoaded>()
            .having((s) => s.livestock.length, 'livestock count', 1)
            .having((s) => s.plants.length, 'plants count', 1),
      ],
    );

    blocTest<GalleryCubit, GalleryState>(
      'emits [GalleryFailure] when load fails',
      build: () {
        when(() => mockTankRepository.watchEntries())
            .thenAnswer((_) => Stream.error(Exception('db error')));
        return GalleryCubit(tankRepository: mockTankRepository);
      },
      act: (cubit) => cubit.load(),
      expect: () => [isA<GalleryFailure>()],
    );

    blocTest<GalleryCubit, GalleryState>(
      'toggleSection switches between livestock and plants',
      build: () {
        when(() => mockTankRepository.watchEntries())
            .thenAnswer((_) => Stream.value(testEntries));
        return GalleryCubit(tankRepository: mockTankRepository);
      },
      act: (cubit) async {
        cubit.load();
        await Future<void>.delayed(Duration.zero);
        cubit.toggleSection();
      },
      skip: 1,
      expect: () => [
        isA<GalleryLoaded>()
            .having((s) => s.showingLivestock, 'showingLivestock', false)
            .having((s) => s.currentIndex, 'currentIndex', 0),
      ],
    );

    blocTest<GalleryCubit, GalleryState>(
      'pageChanged updates current index',
      build: () {
        when(() => mockTankRepository.watchEntries())
            .thenAnswer((_) => Stream.value(testEntries));
        return GalleryCubit(tankRepository: mockTankRepository);
      },
      act: (cubit) async {
        cubit.load();
        await Future<void>.delayed(Duration.zero);
        cubit.pageChanged(1);
      },
      skip: 1,
      expect: () => [
        isA<GalleryLoaded>()
            .having((s) => s.currentIndex, 'currentIndex', 1),
      ],
    );

    blocTest<GalleryCubit, GalleryState>(
      'clamps currentIndex when list shrinks',
      build: () {
        final controller = StreamController<List<TankEntry>>();
        when(() => mockTankRepository.watchEntries())
            .thenAnswer((_) => controller.stream);
        return GalleryCubit(tankRepository: mockTankRepository);
      },
      act: (cubit) async {
        final controller = StreamController<List<TankEntry>>();
        when(() => mockTankRepository.watchEntries())
            .thenAnswer((_) => controller.stream);

        // Emit 3 livestock entries.
        final threeEntries = [
          for (var i = 1; i <= 3; i++)
            TankEntry(
              id: i,
              name: 'Fish $i',
              type: TankEntryType.livestock,
              imagePath: '/images/$i.jpg',
              createdAt: DateTime(2026),
            ),
        ];
        cubit.load();
        controller.add(threeEntries);
        await Future<void>.delayed(Duration.zero);

        // Navigate to last page (index 2).
        cubit.pageChanged(2);

        // Emit only 2 entries — index should clamp from 2 to 1.
        controller.add(threeEntries.sublist(0, 2));
        await Future<void>.delayed(Duration.zero);

        await controller.close();
      },
      expect: () => [
        // Initial load with 3 entries.
        isA<GalleryLoaded>()
            .having((s) => s.livestock.length, 'livestock count', 3)
            .having((s) => s.currentIndex, 'currentIndex', 0),
        // pageChanged to 2.
        isA<GalleryLoaded>()
            .having((s) => s.currentIndex, 'currentIndex', 2),
        // After shrink: clamped to 1.
        isA<GalleryLoaded>()
            .having((s) => s.livestock.length, 'livestock count', 2)
            .having((s) => s.currentIndex, 'currentIndex', 1),
      ],
    );
    test('addEntry calls repository and returns TankEntry', () async {
      when(
        () => mockTankRepository.addEntry(
          type: any(named: 'type'),
          imagePath: any(named: 'imagePath'),
        ),
      ).thenAnswer((_) async => 42);
      when(() => mockTankRepository.watchEntries())
          .thenAnswer((_) => const Stream.empty());

      final cubit = GalleryCubit(tankRepository: mockTankRepository);
      final entry = await cubit.addEntry('/images/new.jpg');

      expect(entry.id, 42);
      expect(entry.imagePath, '/images/new.jpg');
      expect(entry.type, TankEntryType.livestock);
      expect(entry.name, '');

      verify(
        () => mockTankRepository.addEntry(
          type: TankEntryType.livestock,
          imagePath: '/images/new.jpg',
        ),
      ).called(1);

      await cubit.close();
    });
  });
}

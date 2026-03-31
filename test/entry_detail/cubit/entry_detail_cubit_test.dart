import 'package:bloc_test/bloc_test.dart';
import 'package:fish_tank_tracker/entry_detail/cubit/entry_detail_cubit.dart';
import 'package:fish_tank_tracker/entry_detail/cubit/entry_detail_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:species_identification_repository/species_identification_repository.dart';
import 'package:tank_repository/tank_repository.dart';

class MockTankRepository extends Mock implements TankRepository {}

class MockSpeciesIdentificationRepository extends Mock
    implements SpeciesIdentificationRepository {}

void main() {
  late MockTankRepository mockTankRepository;

  final testEntry = TankEntry(
    id: 1,
    name: 'Neon Tetra',
    scientificName: 'Paracheirodon innesi',
    type: TankEntryType.livestock,
    imagePath: '/images/1.jpg',
    createdAt: DateTime(2026),
  );

  final emptyEntry = TankEntry(
    id: 2,
    type: TankEntryType.livestock,
    imagePath: '/images/2.jpg',
    createdAt: DateTime(2026),
  );

  setUpAll(() {
    registerFallbackValue(TankEntryType.livestock);
  });

  setUp(() {
    mockTankRepository = MockTankRepository();
    when(
      () => mockTankRepository.updateEntry(
        id: any(named: 'id'),
        name: any(named: 'name'),
        scientificName: any(named: 'scientificName'),
        type: any(named: 'type'),
        imagePath: any(named: 'imagePath'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockTankRepository.deleteEntry(any()))
        .thenAnswer((_) async {});
  });

  group('EntryDetailCubit', () {
    blocTest<EntryDetailCubit, EntryDetailState>(
      'initial state is EntryDetailLoaded with the provided entry',
      build: () => EntryDetailCubit(
        entry: testEntry,
        tankRepository: mockTankRepository,
      ),
      verify: (cubit) {
        expect(
          cubit.state,
          isA<EntryDetailLoaded>()
              .having((s) => s.entry.name, 'name', 'Neon Tetra'),
        );
        expect(cubit.isNewEntry, isFalse);
      },
    );

    blocTest<EntryDetailCubit, EntryDetailState>(
      'isNewEntry is true when passed',
      build: () => EntryDetailCubit(
        entry: testEntry,
        tankRepository: mockTankRepository,
        isNewEntry: true,
      ),
      verify: (cubit) {
        expect(cubit.isNewEntry, isTrue);
      },
    );

    blocTest<EntryDetailCubit, EntryDetailState>(
      'updateName saves after debounce',
      build: () => EntryDetailCubit(
        entry: testEntry,
        tankRepository: mockTankRepository,
      ),
      act: (cubit) async {
        cubit.updateName('Cardinal Tetra');
        await Future<void>.delayed(const Duration(milliseconds: 600));
      },
      expect: () => [
        isA<EntryDetailLoaded>()
            .having((s) => s.entry.name, 'name', 'Cardinal Tetra'),
      ],
      verify: (_) {
        verify(
          () => mockTankRepository.updateEntry(
            id: 1,
            name: 'Cardinal Tetra',
            scientificName: 'Paracheirodon innesi',
            type: TankEntryType.livestock,
          ),
        ).called(1);
      },
    );

    blocTest<EntryDetailCubit, EntryDetailState>(
      'updateName resets debounce on rapid input — only final value saved',
      build: () => EntryDetailCubit(
        entry: testEntry,
        tankRepository: mockTankRepository,
      ),
      act: (cubit) async {
        cubit
          ..updateName('C')
          ..updateName('Ca')
          ..updateName('Cardinal Tetra');
        await Future<void>.delayed(const Duration(milliseconds: 600));
      },
      expect: () => [
        isA<EntryDetailLoaded>()
            .having((s) => s.entry.name, 'name', 'Cardinal Tetra'),
      ],
      verify: (_) {
        verify(
          () => mockTankRepository.updateEntry(
            id: any(named: 'id'),
            name: any(named: 'name'),
            scientificName: any(named: 'scientificName'),
            type: any(named: 'type'),
          ),
        ).called(1);
      },
    );

    blocTest<EntryDetailCubit, EntryDetailState>(
      'updateName with empty string still saves (guard removed)',
      build: () => EntryDetailCubit(
        entry: testEntry,
        tankRepository: mockTankRepository,
      ),
      act: (cubit) async {
        cubit.updateName('');
        await Future<void>.delayed(const Duration(milliseconds: 600));
      },
      expect: () => [
        isA<EntryDetailLoaded>()
            .having((s) => s.entry.name, 'name', ''),
      ],
      verify: (_) {
        verify(
          () => mockTankRepository.updateEntry(
            id: 1,
            name: '',
            scientificName: 'Paracheirodon innesi',
            type: TankEntryType.livestock,
          ),
        ).called(1);
      },
    );

    blocTest<EntryDetailCubit, EntryDetailState>(
      'updateType saves immediately',
      build: () => EntryDetailCubit(
        entry: testEntry,
        tankRepository: mockTankRepository,
      ),
      act: (cubit) => cubit.updateType(TankEntryType.plant),
      expect: () => [
        isA<EntryDetailLoaded>()
            .having((s) => s.entry.type, 'type', TankEntryType.plant),
      ],
      verify: (_) {
        verify(
          () => mockTankRepository.updateEntry(
            id: 1,
            name: 'Neon Tetra',
            scientificName: 'Paracheirodon innesi',
            type: TankEntryType.plant,
          ),
        ).called(1);
      },
    );

    blocTest<EntryDetailCubit, EntryDetailState>(
      'updateType cancels pending debounced name save',
      build: () => EntryDetailCubit(
        entry: testEntry,
        tankRepository: mockTankRepository,
      ),
      act: (cubit) async {
        cubit.updateName('Pending Name');
        await cubit.updateType(TankEntryType.plant);
        await Future<void>.delayed(const Duration(milliseconds: 600));
      },
      expect: () => [
        isA<EntryDetailLoaded>()
            .having((s) => s.entry.type, 'type', TankEntryType.plant),
      ],
      verify: (_) {
        verify(
          () => mockTankRepository.updateEntry(
            id: any(named: 'id'),
            name: any(named: 'name'),
            scientificName: any(named: 'scientificName'),
            type: any(named: 'type'),
          ),
        ).called(1);
      },
    );

    blocTest<EntryDetailCubit, EntryDetailState>(
      'deleteEntry emits EntryDetailDeleted',
      build: () => EntryDetailCubit(
        entry: testEntry,
        tankRepository: mockTankRepository,
      ),
      act: (cubit) => cubit.deleteEntry(),
      expect: () => [isA<EntryDetailDeleted>()],
      verify: (_) {
        verify(() => mockTankRepository.deleteEntry(1)).called(1);
      },
    );

    blocTest<EntryDetailCubit, EntryDetailState>(
      'deleteEntry cancels pending debounced save',
      build: () => EntryDetailCubit(
        entry: testEntry,
        tankRepository: mockTankRepository,
      ),
      act: (cubit) async {
        cubit.updateName('New Name');
        await cubit.deleteEntry();
        await Future<void>.delayed(const Duration(milliseconds: 600));
      },
      expect: () => [isA<EntryDetailDeleted>()],
      verify: (_) {
        verifyNever(
          () => mockTankRepository.updateEntry(
            id: any(named: 'id'),
            name: any(named: 'name'),
            scientificName: any(named: 'scientificName'),
            type: any(named: 'type'),
          ),
        );
      },
    );

    blocTest<EntryDetailCubit, EntryDetailState>(
      'close flushes pending debounced save',
      build: () => EntryDetailCubit(
        entry: testEntry,
        tankRepository: mockTankRepository,
      ),
      act: (cubit) async {
        cubit.updateName('Flushed Name');
        await cubit.close();
      },
      verify: (_) {
        verify(
          () => mockTankRepository.updateEntry(
            id: 1,
            name: 'Flushed Name',
            scientificName: 'Paracheirodon innesi',
            type: TankEntryType.livestock,
          ),
        ).called(1);
      },
    );

    group('updateScientificName', () {
      blocTest<EntryDetailCubit, EntryDetailState>(
        'saves non-empty value after debounce',
        build: () => EntryDetailCubit(
          entry: testEntry,
          tankRepository: mockTankRepository,
        ),
        act: (cubit) async {
          cubit.updateScientificName('Paracheirodon axelrodi');
          await Future<void>.delayed(const Duration(milliseconds: 600));
        },
        expect: () => [
          isA<EntryDetailLoaded>().having(
            (s) => s.entry.scientificName,
            'scientificName',
            'Paracheirodon axelrodi',
          ),
        ],
      );

      blocTest<EntryDetailCubit, EntryDetailState>(
        'saves null when cleared to empty string',
        build: () => EntryDetailCubit(
          entry: testEntry,
          tankRepository: mockTankRepository,
        ),
        act: (cubit) async {
          cubit.updateScientificName('');
          await Future<void>.delayed(const Duration(milliseconds: 600));
        },
        expect: () => [
          isA<EntryDetailLoaded>().having(
            (s) => s.entry.scientificName,
            'scientificName',
            isNull,
          ),
        ],
      );
    });

    group('updateImage', () {
      blocTest<EntryDetailCubit, EntryDetailState>(
        'emits loaded state with new image path',
        build: () => EntryDetailCubit(
          entry: testEntry,
          tankRepository: mockTankRepository,
        ),
        act: (cubit) => cubit.updateImage('/images/new.jpg'),
        expect: () => [
          isA<EntryDetailLoaded>().having(
            (s) => s.entry.imagePath,
            'imagePath',
            '/images/new.jpg',
          ),
        ],
        verify: (_) {
          verify(
            () => mockTankRepository.updateEntry(
              id: 1,
              name: 'Neon Tetra',
              scientificName: 'Paracheirodon innesi',
              type: TankEntryType.livestock,
              imagePath: '/images/new.jpg',
            ),
          ).called(1);
        },
      );
    });

    group('revert', () {
      blocTest<EntryDetailCubit, EntryDetailState>(
        'reverts to original entry and calls repository',
        build: () => EntryDetailCubit(
          entry: testEntry,
          tankRepository: mockTankRepository,
        ),
        act: (cubit) async {
          // Make some changes first.
          cubit.updateName('Changed Name');
          await Future<void>.delayed(const Duration(milliseconds: 600));
          // Then revert.
          await cubit.revert();
        },
        expect: () => [
          // Debounced save with changed name.
          isA<EntryDetailLoaded>()
              .having((s) => s.entry.name, 'name', 'Changed Name'),
          // Reverted to original.
          isA<EntryDetailLoaded>()
              .having((s) => s.entry.name, 'name', 'Neon Tetra'),
        ],
        verify: (_) {
          // The revert call with original values.
          verify(
            () => mockTankRepository.updateEntry(
              id: 1,
              name: 'Neon Tetra',
              scientificName: 'Paracheirodon innesi',
              type: TankEntryType.livestock,
              imagePath: '/images/1.jpg',
            ),
          ).called(1);
        },
      );

      blocTest<EntryDetailCubit, EntryDetailState>(
        'cancels pending debounced save',
        build: () => EntryDetailCubit(
          entry: testEntry,
          tankRepository: mockTankRepository,
        ),
        act: (cubit) async {
          cubit.updateName('Pending');
          // Revert before debounce fires.
          await cubit.revert();
          await Future<void>.delayed(const Duration(milliseconds: 600));
        },
        expect: () => [
          isA<EntryDetailLoaded>()
              .having((s) => s.entry.name, 'name', 'Neon Tetra'),
        ],
      );
    });

    group('cancel', () {
      blocTest<EntryDetailCubit, EntryDetailState>(
        'deletes entry and emits EntryDetailDeleted',
        build: () => EntryDetailCubit(
          entry: emptyEntry,
          tankRepository: mockTankRepository,
          isNewEntry: true,
        ),
        act: (cubit) => cubit.cancel(),
        expect: () => [isA<EntryDetailDeleted>()],
        verify: (_) {
          verify(() => mockTankRepository.deleteEntry(2)).called(1);
        },
      );

      blocTest<EntryDetailCubit, EntryDetailState>(
        'cancels pending debounced save',
        build: () => EntryDetailCubit(
          entry: emptyEntry,
          tankRepository: mockTankRepository,
          isNewEntry: true,
        ),
        act: (cubit) async {
          cubit.updateName('Some Name');
          await cubit.cancel();
          await Future<void>.delayed(const Duration(milliseconds: 600));
        },
        expect: () => [isA<EntryDetailDeleted>()],
        verify: (_) {
          verifyNever(
            () => mockTankRepository.updateEntry(
              id: any(named: 'id'),
              name: any(named: 'name'),
              scientificName: any(named: 'scientificName'),
              type: any(named: 'type'),
            ),
          );
        },
      );
    });

    group('reidentify', () {
      late MockSpeciesIdentificationRepository mockSpeciesRepo;

      setUp(() {
        mockSpeciesRepo = MockSpeciesIdentificationRepository();
      });

      blocTest<EntryDetailCubit, EntryDetailState>(
        'emits identifying then updated entry on success',
        build: () {
          when(() => mockSpeciesRepo.identify(any())).thenAnswer(
            (_) async => const IdentificationResult(
              commonName: 'Java Fern',
              scientificName: 'Microsorum pteropus',
              type: 'plant',
            ),
          );
          return EntryDetailCubit(
            entry: testEntry,
            tankRepository: mockTankRepository,
            speciesIdentificationRepository: mockSpeciesRepo,
          );
        },
        act: (cubit) => cubit.reidentify(),
        expect: () => [
          isA<EntryDetailLoaded>()
              .having((s) => s.isIdentifying, 'isIdentifying', true),
          isA<EntryDetailLoaded>()
              .having((s) => s.isIdentifying, 'isIdentifying', false)
              .having((s) => s.entry.name, 'name', 'Java Fern')
              .having(
                (s) => s.entry.scientificName,
                'scientificName',
                'Microsorum pteropus',
              )
              .having(
                (s) => s.entry.type,
                'type',
                TankEntryType.plant,
              ),
        ],
        verify: (_) {
          verify(
            () => mockTankRepository.updateEntry(
              id: 1,
              name: 'Java Fern',
              scientificName: 'Microsorum pteropus',
              type: TankEntryType.plant,
            ),
          ).called(1);
        },
      );

      blocTest<EntryDetailCubit, EntryDetailState>(
        'emits identifying then reverts on failure',
        build: () {
          when(() => mockSpeciesRepo.identify(any()))
              .thenThrow(const NetworkFailure());
          return EntryDetailCubit(
            entry: testEntry,
            tankRepository: mockTankRepository,
            speciesIdentificationRepository: mockSpeciesRepo,
          );
        },
        act: (cubit) => cubit.reidentify(),
        expect: () => [
          isA<EntryDetailLoaded>()
              .having((s) => s.isIdentifying, 'isIdentifying', true),
          isA<EntryDetailLoaded>()
              .having((s) => s.isIdentifying, 'isIdentifying', false)
              .having((s) => s.entry.name, 'name', 'Neon Tetra'),
        ],
      );

      blocTest<EntryDetailCubit, EntryDetailState>(
        'does nothing when no species repo is provided',
        build: () => EntryDetailCubit(
          entry: testEntry,
          tankRepository: mockTankRepository,
        ),
        act: (cubit) => cubit.reidentify(),
        expect: () => <EntryDetailState>[],
      );
    });
  });
}

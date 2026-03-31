import 'package:tank_repository/tank_repository.dart';
import 'package:test/test.dart';

void main() {
  group('TankEntry', () {
    final entry = TankEntry(
      id: 1,
      name: 'Neon Tetra',
      scientificName: 'Paracheirodon innesi',
      type: TankEntryType.livestock,
      imagePath: '/images/1.jpg',
      createdAt: DateTime(2026),
    );

    test('supports value equality', () {
      expect(
        entry,
        equals(
          TankEntry(
            id: 1,
            name: 'Neon Tetra',
            scientificName: 'Paracheirodon innesi',
            type: TankEntryType.livestock,
            imagePath: '/images/1.jpg',
            createdAt: DateTime(2026),
          ),
        ),
      );
    });

    test('different entries are not equal', () {
      final other = TankEntry(
        id: 2,
        name: 'Cardinal Tetra',
        type: TankEntryType.livestock,
        imagePath: '/images/2.jpg',
        createdAt: DateTime(2026),
      );
      expect(entry, isNot(equals(other)));
    });

    test('scientificName can be null', () {
      final noScientific = TankEntry(
        id: 3,
        name: 'Mystery Fish',
        type: TankEntryType.livestock,
        imagePath: '/images/3.jpg',
        createdAt: DateTime(2026),
      );
      expect(noScientific.scientificName, isNull);
    });
  });

  group('TankEntryType', () {
    test('has livestock and plant values', () {
      expect(TankEntryType.values, containsAll([
        TankEntryType.livestock,
        TankEntryType.plant,
      ]));
    });
  });
}

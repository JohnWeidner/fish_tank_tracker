import 'package:test/test.dart';
import 'package:water_repository/water_repository.dart';

void main() {
  group('WaterParameters', () {
    test('supports value equality', () {
      final a = WaterParameters(
        id: 1,
        ph: 7,
        ammonia: 0,
        recordedAt: DateTime(2026),
      );
      final b = WaterParameters(
        id: 1,
        ph: 7,
        ammonia: 0,
        recordedAt: DateTime(2026),
      );
      expect(a, equals(b));
    });

    test('allows all optional fields to be null', () {
      final params = WaterParameters(
        id: 1,
        recordedAt: DateTime(2026),
      );
      expect(params.ph, isNull);
      expect(params.ammonia, isNull);
      expect(params.nitrite, isNull);
      expect(params.nitrate, isNull);
      expect(params.temperature, isNull);
      expect(params.gh, isNull);
      expect(params.kh, isNull);
    });
  });
}

import 'package:species_identification_repository/species_identification_repository.dart';
import 'package:test/test.dart';

void main() {
  group('IdentificationResult', () {
    test('supports value equality', () {
      const a = IdentificationResult(
        commonName: 'Neon Tetra',
        scientificName: 'Paracheirodon innesi',
        type: 'livestock',
      );
      const b = IdentificationResult(
        commonName: 'Neon Tetra',
        scientificName: 'Paracheirodon innesi',
        type: 'livestock',
      );
      expect(a, equals(b));
    });

    test('scientificName can be null', () {
      const result = IdentificationResult(
        commonName: 'Unknown Fish',
        type: 'livestock',
      );
      expect(result.scientificName, isNull);
    });
  });

  group('IdentificationFailure', () {
    test('InvalidApiKeyFailure has correct message', () {
      const failure = InvalidApiKeyFailure();
      expect(failure.message, contains('API key'));
    });

    test('RateLimitedFailure has correct message', () {
      const failure = RateLimitedFailure();
      expect(failure.message, contains('Too many requests'));
    });

    test('TimeoutFailure has correct message', () {
      const failure = TimeoutFailure();
      expect(failure.message, contains('timed out'));
    });

    test('NetworkFailure has correct message', () {
      const failure = NetworkFailure();
      expect(failure.message, contains('internet'));
    });

    test('ParseFailure has correct message', () {
      const failure = ParseFailure();
      expect(failure.message, contains('parse'));
    });
  });
}

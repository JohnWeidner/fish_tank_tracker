import 'package:species_identification_repository/species_identification_repository.dart';

/// Failure types for species identification.
sealed class IdentificationFailure implements Exception {
  const IdentificationFailure(this.message);

  /// Human-readable error message.
  final String message;
}

/// The API key is invalid or missing.
class InvalidApiKeyFailure extends IdentificationFailure {
  /// Creates an [InvalidApiKeyFailure].
  const InvalidApiKeyFailure()
      : super('Your API key appears invalid. Check Settings.');
}

/// The API rate limit was exceeded.
class RateLimitedFailure extends IdentificationFailure {
  /// Creates a [RateLimitedFailure].
  const RateLimitedFailure()
      : super('Too many requests. Try again in a moment.');
}

/// The API request timed out.
class TimeoutFailure extends IdentificationFailure {
  /// Creates a [TimeoutFailure].
  const TimeoutFailure()
      : super('Identification timed out. Enter name manually.');
}

/// A network error occurred.
class NetworkFailure extends IdentificationFailure {
  /// Creates a [NetworkFailure].
  const NetworkFailure() : super('No internet connection.');
}

/// The API response could not be parsed.
class ParseFailure extends IdentificationFailure {
  /// Creates a [ParseFailure].
  const ParseFailure() : super('Could not parse identification result.');
}

/// {@template species_identification_repository}
/// Repository interface for identifying species from images.
/// {@endtemplate}
// ignore: one_member_abstracts
abstract class SpeciesIdentificationRepository {
  /// Identifies the species in the image at [imagePath].
  ///
  /// Throws [IdentificationFailure] subtypes on error.
  Future<IdentificationResult> identify(String imagePath);
}

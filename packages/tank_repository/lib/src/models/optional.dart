/// A wrapper to distinguish between "not provided" and an explicit value
/// (including null) in `copyWith` methods.
///
/// ```dart
/// entry.copyWith()                                  // don't change
/// entry.copyWith(scientificName: Optional(null))     // clear it
/// entry.copyWith(scientificName: Optional('Danio'))  // set it
/// ```
class Optional<T> {
  /// Creates an [Optional] wrapping [value].
  const Optional(this.value);

  /// The wrapped value, which may be null.
  final T value;
}

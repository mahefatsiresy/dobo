/// A pond or batch code already used on this site.
class DuplicateCodeException implements Exception {
  const DuplicateCodeException(this.code);

  final String code;

  @override
  String toString() => 'DuplicateCodeException: $code';
}

/// Fish must not leave an isolated pond (DOMAIN §Health).
class PondIsolatedException implements Exception {
  const PondIsolatedException(this.pondId);

  final String pondId;

  @override
  String toString() => 'PondIsolatedException: $pondId';
}

/// Codes match whatever the case and surrounding spaces.
String normaliseCode(String code) => code.trim().toLowerCase();

/// The record was already corrected or deleted (a double tap, or another
/// phone): only the current version may be superseded.
class StaleEventException implements Exception {
  const StaleEventException(this.id);

  final String id;

  @override
  String toString() => 'StaleEventException: $id';
}

/// A pond still holding fish can't be archived: they would be unreachable.
class PondNotEmptyException implements Exception {
  const PondNotEmptyException(this.pondId);

  final String pondId;

  @override
  String toString() => 'PondNotEmptyException: $pondId';
}

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

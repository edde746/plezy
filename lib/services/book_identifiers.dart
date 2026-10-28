/// Normalized book edition identifiers used for precise storefront searches.
/// Invalid values are ignored; an unverified identifier must never replace a
/// title search or be presented as an edition match.
abstract final class BookIdentifiers {
  static String? normalize(Object? value) {
    if (value is! String || value.length > 128) return null;
    final withoutPrefix = value.trim().replaceFirst(
      RegExp(r'^(?:urn:)?isbn(?:[\s-]?1[03])?[\s:]*', caseSensitive: false),
      '',
    );
    final isbn = withoutPrefix.replaceAll(RegExp(r'[\s\-\u2010-\u2015]'), '').toUpperCase();
    if (RegExp(r'^[0-9]{9}[0-9X]$').hasMatch(isbn)) {
      var checksum = 0;
      for (var index = 0; index < isbn.length; index++) {
        final digit = isbn[index] == 'X' ? 10 : int.parse(isbn[index]);
        checksum += (10 - index) * digit;
      }
      return checksum % 11 == 0 ? isbn : null;
    }
    if (RegExp(r'^97[89][0-9]{10}$').hasMatch(isbn)) {
      var checksum = 0;
      for (var index = 0; index < 12; index++) {
        checksum += int.parse(isbn[index]) * (index.isEven ? 1 : 3);
      }
      final checkDigit = (10 - checksum % 10) % 10;
      return checkDigit == int.parse(isbn[12]) ? isbn : null;
    }
    return null;
  }

  /// Reads common Open Library, Google Books, OPDS and identifier-map shapes.
  static Map<String, String> fromValues(Object? value) {
    final result = <String, String>{};

    void add(Object? candidate) {
      final normalized = normalize(candidate);
      if (normalized == null) return;
      final key = normalized.length == 13 ? 'isbn13' : 'isbn10';
      result.putIfAbsent(key, () => normalized);
    }

    void read(Object? candidate) {
      if (candidate is Map) {
        final normalizedKeys = candidate.keys.map((key) => '$key'.toLowerCase()).toSet();
        if (normalizedKeys.contains('identifier') || normalizedKeys.contains('value')) {
          add(candidate['identifier'] ?? candidate['value'] ?? candidate['id']);
        } else {
          for (final entry in candidate.entries) {
            if ('${entry.key}'.toLowerCase().contains('isbn')) add(entry.value);
          }
          if (!result.containsKey('isbn13') && !result.containsKey('isbn10') && normalizedKeys.contains('id')) {
            add(candidate['id']);
          }
        }
      } else if (candidate is Iterable) {
        for (final value in candidate) {
          read(value);
        }
      } else {
        add(candidate);
      }
    }

    read(value);
    return Map.unmodifiable(result);
  }

  static String? preferred(Map<String, String> identifiers) {
    final normalized = fromValues(identifiers);
    return normalized['isbn13'] ?? normalized['isbn10'];
  }
}

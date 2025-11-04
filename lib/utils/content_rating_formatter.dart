/// Utility function to format content ratings by removing country prefixes
String formatContentRating(String? contentRating) {
  if (contentRating == null || contentRating.isEmpty) {
    return '';
  }

  // Remove common country prefixes like "gb/", "us/", "de/", etc.
  // The pattern matches: lowercase letters followed by a forward slash
  final regex = RegExp(r'^[a-z]{2,3}/(.+)$', caseSensitive: false);
  final match = regex.firstMatch(contentRating);

  if (match != null && match.groupCount >= 1) {
    return match.group(1) ?? contentRating;
  }

  return contentRating;
}

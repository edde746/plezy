import 'dart:convert';

/// Profile-private Plex fields that must never cross an ownerless metadata
/// namespace. Plex may place these at any depth in a metadata response.
const plexProfilePrivateMetadataFields = {
  'lastRatedAt',
  'lastViewedAt',
  'skipCount',
  'userRating',
  'viewCount',
  'viewOffset',
  'viewedLeafCount',
};

/// Returns an in-memory Plex payload safe to retain while a download has no
/// profile owner.
Map<String, dynamic> sanitizePlexMetadataMapForOwnerlessTransfer(Map<String, dynamic> source) {
  Object? scrub(Object? value) {
    if (value is Map<String, dynamic>) {
      return <String, dynamic>{
        for (final entry in value.entries)
          if (!plexProfilePrivateMetadataFields.contains(entry.key)) entry.key: scrub(entry.value),
      };
    }
    if (value is List) return <Object?>[for (final item in value) scrub(item)];
    return value;
  }

  return scrub(source)! as Map<String, dynamic>;
}

/// Returns a persisted cache payload safe to retain while a legacy download
/// has no profile owner. Invalid/non-object payloads are rejected rather than
/// copied into the adoptable transfer namespace.
String sanitizePlexMetadataForOwnerlessTransfer(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Invalid Plex metadata cache payload');
  }
  return jsonEncode(sanitizePlexMetadataMapForOwnerlessTransfer(decoded));
}

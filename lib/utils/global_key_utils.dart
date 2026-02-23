/// Builds a globalKey string from [serverId] and [ratingKey].
String buildGlobalKey(String serverId, String ratingKey) => '$serverId:$ratingKey';

/// Parses a globalKey string (format: "serverId:ratingKey") into its components.
///
/// Returns `null` if the key does not contain a colon separator.
/// Uses [indexOf] so ratingKeys containing colons are handled correctly.
({String serverId, String ratingKey})? parseGlobalKey(String globalKey) {
  final idx = globalKey.indexOf(':');
  if (idx < 0) return null;
  return (serverId: globalKey.substring(0, idx), ratingKey: globalKey.substring(idx + 1));
}

/// Returns a normalized relative folder for durable sync state, or `null` if
/// the value is empty, aliases its parent/root, or can be decoded into a path
/// separator or traversal segment.
String? normalizeSyncFolder(String? value) {
  if (value == null) return null;
  var path = value.trim();
  if (path.isEmpty || path.startsWith('/') || path.contains('\\')) return null;

  if (path.endsWith('/')) path = path.substring(0, path.length - 1);
  if (path.isEmpty || path.endsWith('/')) return null;

  final segments = <String>[];
  for (final rawSegment in path.split('/')) {
    if (rawSegment.isEmpty) return null;
    var segment = rawSegment;
    for (var attempt = 0; attempt < 8; attempt++) {
      final String decoded;
      try {
        decoded = Uri.decodeComponent(segment);
      } on FormatException {
        return null;
      } on ArgumentError {
        return null;
      }
      if (decoded == segment) break;
      segment = decoded;
      if (segment.isEmpty || segment == '.' || segment == '..' || segment.contains('/') || segment.contains('\\')) {
        return null;
      }
      if (attempt == 7) return null;
    }
    if (segment == '.' || segment == '..' || segment.contains('/') || segment.contains('\\')) return null;
    segments.add(segment);
  }
  return segments.join('/');
}

/// Encodes each already-validated folder segment as a path segment, so names
/// containing URI punctuation cannot turn a relative folder into a URL.
String encodeSyncFolderPath(String folder) => folder.split('/').map(Uri.encodeComponent).join('/');

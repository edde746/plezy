/// Packs [filename] and [uri] into a single String
///
/// use [unpack] to retrieve the filename and uri from the packed String
String pack(String filename, Uri uri) =>
    ':::$filename::::::${uri.toString()}:::';

/// Unpacks [packedString] into a (filename, uri). If this is not a packed
/// string, returns the original [packedString] as (filename and null) or,
/// if it is a Uri as (null and the uri)
({String? filename, Uri? uri}) unpack(String packedString) {
  final regex = RegExp(r':::([\s\S]*?)::::::([\s\S]*?):::');
  final match = regex.firstMatch(packedString);

  if (match != null && match.groupCount == 2) {
    final filename = match.group(1)!;
    final uriString = match.group(2)!;
    final uri = Uri.tryParse(uriString);
    return (filename: filename, uri: uri?.hasScheme == true ? uri : null);
  } else {
    final uri = Uri.tryParse(packedString);
    if (uri?.hasScheme == true) {
      return (filename: null, uri: uri);
    }
    return (filename: packedString, uri: null);
  }
}

/// Returns the Uri represented by [maybePacked], or null if the String is not a
/// valid Uri or packed Uri string.
///
/// [maybePacked] should be a full Uri string, or a packed String containing
/// a Uri (see [pack])
Uri? uriFromStringValue(String maybePacked) {
  final (:filename, :uri) = unpack(maybePacked);
  return uri;
}

/// Returns true if [maybePacked] is a valid Uri or packed Uri string.
///
/// [maybePacked] should be a full Uri string, or a packed String containing
/// a Uri (see [pack])
bool containsUri(String maybePacked) => uriFromStringValue(maybePacked) != null;

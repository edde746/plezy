/// Set to `true` to blur all artwork (for store screenshots).
const kBlurArtwork = false;

/// Rotates vowels (a→e, e→i, i→o, o→u, u→a) when [kBlurArtwork] is `true`.
String obfuscateText(String text) {
  if (!kBlurArtwork) return text;
  const from = 'aeiouAEIOU';
  const to = 'eiouaEIOUA';
  final buf = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final idx = from.indexOf(text[i]);
    buf.write(idx >= 0 ? to[idx] : text[i]);
  }
  return buf.toString();
}

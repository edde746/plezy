import '../media/lyrics.dart';

/// Matches `[mm:ss]`, `[mm:ss.x]`, `[mm:ss.xx]`, `[mm:ss.xxx]` timestamps
/// (multiple per line allowed, per the LRC spec).
final RegExp _timestamp = RegExp(r'\[(\d{1,3}):(\d{1,2})(?:\.(\d{1,3}))?\]');

/// Metadata/ID tags like `[ar:Artist]`, `[offset:+120]`.
final RegExp _idTag = RegExp(r'^\[([a-zA-Z#]+):(.*)\]$');

/// Parse LRC content into [Lyrics]. Lines with `[mm:ss.xx]` timestamps become
/// synced lines (a line with multiple timestamps is emitted once per
/// timestamp); the `[offset:±ms]` tag is applied. Input with no timestamps at
/// all falls back to unsynced plain text. Returns `null` for blank input.
Lyrics? parseLrc(String raw) {
  final lines = <LyricLine>[];
  final plain = <String>[];
  var offsetMs = 0;

  for (final rawLine in raw.split(RegExp(r'\r?\n'))) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;

    final idTag = _idTag.firstMatch(line);
    if (idTag != null && !_timestamp.hasMatch(line)) {
      if (idTag.group(1)!.toLowerCase() == 'offset') {
        offsetMs = int.tryParse(idTag.group(2)!.trim()) ?? 0;
      }
      continue;
    }

    final stamps = _timestamp.allMatches(line).toList();
    if (stamps.isEmpty) {
      plain.add(line);
      continue;
    }

    final text = line.substring(stamps.last.end).trim();
    for (final m in stamps) {
      final minutes = int.parse(m.group(1)!);
      final seconds = int.parse(m.group(2)!);
      // Fractional part scales by digit count: ".5" = 500ms, ".50" = 500ms.
      final frac = m.group(3);
      final fracMs = frac == null ? 0 : (int.parse(frac) * 1000 ~/ _pow10(frac.length)).clamp(0, 999);
      final startMs = (minutes * 60 + seconds) * 1000 + fracMs - offsetMs;
      lines.add(LyricLine(text: text, startMs: startMs < 0 ? 0 : startMs));
    }
  }

  if (lines.isNotEmpty) {
    lines.sort((a, b) => a.startMs!.compareTo(b.startMs!));
    return Lyrics(synced: true, lines: lines);
  }
  if (plain.isNotEmpty) {
    return Lyrics(synced: false, lines: [for (final t in plain) LyricLine(text: t)]);
  }
  return null;
}

int _pow10(int n) => switch (n) {
  1 => 10,
  2 => 100,
  _ => 1000,
};

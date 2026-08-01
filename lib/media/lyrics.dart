/// One lyric line. [startMs] is the offset from track start, `null` when the
/// source is unsynced plain text.
class LyricLine {
  final String text;
  final int? startMs;

  const LyricLine({required this.text, this.startMs});
}

/// Track lyrics as returned by [MediaServerClient.fetchLyrics].
///
/// [synced] is true when (enough) lines carry [LyricLine.startMs] for the
/// player to highlight/scroll along with playback. Jellyfin's `LyricDto`
/// omits its `IsSynced` flag on some server versions, so implementations
/// infer synced-ness from the presence of per-line offsets.
class Lyrics {
  final bool synced;
  final List<LyricLine> lines;

  const Lyrics({required this.synced, required this.lines});

  bool get isEmpty => lines.isEmpty;
}

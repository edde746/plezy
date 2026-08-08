/// Parsers for deriving the segmented-subtitle timeline offset of a Plex HLS
/// transcode from the stream itself (#1738).
///
/// Plex's transcoder starts the HLS presentation clock at a non-zero MPEG-TS
/// PTS and declares the mapping in each WebVTT segment's `X-TIMESTAMP-MAP`
/// header. ffmpeg's HLS demuxer never applies that map — `webvttdec.c` passes
/// cue times straight through as packet timestamps and `hls.c` offers no
/// option to compensate — so segmented cues reach mpv early by exactly the
/// declared offset. The player closes the gap via `sub-delay`; these parsers
/// recover the declared value so the compensation follows what the server
/// actually emits instead of assuming Plex's historical 10s constant.
library;

/// URI of the first `TYPE=SUBTITLES` rendition in an HLS master playlist, or
/// null when the playlist declares none (or [masterPlaylist] is not an HLS
/// playlist at all).
String? hlsSubtitleRenditionUri(String masterPlaylist) {
  for (final line in masterPlaylist.split('\n')) {
    final trimmed = line.trim();
    if (!trimmed.startsWith('#EXT-X-MEDIA:') || !trimmed.contains('TYPE=SUBTITLES')) continue;
    final uri = RegExp(r'URI="([^"]+)"').firstMatch(trimmed);
    if (uri != null) return uri.group(1);
  }
  return null;
}

/// URIs of the media segments in an HLS media playlist, in order.
List<String> hlsSegmentUris(String mediaPlaylist) {
  final uris = <String>[];
  for (final line in mediaPlaylist.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isNotEmpty && !trimmed.startsWith('#')) uris.add(trimmed);
  }
  return uris;
}

/// Cue-to-presentation offset in milliseconds declared by a WebVTT segment's
/// `X-TIMESTAMP-MAP` header: `MPEGTS ÷ 90 − LOCAL` (the MPEG-TS clock runs at
/// 90 kHz). Returns null when the segment declares no parseable map — which
/// includes the bare `WEBVTT` stubs Plex serves for cue-less segments. A stub
/// carries no timing evidence either way, so callers must keep looking rather
/// than read it as "no offset".
int? webVttTimestampMapOffsetMs(String segment) {
  final body = segment.trimLeft();
  if (!body.startsWith('WEBVTT')) return null;
  final map = RegExp(r'X-TIMESTAMP-MAP=([^\r\n]+)').firstMatch(body);
  if (map == null) return null;
  final attributes = map.group(1)!;
  final mpegTs = RegExp(r'MPEGTS:(\d+)').firstMatch(attributes);
  final local = RegExp(r'LOCAL:([\d:.]+)').firstMatch(attributes);
  if (mpegTs == null || local == null) return null;
  final localMs = _webVttTimestampMs(local.group(1)!);
  if (localMs == null) return null;
  return (int.parse(mpegTs.group(1)!) / 90).round() - localMs;
}

/// Milliseconds for a WebVTT timestamp (`HH:MM:SS.mmm` or `MM:SS.mmm`).
int? _webVttTimestampMs(String value) {
  final match = RegExp(r'^(?:(\d+):)?(\d{1,2}):(\d{1,2})\.(\d{3})$').firstMatch(value);
  if (match == null) return null;
  final hours = int.parse(match.group(1) ?? '0');
  final minutes = int.parse(match.group(2)!);
  final seconds = int.parse(match.group(3)!);
  final millis = int.parse(match.group(4)!);
  if (minutes > 59 || seconds > 59) return null;
  return ((hours * 60 + minutes) * 60 + seconds) * 1000 + millis;
}

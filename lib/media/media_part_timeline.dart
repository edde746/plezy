import 'media_part.dart';

/// One file's span on the timeline of an item stacked across several files.
class MediaPartSpan {
  const MediaPartSpan({required this.partId, required this.start, required this.duration});

  /// Backend part id ([MediaPart.id]).
  final String partId;

  /// Where this file begins on the item's timeline.
  final Duration start;

  final Duration duration;

  Duration get end => start + duration;
}

/// The timeline of an item stacked across several files — Plex's
/// `Movie - Part 1.mkv`, `Movie - Part 2.mkv` — and which of them is open.
///
/// Everything above the player speaks item time: resume offsets, progress
/// reports, markers, chapters and the seek bar all cover the whole item. Only
/// the open file is part-relative, and the player translates at its own
/// boundary (`Player.open`'s `timelineOffset`). Reaching the end of a file
/// that is not the last, or seeking outside it, opens the file that holds the
/// target instead.
class MediaPartTimeline {
  const MediaPartTimeline._(this.parts, this.currentIndex);

  /// The timeline of one version's [parts] with [currentIndex] open.
  ///
  /// Null for a single-file version, and when any part lacks a duration:
  /// without every boundary, item time cannot be mapped onto the files.
  static MediaPartTimeline? fromParts(List<MediaPart> parts, {int currentIndex = 0}) {
    if (parts.length < 2 || currentIndex < 0 || currentIndex >= parts.length) return null;
    final spans = <MediaPartSpan>[];
    var start = Duration.zero;
    for (final part in parts) {
      final durationMs = part.durationMs;
      if (durationMs == null || durationMs <= 0) return null;
      final duration = Duration(milliseconds: durationMs);
      spans.add(MediaPartSpan(partId: part.id, start: start, duration: duration));
      start += duration;
    }
    return MediaPartTimeline._(List.unmodifiable(spans), currentIndex);
  }

  final List<MediaPartSpan> parts;
  final int currentIndex;

  MediaPartSpan get current => parts[currentIndex];

  /// The whole item: every file back to back.
  Duration get duration => parts.last.end;

  bool get hasNext => currentIndex < parts.length - 1;

  /// The file holding [position]. Positions before the item belong to the
  /// first file and positions past its end to the last.
  int indexAt(Duration position) {
    for (var i = 0; i < parts.length - 1; i++) {
      if (position < parts[i].end) return i;
    }
    return parts.length - 1;
  }

  /// Whether the open file plays [position] without another file opening.
  bool covers(Duration position) => indexAt(position) == currentIndex;
}

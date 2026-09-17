import '../models/livetv_program.dart';

/// Epoch values in this file are UTC seconds (including fractional seconds).
/// Player durations and backend-relative offsets must be converted by the
/// session adapter. No timeline arithmetic reads the device wall clock.
enum LiveTvTimeAccuracy { unknown, estimated, confirmed, stale }

enum LiveTvSeekStatus { idle, pending, opening, failed }

enum LiveTvTimelineMode {
  seekPreview,
  playbackProgram,
  estimatedPlaybackProgram,
  lastKnownPlaybackProgram,
  liveProgramFallback,
  buffer,
  unavailable,
}

class LiveTvPlaybackPosition {
  final double? epoch;
  final LiveTvTimeAccuracy accuracy;
  final bool active;

  const LiveTvPlaybackPosition({this.epoch, this.accuracy = LiveTvTimeAccuracy.unknown, this.active = false});

  double? get confirmedEpoch => active && accuracy == LiveTvTimeAccuracy.confirmed ? epoch : null;
}

/// Inclusive playable targets on a backend-supplied grid. The backend must
/// already have excluded restricted endpoints (e.g. Plex's unfinished edge).
/// [startEpoch] anchors the grid, which need not coincide with whole epochs.
class LiveTvSeekWindow {
  final double startEpoch;
  final double endEpoch;
  final double stepSeconds;

  const LiveTvSeekWindow({required this.startEpoch, required this.endEpoch, this.stepSeconds = 1});

  bool get isValid =>
      startEpoch.isFinite && endEpoch.isFinite && stepSeconds.isFinite && stepSeconds > 0 && startEpoch <= endEpoch;

  double? target(double epoch) => targetWithin(epoch, startEpoch, endEpoch, endExclusive: false);

  /// Restrict scrubbing to a displayed half-open program interval, while
  /// preserving the backend grid and its inclusive last playable target.
  double? targetWithin(double epoch, double start, double end, {bool endExclusive = true}) {
    if (!isValid || !epoch.isFinite || !start.isFinite || !end.isFinite) return null;
    final first = ((start - startEpoch) / stepSeconds).ceil().clamp(0, 1 << 53);
    final windowLast = ((endEpoch - startEpoch) / stepSeconds).floor();
    final last =
        (endExclusive ? ((end - startEpoch) / stepSeconds).ceil() - 1 : ((end - startEpoch) / stepSeconds).floor())
            .clamp(-1, windowLast);
    if (first > last) return null;
    final index = ((epoch - startEpoch) / stepSeconds).round().clamp(first, last);
    return startEpoch + index * stepSeconds;
  }
}

/// One presentation snapshot, shared by all Live TV controls. Remote/keyboard
/// previews can select a displayed program without replacing [playback]. Active
/// estimates may select guide metadata without becoming confirmed playback. Last-known
/// positions preserve program context while a source opens or has failed.
/// Stale schedule data is retained for live fallback display only.
class LiveTvTimeline {
  final LiveTvPlaybackPosition playback;
  final LiveTvSeekWindow? seekable;
  final double? liveEdgeEpoch;
  final LiveTvTimeAccuracy liveEdgeAccuracy;
  final double? pendingSeekEpoch;
  final double? programPreviewEpoch;
  final LiveTvSeekStatus seekStatus;
  final LiveTvProgram? program;
  final LiveTvTimelineMode mode;
  final bool programDataStale;
  final double? startEpoch;
  final double? endEpoch;

  const LiveTvTimeline._({
    required this.playback,
    required this.seekable,
    required this.liveEdgeEpoch,
    required this.liveEdgeAccuracy,
    required this.pendingSeekEpoch,
    required this.programPreviewEpoch,
    required this.seekStatus,
    required this.program,
    required this.mode,
    required this.programDataStale,
    required this.startEpoch,
    required this.endEpoch,
  });

  factory LiveTvTimeline.resolve({
    required LiveTvPlaybackPosition playback,
    LiveTvSeekWindow? seekable,
    double? liveEdgeEpoch,
    LiveTvTimeAccuracy liveEdgeAccuracy = LiveTvTimeAccuracy.unknown,
    double? pendingSeekEpoch,
    double? programPreviewEpoch,
    LiveTvSeekStatus seekStatus = LiveTvSeekStatus.idle,
    List<LiveTvProgram> programs = const [],
    required double metadataNowEpoch,
    bool programDataStale = false,
  }) {
    final epoch = playback.epoch;
    final canSelectPlayback =
        epoch != null &&
        epoch.isFinite &&
        ((playback.active &&
                (playback.accuracy == LiveTvTimeAccuracy.confirmed ||
                    playback.accuracy == LiveTvTimeAccuracy.estimated)) ||
            playback.accuracy == LiveTvTimeAccuracy.stale);
    final playing = !canSelectPlayback || programDataStale ? null : programAt(programs, epoch);
    final preview = programPreviewEpoch?.isFinite == true ? programPreviewEpoch : null;
    // Unknown preview airings use the whole buffer instead of leaving the
    // destination outside the old program. Do not invent guide metadata.
    final selected = preview != null
        ? (programDataStale ? null : programAt(programs, preview))
        : playing ?? programAt(programs, metadataNowEpoch);
    final window = seekable?.isValid == true ? seekable : null;
    final mode = preview != null
        ? (selected != null
              ? LiveTvTimelineMode.seekPreview
              : window != null
              ? LiveTvTimelineMode.buffer
              : LiveTvTimelineMode.unavailable)
        : playing != null
        ? switch (playback.accuracy) {
            LiveTvTimeAccuracy.confirmed => LiveTvTimelineMode.playbackProgram,
            LiveTvTimeAccuracy.estimated => LiveTvTimelineMode.estimatedPlaybackProgram,
            _ => LiveTvTimelineMode.lastKnownPlaybackProgram,
          }
        : selected != null
        ? LiveTvTimelineMode.liveProgramFallback
        : window != null
        ? LiveTvTimelineMode.buffer
        : LiveTvTimelineMode.unavailable;
    return LiveTvTimeline._(
      playback: playback,
      seekable: window,
      liveEdgeEpoch: liveEdgeEpoch,
      liveEdgeAccuracy: liveEdgeAccuracy,
      pendingSeekEpoch: pendingSeekEpoch,
      programPreviewEpoch: preview,
      seekStatus: seekStatus,
      program: selected,
      mode: mode,
      programDataStale: programDataStale,
      startEpoch: selected?.beginsAt?.toDouble() ?? window?.startEpoch,
      endEpoch: selected?.endsAt?.toDouble() ?? window?.endEpoch,
    );
  }

  /// Half-open selection. Overlaps prefer the latest start, then earliest
  /// end, then stable program identity/title. Invalid bounds are ignored.
  static LiveTvProgram? programAt(Iterable<LiveTvProgram> programs, double epoch) {
    final matches = programs
        .where(
          (p) =>
              p.beginsAt != null &&
              p.endsAt != null &&
              p.beginsAt! < p.endsAt! &&
              p.beginsAt! <= epoch &&
              epoch < p.endsAt!,
        )
        .toList();
    matches.sort((a, b) {
      var order = b.beginsAt!.compareTo(a.beginsAt!);
      if (order != 0) return order;
      order = a.endsAt!.compareTo(b.endsAt!);
      if (order != 0) return order;
      return '${a.ratingKey ?? a.key ?? a.guid ?? ''}:${a.title}'.compareTo(
        '${b.ratingKey ?? b.key ?? b.guid ?? ''}:${b.title}',
      );
    });
    return matches.firstOrNull;
  }

  bool get hasRange => startEpoch != null && endEpoch != null && startEpoch! < endEpoch!;
  bool contains(double epoch) =>
      hasRange && epoch >= startEpoch! && (program == null ? epoch <= endEpoch! : epoch < endEpoch!);
  bool get playbackOutOfWindow => playback.epoch != null && !contains(playback.epoch!);
  double? get confirmedPlayheadEpoch =>
      playback.confirmedEpoch != null && contains(playback.confirmedEpoch!) ? playback.confirmedEpoch : null;
  double? get estimatedPlayheadEpoch =>
      playback.active &&
          playback.accuracy == LiveTvTimeAccuracy.estimated &&
          playback.epoch != null &&
          contains(playback.epoch!)
      ? playback.epoch
      : null;

  double? get visibleSeekStart => _intersection?.$1;
  double? get visibleSeekEnd => _intersection?.$2;
  (double, double)? get _intersection {
    final window = seekable;
    if (!hasRange || window == null) return null;
    final start = startEpoch! > window.startEpoch ? startEpoch! : window.startEpoch;
    final end = endEpoch! < window.endEpoch ? endEpoch! : window.endEpoch;
    return start < end ? (start, end) : null;
  }

  double? scrubTarget(double epoch) =>
      hasRange ? seekable?.targetWithin(epoch, startEpoch!, endEpoch!, endExclusive: program != null) : null;

  /// Retains Plezy's 15s live-edge tolerance for active playback with fresh
  /// timing evidence. This UI status does not promote an estimated broadcast
  /// clock to confirmed accuracy, and pending targets never establish it.
  bool get isAtLive =>
      playback.active &&
      (playback.accuracy == LiveTvTimeAccuracy.confirmed || playback.accuracy == LiveTvTimeAccuracy.estimated) &&
      playback.epoch?.isFinite == true &&
      liveEdgeEpoch?.isFinite == true &&
      liveEdgeAccuracy != LiveTvTimeAccuracy.unknown &&
      liveEdgeAccuracy != LiveTvTimeAccuracy.stale &&
      (playback.epoch! - liveEdgeEpoch!).abs() <= 15;
}

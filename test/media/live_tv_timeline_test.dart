import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/live_tv_timeline.dart';
import 'package:plezy/models/livetv_program.dart';

void main() {
  final a = LiveTvProgram(title: 'A', beginsAt: 7200, endsAt: 10800);
  final b = LiveTvProgram(title: 'B', beginsAt: 10800, endsAt: 14400);
  const buffer = LiveTvSeekWindow(startEpoch: 9000, endEpoch: 12600);
  LiveTvTimeline timeline(
    double? epoch, {
    double? pending,
    double? preview,
    List<LiveTvProgram>? programs,
    LiveTvTimeAccuracy accuracy = LiveTvTimeAccuracy.confirmed,
    bool stale = false,
    bool active = true,
    LiveTvTimeAccuracy edgeAccuracy = LiveTvTimeAccuracy.estimated,
    LiveTvSeekWindow? window = buffer,
  }) => LiveTvTimeline.resolve(
    playback: LiveTvPlaybackPosition(epoch: epoch, accuracy: accuracy, active: active && epoch != null),
    programs: programs ?? [a, b],
    metadataNowEpoch: 12600,
    seekable: window,
    pendingSeekEpoch: pending,
    programPreviewEpoch: preview,
    programDataStale: stale,
    liveEdgeEpoch: 12600.5,
    liveEdgeAccuracy: edgeAccuracy,
  );

  test('rewind and forward progression select the half-open playback program', () {
    expect(timeline(10920).program, same(b));
    expect(timeline(10620).program, same(a));
    expect(timeline(10799.999).program, same(a));
    expect(timeline(10800).program, same(b));
    expect(timeline(10920, pending: 10620).program, same(b));
    expect(timeline(10920, pending: 10620).confirmedPlayheadEpoch, 10920);
  });

  test('remote program preview crosses boundaries without moving the playback clock', () {
    final view = timeline(10920, pending: 10620, preview: 10620);
    expect(view.program, same(a));
    expect(view.mode, LiveTvTimelineMode.seekPreview);
    expect(view.playback.confirmedEpoch, 10920);
    expect((view.startEpoch, view.endEpoch), (7200, 10800));
    expect(timeline(10920, preview: 10800).program, same(b));
    // Mouse/ordinary pending seeks do not request program preview.
    expect(timeline(10920, pending: 10620).program, same(b));
    expect(timeline(10920, pending: 12600, preview: 12600).isAtLive, isFalse);
  });

  test('missing or stale preview guide data keeps the destination visible on the buffer', () {
    for (final view in [
      timeline(10920, pending: 10000, preview: 10000, programs: [b]),
      timeline(10920, pending: 10000, preview: 10000, stale: true),
    ]) {
      expect(view.program, isNull);
      expect(view.mode, LiveTvTimelineMode.buffer);
      expect((view.startEpoch, view.endEpoch), (9000, 12600));
      expect(view.contains(10000), isTrue);
      expect(view.playback.epoch, 10920);
    }
  });

  test('whole schedule and seekable intersection differ when joining midway', () {
    final view = timeline(10000);
    expect((view.startEpoch, view.endEpoch), (7200, 10800));
    expect((view.visibleSeekStart, view.visibleSeekEnd), (9000, 10800));
    expect(view.scrubTarget(7200), 9000);
    expect(view.scrubTarget(10800), 10799);
    expect(timeline(10920).seekable!.target(10920 - 300), 10620);
  });

  test('fallback metadata never pins an out-of-window confirmed playhead', () {
    final fallback = timeline(10000, programs: [b]);
    expect(fallback.mode, LiveTvTimelineMode.liveProgramFallback);
    expect(fallback.playbackOutOfWindow, isTrue);
    expect(fallback.confirmedPlayheadEpoch, isNull);
    expect(fallback.seekable!.target(10000), 10000);
    expect(timeline(10000, programs: []).mode, LiveTvTimelineMode.buffer);
    expect(timeline(null, programs: [], window: null).mode, LiveTvTimelineMode.unavailable);
  });

  test('active estimates select historical guide metadata without confirming playback', () {
    final estimated = timeline(10000, accuracy: LiveTvTimeAccuracy.estimated);
    expect(estimated.mode, LiveTvTimelineMode.estimatedPlaybackProgram);
    expect(estimated.program, same(a));
    expect((estimated.startEpoch, estimated.endEpoch), (7200, 10800));
    expect(estimated.estimatedPlayheadEpoch, 10000);
    expect(estimated.confirmedPlayheadEpoch, isNull);
    expect(estimated.playback.accuracy, LiveTvTimeAccuracy.estimated);
    expect(estimated.isAtLive, isFalse);
    expect(timeline(10799.999, accuracy: LiveTvTimeAccuracy.estimated).program, same(a));
    expect(timeline(10800, accuracy: LiveTvTimeAccuracy.estimated).program, same(b));
    expect(timeline(10920, pending: 10000, accuracy: LiveTvTimeAccuracy.estimated).program, same(b));
  });

  test('last-known program stays in place during reopen and never paints an active playhead', () {
    final opening = timeline(10000, accuracy: LiveTvTimeAccuracy.stale, active: false, pending: 12000);
    expect(opening.mode, LiveTvTimelineMode.lastKnownPlaybackProgram);
    expect(opening.program, same(a));
    expect(opening.confirmedPlayheadEpoch, isNull);
    expect(opening.estimatedPlayheadEpoch, isNull);
    expect(opening.playback.active, isFalse);
  });

  test('unknown positions, inactive estimates and stale guide data still fall back', () {
    expect(timeline(10000, accuracy: LiveTvTimeAccuracy.unknown).mode, LiveTvTimelineMode.liveProgramFallback);
    expect(
      timeline(10000, accuracy: LiveTvTimeAccuracy.estimated, active: false).mode,
      LiveTvTimelineMode.liveProgramFallback,
    );
    expect(timeline(10000, stale: true).mode, LiveTvTimelineMode.liveProgramFallback);
    expect(
      timeline(10000, stale: true, accuracy: LiveTvTimeAccuracy.estimated).mode,
      LiveTvTimelineMode.liveProgramFallback,
    );
    final stale = timeline(12000, accuracy: LiveTvTimeAccuracy.stale, active: false);
    expect(stale.estimatedPlayheadEpoch, isNull);
    expect(stale.confirmedPlayheadEpoch, isNull);
  });

  test('gaps, invalid bounds and overlaps resolve deterministically', () {
    final overlap = LiveTvProgram(title: 'Overlap', beginsAt: 10000, endsAt: 10700);
    final invalid = LiveTvProgram(title: 'Invalid', beginsAt: 11000, endsAt: 10000);
    expect(LiveTvTimeline.programAt([a, overlap, invalid], 10500), same(overlap));
    expect(LiveTvTimeline.programAt([invalid, overlap, a], 10500), same(overlap));
    expect(LiveTvTimeline.programAt([a, b], 14400), isNull);
    expect(LiveTvTimeline.programAt([a, b], 7000), isNull);
  });

  test('empty intersection disables scrub without disabling full buffer targets', () {
    final view = timeline(10000, window: const LiveTvSeekWindow(startEpoch: 11000, endEpoch: 12000));
    expect(view.visibleSeekStart, isNull);
    expect(view.visibleSeekEnd, isNull);
    expect(view.scrubTarget(10000), isNull);
    expect(view.seekable!.target(10000), 11000);
  });

  test('fractional backend grid never selects program exclusive endpoint', () {
    const window = LiveTvSeekWindow(startEpoch: 1000.25, endEpoch: 1010.25);
    expect(window.targetWithin(1007, 1004.1, 1007.25), 1006.25);
    expect(window.targetWithin(1007, 1006.5, 1007.1), isNull);
    expect(window.target(-100), 1000.25);
    expect(window.target(double.nan), isNull);
    expect(const LiveTvSeekWindow(startEpoch: 2, endEpoch: 1).target(1), isNull);
  });

  test('live tolerance accepts active estimates without confirming the clock or following a paused edge', () {
    expect(timeline(12600).isAtLive, isTrue);
    expect(timeline(12585).isAtLive, isFalse);
    final estimated = timeline(12600, accuracy: LiveTvTimeAccuracy.estimated);
    expect(estimated.isAtLive, isTrue);
    expect(estimated.playback.confirmedEpoch, isNull);
    expect(estimated.playback.accuracy, LiveTvTimeAccuracy.estimated);
    final paused = LiveTvTimeline.resolve(
      playback: const LiveTvPlaybackPosition(epoch: 12600, accuracy: LiveTvTimeAccuracy.confirmed, active: true),
      seekable: const LiveTvSeekWindow(startEpoch: 12700, endEpoch: 13000),
      liveEdgeEpoch: 13001,
      liveEdgeAccuracy: LiveTvTimeAccuracy.estimated,
      metadataNowEpoch: 50000,
    );
    expect(paused.playback.confirmedEpoch, 12600);
    expect(paused.isAtLive, isFalse);
    expect(paused.playbackOutOfWindow, isTrue);
  });

  test('LIVE ignores pending targets and requires active fresh finite timing', () {
    expect(timeline(12000, pending: 12600, accuracy: LiveTvTimeAccuracy.estimated).isAtLive, isFalse);
    expect(timeline(12600, active: false).isAtLive, isFalse);
    expect(timeline(12600, accuracy: LiveTvTimeAccuracy.unknown).isAtLive, isFalse);
    expect(timeline(12600, accuracy: LiveTvTimeAccuracy.stale).isAtLive, isFalse);
    expect(timeline(12600, edgeAccuracy: LiveTvTimeAccuracy.stale).isAtLive, isFalse);
    expect(timeline(12600, edgeAccuracy: LiveTvTimeAccuracy.unknown).isAtLive, isFalse);
    expect(timeline(double.nan).isAtLive, isFalse);
    expect(timeline(null).isAtLive, isFalse);
  });
}

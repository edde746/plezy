import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/models.dart';
import 'package:plezy/screens/video_player/playback_failure_action.dart';

PlaybackFailureAction resolve({
  String? cause,
  Set<int> statuses = const <int>{},
  bool isLive = false,
  bool liveRetrying = false,
  int liveFallbackLevel = 0,
  bool liveRetryFailed = false,
}) {
  return resolvePlaybackFailureAction(
    cause: cause,
    fatalHttpStatuses: statuses,
    isLive: isLive,
    liveRetrying: liveRetrying,
    liveFallbackLevel: liveFallbackLevel,
    liveRetryFailed: liveRetryFailed,
  );
}

void main() {
  group('HTTP 404', () {
    test('on-demand playback treats it as terminal', () {
      // The file behind the item is unreadable server-side (#1750); no retry,
      // quality change, or backend switch recovers it.
      expect(resolve(statuses: {404}), PlaybackFailureAction.mediaUnreadableDialog);
      expect(resolve(cause: PlayerError.serverHttp404), PlaybackFailureAction.mediaUnreadableDialog);
    });

    test('live TV rides it out on the fallback ladder instead', () {
      // An HLS segment that rolled off the playlist, or a transcode session
      // restarting, answers 404 mid-stream. Showing "file unavailable" there
      // would kill a recoverable stream.
      expect(resolve(statuses: {404}, isLive: true), PlaybackFailureAction.liveRetry);
      expect(resolve(cause: PlayerError.serverHttp404, isLive: true), PlaybackFailureAction.liveRetry);
    });

    test('live TV still exhausts the ladder before giving up', () {
      expect(
        resolve(statuses: {404}, isLive: true, liveFallbackLevel: maxLiveFallbackLevel, liveRetryFailed: true),
        PlaybackFailureAction.liveInterrupted,
      );
    });
  });

  group('HTTP 500', () {
    test('is terminal for on-demand and live alike', () {
      // A bandwidth/transcoding limit rejection is not something a retry
      // clears, so live TV gets the same modal.
      expect(resolve(statuses: {500}), PlaybackFailureAction.serverLimitDialog);
      expect(resolve(statuses: {500}, isLive: true), PlaybackFailureAction.serverLimitDialog);
      expect(resolve(cause: PlayerError.serverHttp500, isLive: true), PlaybackFailureAction.serverLimitDialog);
    });

    test('outranks a 404 latched on the same open', () {
      expect(resolve(statuses: {404, 500}), PlaybackFailureAction.serverLimitDialog);
    });
  });

  group('HTTP 503', () {
    test('the open-phase watchdog tag is terminal for on-demand playback', () {
      // The tag only exists once the watchdog has already waited out the
      // reconnect loop's chances (#1830) — no further retry recovers it.
      expect(resolve(cause: PlayerError.serverHttp503), PlaybackFailureAction.serverBusyDialog);
    });

    test('live TV keeps its fallback ladder', () {
      // The watchdog never arms for live opens, but a defensively passed tag
      // must still ride the ladder rather than kill a recoverable stream.
      expect(resolve(cause: PlayerError.serverHttp503, isLive: true), PlaybackFailureAction.liveRetry);
    });

    test('a latched fatal status outranks the watchdog tag', () {
      // A 500/404 seen on the same open is the more specific diagnosis.
      expect(resolve(cause: PlayerError.serverHttp503, statuses: {500}), PlaybackFailureAction.serverLimitDialog);
      expect(resolve(cause: PlayerError.serverHttp503, statuses: {404}), PlaybackFailureAction.mediaUnreadableDialog);
    });
  });

  group('live fallback ladder', () {
    test('climbs every rung below the bound', () {
      for (var level = 0; level < maxLiveFallbackLevel; level++) {
        expect(resolve(isLive: true, liveFallbackLevel: level), PlaybackFailureAction.liveRetry);
      }
    });

    test('an in-flight retry owns the error', () {
      expect(resolve(isLive: true, liveRetrying: true), PlaybackFailureAction.ignore);
      // Even a latched 404 must not preempt the running retry.
      expect(resolve(statuses: {404}, isLive: true, liveRetrying: true), PlaybackFailureAction.ignore);
    });

    test('a failed last retry reports an interruption', () {
      expect(
        resolve(isLive: true, liveFallbackLevel: maxLiveFallbackLevel, liveRetryFailed: true),
        PlaybackFailureAction.liveInterrupted,
      );
    });

    test('an exhausted ladder that never failed falls through to the raw error', () {
      expect(resolve(isLive: true, liveFallbackLevel: maxLiveFallbackLevel), PlaybackFailureAction.fatal);
    });
  });

  test('an error with no server status is fatal for on-demand playback', () {
    expect(resolve(), PlaybackFailureAction.fatal);
    expect(resolve(statuses: {503}), PlaybackFailureAction.fatal);
    expect(resolve(cause: 'some-decoder-fault'), PlaybackFailureAction.fatal);
  });
}

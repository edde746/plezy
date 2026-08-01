import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/screens/video_player/live_stream_retry.dart';

void main() {
  group('runLiveStreamRetry', () {
    test('reports recover failures and finishes retry state', () async {
      final harness = _RetryHarness(failAt: _Stage.recover);

      expect(await harness.run(), LiveStreamRetryResult.failed);

      expect(harness.failures, hasLength(1));
      expect(harness.finished, isTrue);
      expect(harness.adopted, isFalse);
      expect(harness.discarded, isFalse);
    });

    test('reports stream URL lookup failures and finishes retry state', () async {
      final harness = _RetryHarness(failAt: _Stage.lookup);

      expect(await harness.run(), LiveStreamRetryResult.failed);

      expect(harness.failures, hasLength(1));
      expect(harness.finished, isTrue);
      expect(harness.adopted, isFalse);
      expect(harness.discarded, isTrue);
    });

    test('reports player option failures and finishes retry state', () async {
      final harness = _RetryHarness(failAt: _Stage.options);

      expect(await harness.run(), LiveStreamRetryResult.failed);

      expect(harness.failures, hasLength(1));
      expect(harness.finished, isTrue);
      expect(harness.adopted, isFalse);
      expect(harness.discarded, isTrue);
    });

    test('reports player open failures and finishes retry state', () async {
      final harness = _RetryHarness(failAt: _Stage.open);

      expect(await harness.run(), LiveStreamRetryResult.failed);

      expect(harness.failures, hasLength(1));
      expect(harness.finished, isTrue);
      expect(harness.adopted, isFalse);
      expect(harness.discarded, isTrue);
    });

    test('adopts the recovered session after a successful open', () async {
      final harness = _RetryHarness();

      expect(await harness.run(), LiveStreamRetryResult.succeeded);

      expect(harness.calls, [_Stage.recover, _Stage.lookup, _Stage.options, _Stage.open]);
      expect(harness.failures, isEmpty);
      expect(harness.finished, isTrue);
      expect(harness.adopted, isTrue);
      expect(harness.discarded, isFalse);
    });

    test('stale operation does not report an async failure', () async {
      final harness = _RetryHarness(failAt: _Stage.lookup);
      harness.becomeStaleAt = _Stage.lookup;

      expect(await harness.run(), LiveStreamRetryResult.stale);

      expect(harness.failures, isEmpty);
      expect(harness.finished, isTrue);
      expect(harness.adopted, isFalse);
      expect(harness.discarded, isTrue);
    });
  });
}

enum _Stage { recover, lookup, options, open }

class _RetryHarness {
  _RetryHarness({this.failAt});

  final _Stage? failAt;
  _Stage? becomeStaleAt;
  final calls = <_Stage>[];
  final failures = <Object>[];
  bool current = true;
  bool finished = false;
  bool adopted = false;
  bool discarded = false;

  Future<LiveStreamRetryResult> run() => runLiveStreamRetry<Object>(
    recover: () => _stage(_Stage.recover, Object.new),
    lookupStreamUrl: (_) => _stage(_Stage.lookup, () => 'https://example.com/live'),
    applyPlayerOptions: () => _stage<void>(_Stage.options, () {}),
    open: (_) => _stage<void>(_Stage.open, () {}),
    isCurrent: () => current,
    adoptSession: (_) => adopted = true,
    reportFailure: (error, _) => failures.add(error),
    discardSession: (_) => discarded = true,
    onFinished: () => finished = true,
  );

  Future<T> _stage<T>(_Stage stage, T Function() value) async {
    calls.add(stage);
    if (becomeStaleAt == stage) current = false;
    if (failAt == stage) throw StateError('$stage failed');
    return value();
  }
}

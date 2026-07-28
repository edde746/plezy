import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/screens/video_player/frame_rate_matcher.dart';

void main() {
  test('single suppression window lasts through its configured deadline', () {
    fakeAsync((async) {
      final matcher = FrameRateMatcher();

      matcher.beginSuppressWindow(2);
      expect(matcher.suppressesMediaPause, isTrue);

      async.elapse(const Duration(milliseconds: 4999));
      expect(matcher.suppressesMediaPause, isTrue);

      async.elapse(const Duration(milliseconds: 1));
      expect(matcher.suppressesMediaPause, isFalse);
      matcher.dispose();
    });
  });

  test('overlapping suppression windows remain active until the newest deadline', () {
    fakeAsync((async) {
      final matcher = FrameRateMatcher();

      matcher.beginSuppressWindow(0);
      async.elapse(const Duration(seconds: 2));
      matcher.beginSuppressWindow(0);
      expect(async.nonPeriodicTimerCount, 1);

      async.elapse(const Duration(seconds: 1));
      expect(
        matcher.suppressesMediaPause,
        isTrue,
        reason: 'the older window must not clear the overlapping newer window',
      );

      async.elapse(const Duration(milliseconds: 1999));
      expect(matcher.suppressesMediaPause, isTrue);

      async.elapse(const Duration(milliseconds: 1));
      expect(matcher.suppressesMediaPause, isFalse);
      matcher.dispose();
    });
  });

  test('dispose cancels an active suppression deadline', () {
    fakeAsync((async) {
      final matcher = FrameRateMatcher()..beginSuppressWindow(0);
      expect(async.nonPeriodicTimerCount, 1);

      matcher.dispose();
      expect(matcher.suppressesMediaPause, isFalse);
      expect(async.nonPeriodicTimerCount, 0);

      async.elapse(const Duration(seconds: 10));
      expect(matcher.suppressesMediaPause, isFalse);
    });
  });
}

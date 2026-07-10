import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/screens/video_player/tv_background_suspend_policy.dart';

void main() {
  test('Android TV VOD releases the player after the background grace period', () {
    expect(
      shouldSuspendPlayerForTvBackground(isAndroid: true, isTv: true, isLive: false, alreadySuspended: false),
      isTrue,
    );
  });

  test('live TV retains its tuned session and time-shift state', () {
    expect(
      shouldSuspendPlayerForTvBackground(isAndroid: true, isTv: true, isLive: true, alreadySuspended: false),
      isFalse,
    );
  });

  test('non-Android and non-TV players do not use the TV suspend flow', () {
    expect(
      shouldSuspendPlayerForTvBackground(isAndroid: false, isTv: true, isLive: false, alreadySuspended: false),
      isFalse,
    );
    expect(
      shouldSuspendPlayerForTvBackground(isAndroid: true, isTv: false, isLive: false, alreadySuspended: false),
      isFalse,
    );
  });

  test('an already suspended player is not scheduled again', () {
    expect(
      shouldSuspendPlayerForTvBackground(isAndroid: true, isTv: true, isLive: false, alreadySuspended: true),
      isFalse,
    );
  });
}

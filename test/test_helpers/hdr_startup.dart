import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/player/player_native.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/screens/video_player_screen.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:provider/provider.dart';

import 'media_items.dart';
import 'mock_player_channels.dart';
import 'prefs.dart';
import 'pump.dart';

/// Shared scaffold for the three Linux HDR startup cases.
///
/// Each lives in its own file with one test, because a second `VideoPlayerScreen`
/// in the same isolate never reaches `initialize`. Measured, repeatedly: the
/// second test's wait fails with `calls=[isModeChanged, isHDRChanged,
/// setVideoRect]` and no `initialize` among them, so nothing the HDR block does
/// can be observed.
///
/// Partly explained, and the gap is worth knowing before you retry. `PlayerBase`
/// keeps one event-channel owner at a time; a successor built before the
/// predecessor's release settles inherits that future, and `PlayerBase.invoke`
/// awaits it before touching the channel, returning null on timeout rather than
/// calling (player_base.dart:1035-1041). That accounts for the missing
/// `initialize`, and for `isModeChanged`/`isHDRChanged` arriving anyway since
/// DisplayModeService drives the channel directly. It does *not* account for
/// `setVideoRect`, which goes through the same gate and still lands - so the
/// picture is incomplete and that is the loose end to pull on.
///
/// Two remedies were measured and neither works. Shortening
/// `debugNativeOwnershipDisposeTimeout` only makes `invoke` give up sooner, which
/// is still a dropped call; at its 3 s default it outlasts [pumpUntil]'s 2 s
/// budget, so the wait fails first. Draining the predecessor's `dispose`/`cancel`
/// does not help either - the owner entry clears a microtask after those calls
/// land (player_base.dart:1426-1434).
Future<void> installHdrStartupHarness({bool linuxVideoPath = true}) async {
  resetSharedPreferencesForTest();
  SettingsService.resetForTesting();
  await SettingsService.getInstance();
  // Non-zero so the write that follows the HDR block actually happens.
  await SettingsService.instance.write(SettingsService.audioSyncOffset, 250);
  // Reaches the Linux-only tolerance on any host, so this is real coverage
  // everywhere rather than something only Linux CI ever runs - and forcing it
  // off is what makes the non-Linux abort testable at all.
  PlayerNative.debugUseLinuxVideoPlane = linuxVideoPath;
  addTearDown(() => PlayerNative.debugUseLinuxVideoPlane = null);
}

/// Answers like the native plane - `initialize` succeeds with a plain `true`,
/// the surface itself being the compositor's subsurface rather than anything
/// Dart holds - but fails the `hdr-enabled` write with [refusal].
Future<Object?> Function(MethodCall) _refusingPlane(List<MethodCall> calls, PlatformException refusal) => (call) {
  calls.add(call);
  if (call.method == 'setProperty' && (call.arguments as Map)['name'] == 'hdr-enabled') {
    return Future<Object?>.error(refusal);
  }
  return switch (call.method) {
    'initialize' => Future<Object?>.value(true),
    _ => Future<Object?>.value(null),
  };
};

// The title reaches the "VideoPlayerScreen initialized for:" log line, so each
// case names itself in any log a failure is diagnosed from.
Future<void> _mountPlayerScreen(WidgetTester tester, String title) => tester.pumpWidget(
  ChangeNotifierProvider(
    create: (_) => PlaybackStateProvider(),
    child: MaterialApp(
      home: VideoPlayerScreen(metadata: testMediaItem(title: title), isOffline: true),
    ),
  ),
);

/// Mounts the player screen against a native plane that fails the `hdr-enabled`
/// write with [refusal], and asserts initialization ran through the HDR block
/// into the `audio-delay` write that follows it.
Future<void> expectStartupSurvivesHdrRefusal(WidgetTester tester, PlatformException refusal) async {
  final calls = <MethodCall>[];
  final eventCalls = <MethodCall>[];

  await withMockPlayerChannels(
    methodChannelName: 'com.plezy/mpv_player',
    eventChannelName: 'com.plezy/mpv_player/events',
    methodHandler: _refusingPlane(calls, refusal),
    eventHandler: (call) async {
      eventCalls.add(call);
      return null;
    },
    testBody: () async {
      await _mountPlayerScreen(tester, 'Linux HDR startup test video');
      await pumpUntil(
        tester,
        () => _propertyWrites(calls).contains('audio-delay'),
        describe: () => 'writes=${_propertyWrites(calls)} calls=${calls.map((c) => c.method).toList()}',
      );

      // The write was attempted, not skipped, and the sentinel came after it:
      // tolerating the refusal is only meaningful if the preference was actually
      // pushed, and `audio-delay` only proves anything downstream of the block.
      expect(_propertyWrites(calls), containsAllInOrder(['hdr-enabled', 'audio-delay']));

      // Unmount and let the dispose/cancel round-trip land while the mock
      // handlers are still registered, so teardown is deterministic instead of
      // racing withMockPlayerChannels' finally. It does not make a second mount
      // in this isolate work - see the note on installHdrStartupHarness.
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpUntil(
        tester,
        () => calls.any((call) => call.method == 'dispose') && eventCalls.any((call) => call.method == 'cancel'),
        describe: () =>
            'calls=${calls.map((c) => c.method).toList()} events=${eventCalls.map((c) => c.method).toList()}',
      );
    },
  );
}

/// The negative side of [expectStartupSurvivesHdrRefusal]: with the Linux video
/// path forced off, the same refusal must abort initialization rather than be
/// swallowed, so `audio-delay` never follows it.
Future<void> expectStartupAbortsOnHdrRefusal(WidgetTester tester, PlatformException refusal) async {
  final calls = <MethodCall>[];

  await withMockPlayerChannels(
    methodChannelName: 'com.plezy/mpv_player',
    eventChannelName: 'com.plezy/mpv_player/events',
    methodHandler: _refusingPlane(calls, refusal),
    testBody: () async {
      await _mountPlayerScreen(tester, 'Non-Linux HDR refusal video');
      // Wait for the abort to *show*, rather than for a fixed budget to elapse.
      // The error screen is the positive marker that initialization gave up, so
      // the absence asserted below is final rather than merely not-yet.
      await pumpUntil(
        tester,
        () => find.widgetWithText(FilledButton, 'Retry').evaluate().isNotEmpty,
        describe: () => 'writes=${_propertyWrites(calls)} calls=${calls.map((c) => c.method).toList()}',
      );

      expect(_propertyWrites(calls), contains('hdr-enabled'));
      expect(_propertyWrites(calls), isNot(contains('audio-delay')));

      // Same deterministic teardown as the positive helper. There is no release
      // to drain here: initialization aborted, so no dispose round-trip follows.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}

List<String> _propertyWrites(List<MethodCall> calls) => [
  for (final call in calls)
    if (call.method == 'setProperty') (call.arguments as Map)['name'] as String,
];

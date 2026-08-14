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

/// Shared scaffold for the four Linux HDR startup cases.
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
Future<void> installHdrStartupHarness({bool linuxVideoPath = true, bool enableHdr = true}) async {
  resetSharedPreferencesForTest();
  SettingsService.resetForTesting();
  await SettingsService.getInstance();
  // Non-zero so the write that follows the HDR block actually happens.
  await SettingsService.instance.write(SettingsService.audioSyncOffset, 250);
  // Seeded rather than left at its default, so the value the startup path sends
  // can be asserted against a preference this harness chose - both arms of it.
  await SettingsService.instance.write(SettingsService.enableHDR, enableHdr);
  // Reaches the Linux-only tolerance on any host, so this is real coverage
  // everywhere rather than something only Linux CI ever runs - and forcing it
  // off is what makes the non-Linux abort testable at all.
  PlayerNative.debugUseLinuxVideoPlane = linuxVideoPath;
  addTearDown(() => PlayerNative.debugUseLinuxVideoPlane = null);
}

/// Answers like the native plane - `initialize` succeeds with a plain `true`,
/// the surface itself being the compositor's subsurface rather than anything
/// Dart holds - but fails the write of [property] with [refusal].
Future<Object?> Function(MethodCall) _refusingPlane(
  List<MethodCall> calls,
  PlatformException refusal, {
  String property = 'hdr-enabled',
}) => (call) {
  calls.add(call);
  if (call.method == 'setProperty' && (call.arguments as Map)['name'] == property) {
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
/// into the `audio-delay` write that follows it - and that the stored
/// preference came out of the refusal agreeing with the plane.
Future<void> expectStartupSurvivesHdrRefusal(
  WidgetTester tester,
  PlatformException refusal, {
  String title = 'Linux HDR startup test video',
}) async {
  // Read before mounting, because startup rewrites it: comparing the wire value
  // against a preference the refusal has already corrected would compare the
  // correction with itself and pass whatever was sent.
  final seededHdrEnabled = SettingsService.instance.read(SettingsService.enableHDR);
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
      await _mountPlayerScreen(tester, title);
      await pumpUntil(
        tester,
        () => _propertyWrites(calls).contains('audio-delay'),
        describe: () => 'writes=${_propertyWrites(calls)} calls=${calls.map((c) => c.method).toList()}',
      );

      // The write was attempted, not skipped, and the sentinel came after it:
      // tolerating the refusal is only meaningful if the preference was actually
      // pushed, and `audio-delay` only proves anything downstream of the block.
      expect(_propertyWrites(calls), containsAllInOrder(['hdr-enabled', 'audio-delay']));

      // And it carried the seeded preference, not a hard-coded arm: with the
      // ternary inverted, or a different preference read, everything asserted
      // above still holds because only the property *name* is involved.
      expect(_valueWrites(calls, 'hdr-enabled'), [_hdrEnabledWire(seededHdrEnabled)]);

      // The refused transaction hands the plugin's hdr_wanted back to what it
      // held before the write, which on a plugin this session just created is
      // off. Dart has to follow it down: the settings switch renders straight
      // off this preference, so leaving it on shows HDR enabled over an SDR
      // plane, and every later internal re-apply reads the native side - the
      // two would stay apart until the user toggled twice. Asserted on both
      // arms of the preference, so the stored-off arm proves the correction
      // does not disturb a value that was already right.
      expect(SettingsService.instance.read(SettingsService.enableHDR), isFalse);

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

/// Startup pushes the tone-mapping preference just before `hdr-enabled`, and a
/// refusal there is swallowed the same way. The plugin, though, reverts to the
/// mode it last accepted - the compositor default, since nothing has moved it
/// this session - so the stored preference has to follow, or the settings sheet
/// keeps naming a mode the plane never entered with no way back but a manual
/// toggle.
Future<void> expectRefusedToneMappingRestoresStoredMode(WidgetTester tester, PlatformException refusal) async {
  await SettingsService.instance.write(SettingsService.hdrToneMapping, HdrToneMapping.player);
  final calls = <MethodCall>[];
  final eventCalls = <MethodCall>[];

  await withMockPlayerChannels(
    methodChannelName: 'com.plezy/mpv_player',
    eventChannelName: 'com.plezy/mpv_player/events',
    methodHandler: _refusingPlane(calls, refusal, property: 'hdr-tone-mapping'),
    eventHandler: (call) async {
      eventCalls.add(call);
      return null;
    },
    testBody: () async {
      await _mountPlayerScreen(tester, 'Linux HDR tone-mapping refusal video');
      await pumpUntil(
        tester,
        () => _propertyWrites(calls).contains('audio-delay'),
        describe: () => 'writes=${_propertyWrites(calls)} calls=${calls.map((c) => c.method).toList()}',
      );

      // The stored mode is what was pushed and refused, so the correction below
      // is a real change of mind rather than a value that was never asked for.
      expect(_valueWrites(calls, 'hdr-tone-mapping'), ['player']);
      expect(_propertyWrites(calls), containsAllInOrder(['hdr-tone-mapping', 'audio-delay']));
      expect(SettingsService.instance.read(SettingsService.hdrToneMapping), HdrToneMapping.compositor);

      // Same deterministic teardown as [expectStartupSurvivesHdrRefusal].
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

/// The custom mpv config is free-form `name=value` text, applied after startup
/// has pushed the stored HDR preferences - and neither `hdr-enabled` nor
/// `hdr-tone-mapping` is an mpv property: the Linux plugin intercepts both and
/// moves the plane's own HDR state. An entry for either would therefore land
/// last, change the plane, and never reach SettingsService, which is what the
/// settings sheet renders from. Startup drops those two names for that reason.
///
/// Seeded with a config that contradicts both preferences, so restoring the
/// unfiltered pass fails here: the plane would see a second write of each
/// carrying the config's value while the stored preferences kept the app's. A
/// third, ordinary entry is expected to survive, so a filter that simply
/// skipped the whole pass would fail too.
Future<void> expectCustomConfigCannotOverrideHdrPreferences(WidgetTester tester) async {
  await SettingsService.instance.write(SettingsService.hdrToneMapping, HdrToneMapping.player);
  await SettingsService.instance.write(
    SettingsService.mpvConfigText,
    // The last four are real mpv properties the video plane owns and caches, so
    // a config write would desynchronise that cache from mpv - see
    // _appOwnedMpvProperties. The first two are not mpv properties at all.
    'hdr-enabled=no\n'
    'hdr-tone-mapping=compositor\n'
    'target-trc=pq\n'
    'target-prim=bt.2020\n'
    'target-peak=4000\n'
    'tone-mapping=bt.2390\n'
    'sub-scale=1.5\n',
  );
  // Read before mounting for the same reason as [expectStartupSurvivesHdrRefusal].
  final seededHdrEnabled = SettingsService.instance.read(SettingsService.enableHDR);
  final calls = <MethodCall>[];
  final eventCalls = <MethodCall>[];

  await withMockPlayerChannels(
    methodChannelName: 'com.plezy/mpv_player',
    eventChannelName: 'com.plezy/mpv_player/events',
    // A plane that accepts everything: the hazard here is ordering, not refusal.
    methodHandler: (call) async {
      calls.add(call);
      return call.method == 'initialize' ? true : null;
    },
    eventHandler: (call) async {
      eventCalls.add(call);
      return null;
    },
    testBody: () async {
      await _mountPlayerScreen(tester, 'Linux HDR custom config video');
      // `volume-max` is the write immediately after the custom-config pass, so
      // its arrival is what makes the lists below complete rather than merely
      // not-appended-to-yet.
      await pumpUntil(
        tester,
        () => _propertyWrites(calls).contains('volume-max'),
        describe: () => 'writes=${_propertyWrites(calls)} calls=${calls.map((c) => c.method).toList()}',
      );

      // One write of each, carrying the preference rather than the config line
      // that contradicts it.
      expect(_valueWrites(calls, 'hdr-enabled'), [_hdrEnabledWire(seededHdrEnabled)]);
      expect(_valueWrites(calls, 'hdr-tone-mapping'), ['player']);

      // The rest of the config still reaches mpv: the skip goes by name.
      expect(_valueWrites(calls, 'sub-scale'), ['1.5']);

      // And none of the four the plane owns reached mpv at all: one arriving
      // behind the plane's back leaves its cache describing a colour state mpv
      // does not hold, and the next transaction then skips the write that would
      // have corrected it.
      for (final owned in ['target-trc', 'target-prim', 'target-peak', 'tone-mapping']) {
        expect(_valueWrites(calls, owned), isEmpty, reason: '$owned is owned by the video plane');
      }

      // And nothing dragged the preferences down to what the config asked for,
      // so the settings sheet and the plane still describe the same session.
      expect(SettingsService.instance.read(SettingsService.enableHDR), seededHdrEnabled);
      expect(SettingsService.instance.read(SettingsService.hdrToneMapping), HdrToneMapping.player);

      // Same deterministic teardown as [expectStartupSurvivesHdrRefusal].
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

/// The custom mpv config is applied as runtime mpv_set_property writes, and
/// vo/gpu-context/gpu-api are owned by the embedded renderer: a vo=gpu-next
/// line would make mpv re-create its output as a separate window and orphan
/// the plane (the render API is OpenGL-only, so gpu-next cannot be embedded).
/// Startup must skip the whole VO family by name - with a key-aware log, not
/// the HDR-settings pointer - and let ordinary entries through.
Future<void> expectCustomConfigCannotOverrideEmbeddedVo(WidgetTester tester) async {
  await SettingsService.instance.write(
    SettingsService.mpvConfigText,
    'vo=gpu-next\n'
    'gpu-context=waylandvk\n'
    'gpu-api=vulkan\n'
    'sub-scale=1.5\n',
  );
  final calls = <MethodCall>[];
  final eventCalls = <MethodCall>[];

  await withMockPlayerChannels(
    methodChannelName: 'com.plezy/mpv_player',
    eventChannelName: 'com.plezy/mpv_player/events',
    methodHandler: (call) async {
      calls.add(call);
      return call.method == 'initialize' ? true : null;
    },
    eventHandler: (call) async {
      eventCalls.add(call);
      return null;
    },
    testBody: () async {
      await _mountPlayerScreen(tester, 'Linux embedded VO override video');
      // `volume-max` is the write immediately after the custom-config pass, so
      // its arrival is what makes the lists below complete.
      await pumpUntil(
        tester,
        () => _propertyWrites(calls).contains('volume-max'),
        describe: () => 'writes=${_propertyWrites(calls)} calls=${calls.map((c) => c.method).toList()}',
      );

      // None of the VO family reached mpv: a vo switch would detach the
      // embedded render context into a separate window.
      for (final owned in ['vo', 'gpu-context', 'gpu-api']) {
        expect(_valueWrites(calls, owned), isEmpty, reason: '$owned is owned by the embedded renderer');
      }
      // The rest of the config still reaches mpv: the skip goes by name.
      expect(_valueWrites(calls, 'sub-scale'), ['1.5']);

      // Same deterministic teardown as [expectCustomConfigCannotOverrideHdrPreferences].
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

/// A refused subtitle-styling write must not abort initialization: styling is
/// a preference, and the same refusal that used to land as
/// SET_PROPERTY_FAILED on the channel used to escape
/// _runPlayerInitializationAttempt into the error screen. The mock plane
/// refuses `sub-color`; initialization must run through to `volume-max` and
/// no error screen may appear.
Future<void> expectSubtitleStyleRefusalDoesNotAbortStartup(WidgetTester tester) async {
  final refusal = PlatformException(
    code: 'SET_PROPERTY_FAILED',
    message: "setProperty 'sub-color'='#FFFFFF' failed: unsupported format for accessing property",
  );
  final calls = <MethodCall>[];
  final eventCalls = <MethodCall>[];

  await withMockPlayerChannels(
    methodChannelName: 'com.plezy/mpv_player',
    eventChannelName: 'com.plezy/mpv_player/events',
    methodHandler: (call) async {
      calls.add(call);
      if (call.method == 'setProperty' && (call.arguments as Map)['name'] == 'sub-color') {
        return Future<Object?>.error(refusal);
      }
      return call.method == 'initialize' ? true : null;
    },
    eventHandler: (call) async {
      eventCalls.add(call);
      return null;
    },
    testBody: () async {
      await _mountPlayerScreen(tester, 'Linux subtitle style refusal video');
      // `volume-max` follows the styling block; reaching it proves the refusal
      // was contained and initialization ran on.
      await pumpUntil(
        tester,
        () => _propertyWrites(calls).contains('volume-max'),
        describe: () => 'writes=${_propertyWrites(calls)} calls=${calls.map((c) => c.method).toList()}',
      );

      // The write was attempted (not skipped) and the refusal was swallowed:
      // playback must not die over styling.
      expect(_propertyWrites(calls), contains('sub-color'));
      expect(find.text('Retry'), findsNothing, reason: 'a styling refusal must not show the error screen');

      // Same deterministic teardown as the HDR cases.
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

/// The stored subtitle colours are free-form strings and mpv 0.40's OPT_COLOR
/// parser rejects anything but #RRGGBB/#AARRGGBB, so startup sanitizes the
/// values before writing: parseable hex passes through, everything else is
/// replaced by the preference default. The caller seeds the unparseable
/// values; this asserts what reaches the wire.
Future<void> expectSanitizedSubtitleColorsOnTheWire(WidgetTester tester) async {
  final calls = <MethodCall>[];
  final eventCalls = <MethodCall>[];

  await withMockPlayerChannels(
    methodChannelName: 'com.plezy/mpv_player',
    eventChannelName: 'com.plezy/mpv_player/events',
    methodHandler: (call) async {
      calls.add(call);
      return call.method == 'initialize' ? true : null;
    },
    eventHandler: (call) async {
      eventCalls.add(call);
      return null;
    },
    testBody: () async {
      await _mountPlayerScreen(tester, 'Linux subtitle colour sanitization video');
      // `volume-max` follows the subtitle styling block, so its arrival makes
      // the styling writes complete.
      await pumpUntil(
        tester,
        () => _propertyWrites(calls).contains('volume-max'),
        describe: () => 'writes=${_propertyWrites(calls)} calls=${calls.map((c) => c.method).toList()}',
      );

      // The defaults, not the unparseable seeds.
      expect(_valueWrites(calls, 'sub-color'), ['#FFFFFF']);
      expect(_valueWrites(calls, 'sub-border-color'), ['#000000']);
      expect(_valueWrites(calls, 'sub-back-color'), ['#FF000000']);

      // Same deterministic teardown as the HDR cases.
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
/// swallowed, so `audio-delay` never follows it and the stored preference is
/// left exactly as it was - the reconciliation lives inside the tolerance, and
/// a rethrown refusal says nothing about what the plane settled on.
Future<void> expectStartupAbortsOnHdrRefusal(WidgetTester tester, PlatformException refusal) async {
  final calls = <MethodCall>[];
  final seededHdrEnabled = SettingsService.instance.read(SettingsService.enableHDR);

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
      expect(_valueWrites(calls, 'hdr-enabled'), [_hdrEnabledWire(seededHdrEnabled)]);
      expect(SettingsService.instance.read(SettingsService.enableHDR), seededHdrEnabled);

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

/// The values every `setProperty` write of [name] carried, in order.
List<String> _valueWrites(List<MethodCall> calls, String name) => [
  for (final call in calls)
    if (call.method == 'setProperty' && (call.arguments as Map)['name'] == name)
      (call.arguments as Map)['value'] as String,
];

/// The wire value startup owes a preference seeded to [enabled].
String _hdrEnabledWire(bool enabled) => enabled ? 'yes' : 'no';

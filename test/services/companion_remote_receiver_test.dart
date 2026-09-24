import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/companion_remote/remote_command.dart';
import 'package:plezy/services/companion_remote/companion_remote_receiver.dart';
import 'package:plezy/widgets/video_controls/player_chrome_controller.dart';
import 'package:plezy/widgets/video_controls/video_controls.dart';

void main() {
  testWidgets('Back command dispatches semantic gamepad B events', (tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    final events = <KeyEvent>[];
    var actions = 0;
    var exits = 0;
    final chromeController = PlayerChromeController();
    addTearDown(chromeController.dispose);
    final coordinator = PlayerNavigationCoordinator(
      chromeController: chromeController,
      isPromptOpen: () => false,
      dismissPrompt: () {},
      isChromePresented: () => chromeController.controlsPresented,
      exitFullscreenIfActive: () async => false,
      exitPlayer: () => exits++,
      navigateHome: () {},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Focus(
          focusNode: focusNode,
          onKeyEvent: (_, event) {
            events.add(event);
            final navigationKey = classifyPlayerNavigationKey(event, isAppleTV: false);
            return handlePlayerNavigationKeyAction(event, navigationKey, () {
              actions++;
              coordinator.handle(navigationKey);
            });
          },
          child: const SizedBox.expand(),
        ),
      ),
    );
    focusNode.requestFocus();
    await tester.pump();

    CompanionRemoteReceiver.instance.handleCommand(const RemoteCommand(type: RemoteCommandType.back), null);
    await tester.pump();

    expect(events, hasLength(2));
    expect(events.first, isA<KeyDownEvent>());
    expect(events.last, isA<KeyUpEvent>());
    expect(events.map((event) => event.logicalKey), everyElement(LogicalKeyboardKey.gameButtonB));
    expect(events.map((event) => event.deviceType), everyElement(ui.KeyEventDeviceType.directionalPad));
    expect(actions, 1);
    expect(chromeController.controlsVisible, isFalse);
    expect(exits, 0);
  });

  testWidgets('playMedia command dispatches serverId, ratingKey and offset to onPlayMediaAction', (tester) async {
    final receiver = CompanionRemoteReceiver.instance;
    String? gotServerId;
    String? gotRatingKey;
    int? gotOffset;
    var calls = 0;
    receiver.onPlayMediaAction = (serverId, ratingKey, offset) {
      calls++;
      gotServerId = serverId;
      gotRatingKey = ratingKey;
      gotOffset = offset;
    };
    addTearDown(() => receiver.onPlayMediaAction = null);

    receiver.handleCommand(
      const RemoteCommand(
        type: RemoteCommandType.playMedia,
        data: {'serverId': 'srv-123', 'ratingKey': '45678', 'offset': 1000},
      ),
      null,
    );
    await tester.pump();

    expect(calls, 1);
    expect(gotServerId, 'srv-123');
    expect(gotRatingKey, '45678');
    expect(gotOffset, 1000);
  });

  testWidgets('playMedia command with missing ratingKey does not dispatch', (tester) async {
    final receiver = CompanionRemoteReceiver.instance;
    var calls = 0;
    receiver.onPlayMediaAction = (_, _, _) => calls++;
    addTearDown(() => receiver.onPlayMediaAction = null);

    receiver.handleCommand(const RemoteCommand(type: RemoteCommandType.playMedia, data: {'serverId': 'srv-123'}), null);
    await tester.pump();

    expect(calls, 0);
  });

  testWidgets('volumeSet dispatches volume to onVolumeSet', (tester) async {
    final receiver = CompanionRemoteReceiver.instance;
    double? got;
    receiver.onVolumeSet = (v) => got = v;
    addTearDown(() => receiver.onVolumeSet = null);
    receiver.handleCommand(const RemoteCommand(type: RemoteCommandType.volumeSet, data: {'volume': 42}), null);
    await tester.pump();
    expect(got, 42.0);
  });

  testWidgets('seekTo dispatches positionMs to onSeekTo', (tester) async {
    final receiver = CompanionRemoteReceiver.instance;
    int? got;
    receiver.onSeekTo = (ms) => got = ms;
    addTearDown(() => receiver.onSeekTo = null);
    receiver.handleCommand(const RemoteCommand(type: RemoteCommandType.seekTo, data: {'positionMs': 90000}), null);
    await tester.pump();
    expect(got, 90000);
  });

  testWidgets('shuffleMedia dispatches serverId+ratingKey to onShuffleMediaAction', (tester) async {
    final receiver = CompanionRemoteReceiver.instance;
    String? s;
    String? r;
    receiver.onShuffleMediaAction = (sv, rk) {
      s = sv;
      r = rk;
    };
    addTearDown(() => receiver.onShuffleMediaAction = null);
    receiver.handleCommand(
      const RemoteCommand(type: RemoteCommandType.shuffleMedia, data: {'serverId': 'srv', 'ratingKey': '99'}),
      null,
    );
    await tester.pump();
    expect(s, 'srv');
    expect(r, '99');
  });

  testWidgets('markWatched/markUnwatched dispatch watched flag to onSetWatchedAction', (tester) async {
    final receiver = CompanionRemoteReceiver.instance;
    final calls = <bool>[];
    receiver.onSetWatchedAction = (_, _, w) => calls.add(w);
    addTearDown(() => receiver.onSetWatchedAction = null);
    receiver.handleCommand(
      const RemoteCommand(type: RemoteCommandType.markWatched, data: {'serverId': 's', 'ratingKey': '1'}),
      null,
    );
    receiver.handleCommand(
      const RemoteCommand(type: RemoteCommandType.markUnwatched, data: {'serverId': 's', 'ratingKey': '1'}),
      null,
    );
    await tester.pump();
    expect(calls, [true, false]);
  });

  testWidgets('criteria commands pass their payload to their own callback', (tester) async {
    final receiver = CompanionRemoteReceiver.instance;
    final got = <RemoteCommandType, Map<String, dynamic>>{};
    void Function(Map<String, dynamic>) record(RemoteCommandType type) =>
        (criteria) => got[type] = criteria;
    receiver
      ..onSetSubtitleTrack = record(RemoteCommandType.setSubtitleTrack)
      ..onSetAudioTrack = record(RemoteCommandType.setAudioTrack)
      ..onSetQuality = record(RemoteCommandType.setQuality)
      ..onSetAudioDevice = record(RemoteCommandType.setAudioDevice)
      ..onSetSubtitleSync = record(RemoteCommandType.setSubtitleSync)
      ..onSetAudioSync = record(RemoteCommandType.setAudioSync)
      ..onSetSpeed = record(RemoteCommandType.setSpeed)
      ..onSetZoom = record(RemoteCommandType.setZoom);
    addTearDown(() {
      receiver
        ..onSetSubtitleTrack = null
        ..onSetAudioTrack = null
        ..onSetQuality = null
        ..onSetAudioDevice = null
        ..onSetSubtitleSync = null
        ..onSetAudioSync = null
        ..onSetSpeed = null
        ..onSetZoom = null;
    });
    const payloads = <RemoteCommandType, Map<String, dynamic>>{
      RemoteCommandType.setSubtitleTrack: {'language': 'eng', 'codec': 'srt', 'external': false},
      RemoteCommandType.setAudioTrack: {'language': 'eng'},
      RemoteCommandType.setQuality: {'quality': '1080p'},
      RemoteCommandType.setAudioDevice: {'name': 'tv'},
      RemoteCommandType.setSubtitleSync: {'deltaMs': 250},
      RemoteCommandType.setAudioSync: {'reset': true},
      RemoteCommandType.setSpeed: {'delta': -0.25},
      RemoteCommandType.setZoom: {'fit': 'cover'},
    };
    for (final entry in payloads.entries) {
      receiver.handleCommand(RemoteCommand(type: entry.key, data: entry.value), null);
    }
    await tester.pump();
    expect(got, payloads);
  });

  test('the appended command indices stay where controllers expect them', () {
    // The wire format is index-based, so an accidental reorder silently
    // repoints every controller. Pin them.
    const expected = {
      RemoteCommandType.playMedia: 40,
      RemoteCommandType.seekTo: 41,
      RemoteCommandType.shuffleMedia: 42,
      RemoteCommandType.markWatched: 43,
      RemoteCommandType.markUnwatched: 44,
      RemoteCommandType.setSubtitleTrack: 45,
      RemoteCommandType.setAudioTrack: 46,
      RemoteCommandType.setQuality: 47,
      RemoteCommandType.setAudioDevice: 48,
      RemoteCommandType.setSubtitleSync: 49,
      RemoteCommandType.setAudioSync: 50,
      RemoteCommandType.setSpeed: 51,
      RemoteCommandType.setSecondarySubtitleTrack: 52,
      RemoteCommandType.setZoom: 53,
      RemoteCommandType.setFullscreen: 54,
    };
    expected.forEach((type, index) => expect(type.index, index, reason: type.name));
  });

  testWidgets('setSecondarySubtitleTrack passes criteria to its own callback', (tester) async {
    final receiver = CompanionRemoteReceiver.instance;
    Map<String, dynamic>? secondary;
    Map<String, dynamic>? primary;
    receiver.onSetSecondarySubtitleTrack = (c) => secondary = c;
    receiver.onSetSubtitleTrack = (c) => primary = c;
    addTearDown(() {
      receiver.onSetSecondarySubtitleTrack = null;
      receiver.onSetSubtitleTrack = null;
    });
    receiver.handleCommand(
      const RemoteCommand(type: RemoteCommandType.setSecondarySubtitleTrack, data: {'language': 'heb'}),
      null,
    );
    await tester.pump();
    expect(secondary, {'language': 'heb'});
    // The two subtitle commands must not share a callback, or a secondary
    // request would move the primary track.
    expect(primary, isNull);
  });

  testWidgets('setFullscreen dispatches the enabled flag to onSetFullscreen', (tester) async {
    final receiver = CompanionRemoteReceiver.instance;
    final got = <bool>[];
    receiver.onSetFullscreen = got.add;
    addTearDown(() => receiver.onSetFullscreen = null);
    receiver.handleCommand(const RemoteCommand(type: RemoteCommandType.setFullscreen, data: {'enabled': true}), null);
    receiver.handleCommand(const RemoteCommand(type: RemoteCommandType.setFullscreen, data: {'enabled': false}), null);
    await tester.pump();
    expect(got, [true, false]);
  });

  testWidgets('setFullscreen with no enabled flag does not dispatch', (tester) async {
    final receiver = CompanionRemoteReceiver.instance;
    var calls = 0;
    receiver.onSetFullscreen = (_) => calls++;
    addTearDown(() => receiver.onSetFullscreen = null);
    receiver.handleCommand(const RemoteCommand(type: RemoteCommandType.setFullscreen, data: {}), null);
    await tester.pump();
    expect(calls, 0);
  });

  testWidgets('skipIntro/skipCredits dispatch to their callbacks', (tester) async {
    final receiver = CompanionRemoteReceiver.instance;
    var intro = 0;
    var credits = 0;
    receiver.onSkipIntro = () => intro++;
    receiver.onSkipCredits = () => credits++;
    addTearDown(() {
      receiver.onSkipIntro = null;
      receiver.onSkipCredits = null;
    });
    receiver.handleCommand(const RemoteCommand(type: RemoteCommandType.skipIntro), null);
    receiver.handleCommand(const RemoteCommand(type: RemoteCommandType.skipCredits), null);
    await tester.pump();
    expect(intro, 1);
    expect(credits, 1);
  });

  testWidgets('play/pause/playPause dispatch to the player callbacks when a player is attached', (tester) async {
    final receiver = CompanionRemoteReceiver.instance;
    var plays = 0;
    var pauses = 0;
    var toggles = 0;
    receiver.onPlay = () => plays++;
    receiver.onPause = () => pauses++;
    receiver.onPlayPause = () => toggles++;
    addTearDown(() {
      receiver.onPlay = null;
      receiver.onPause = null;
      receiver.onPlayPause = null;
    });

    receiver.handleCommand(const RemoteCommand(type: RemoteCommandType.play), null);
    receiver.handleCommand(const RemoteCommand(type: RemoteCommandType.pause), null);
    receiver.handleCommand(const RemoteCommand(type: RemoteCommandType.playPause), null);
    await tester.pump();

    expect(plays, 1);
    expect(pauses, 1);
    expect(toggles, 1);
  });

  testWidgets('play falls back to a space keypress when no player is attached', (tester) async {
    final receiver = CompanionRemoteReceiver.instance;
    receiver.onPlay = null;
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    final events = <KeyEvent>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Focus(
          focusNode: focusNode,
          onKeyEvent: (_, event) {
            events.add(event);
            return KeyEventResult.handled;
          },
          child: const SizedBox.expand(),
        ),
      ),
    );
    focusNode.requestFocus();
    await tester.pump();

    receiver.handleCommand(const RemoteCommand(type: RemoteCommandType.play), null);
    await tester.pump();

    expect(events, hasLength(2));
    expect(events.map((event) => event.logicalKey), everyElement(LogicalKeyboardKey.space));
  });

  group('onCommandHandled', () {
    tearDown(() {
      final receiver = CompanionRemoteReceiver.instance;
      receiver.onCommandHandled = null;
      receiver.onVolumeSet = null;
      receiver.onSeekTo = null;
    });

    test('fires for a command that changes playback state', () {
      final receiver = CompanionRemoteReceiver.instance;
      var handled = 0;
      receiver.onVolumeSet = (_) {};
      receiver.onCommandHandled = () => handled++;

      receiver.handleCommand(const RemoteCommand(type: RemoteCommandType.volumeSet, data: {'volume': 42}), null);

      expect(handled, 1);
    });

    test('does NOT fire for informational frames', () {
      // An inbound ack that produced a state frame the controller then acked
      // would loop forever, so the informational group must stay silent.
      final receiver = CompanionRemoteReceiver.instance;
      var handled = 0;
      receiver.onCommandHandled = () => handled++;

      for (final type in const [
        RemoteCommandType.ping,
        RemoteCommandType.pong,
        RemoteCommandType.ack,
        RemoteCommandType.deviceInfo,
        RemoteCommandType.disconnect,
        RemoteCommandType.syncState,
      ]) {
        receiver.handleCommand(RemoteCommand(type: type), null);
      }

      expect(handled, 0);
    });

    test('stays silent once the player has released the receiver', () {
      final receiver = CompanionRemoteReceiver.instance;
      var handled = 0;
      receiver.onSeekTo = (_) {};
      receiver.onCommandHandled = () => handled++;
      receiver.handleCommand(const RemoteCommand(type: RemoteCommandType.seekTo, data: {'positionMs': 1000}), null);
      expect(handled, 1);

      receiver.onCommandHandled = null;
      receiver.handleCommand(const RemoteCommand(type: RemoteCommandType.seekTo, data: {'positionMs': 2000}), null);
      expect(handled, 1);
    });
  });
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/companion_remote/remote_command.dart';
import 'package:plezy/models/companion_remote/remote_session.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/providers/companion_remote_provider.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/screens/video_player_screen.dart';
import 'package:plezy/services/companion_remote/companion_remote_receiver.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/media_items.dart';
import '../../test_helpers/mock_player_channels.dart';
import '../../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    final settings = await SettingsService.getInstance();
    await settings.write(SettingsService.seekTimeSmall, 7);
  });

  testWidgets('in-flight Companion seeks stay bound to the receipt-time player', (tester) async {
    final nativeInitialize = Completer<bool>();
    final playerA = _ControlledSeekPlayer(position: const Duration(seconds: 30));
    final playerB = _ControlledSeekPlayer(position: const Duration(seconds: 50));
    addTearDown(playerA.dispose);

    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) {
        if (call.method == 'initialize') return nativeInitialize.future;
        return Future<Object?>.value(null);
      },
      eventHandler: (_) async => null,
      testBody: () async {
        final key = GlobalKey<VideoPlayerScreenState>();
        await tester.pumpWidget(_screen(key));
        expect(key.currentState, isNotNull);
        key.currentState!.player = playerA;

        CompanionRemoteReceiver.instance.handleCommand(const RemoteCommand(type: RemoteCommandType.seekForward), null);
        // Relative skips are coalesced by the screen (#1375), so the seek
        // lands on the accumulator's debounce rather than synchronously.
        await tester.pump(const Duration(milliseconds: 400));
        expect(playerA.seekTargets, [const Duration(seconds: 37)]);
        key.currentState!.player = playerB;
        playerA.completeSeek();
        await tester.pump();
        expect(playerB.seekTargets, isEmpty);

        key.currentState!.player = playerA;
        CompanionRemoteReceiver.instance.handleCommand(const RemoteCommand(type: RemoteCommandType.seekBackward), null);
        await tester.pump(const Duration(milliseconds: 400));
        expect(
          playerA.seekTargets.last,
          const Duration(seconds: 30),
          reason: 'the step rebases off the pinned 37s target, not the stale position the backend still reports',
        );
        key.currentState!.player = playerB;
        playerA.completeSeek();
        await tester.pump();
        expect(playerB.seekTargets, isEmpty);

        await tester.pumpWidget(const SizedBox.shrink());
        nativeInitialize.complete(true);
        await tester.pump();
        CompanionRemoteReceiver.instance.handleCommand(const RemoteCommand(type: RemoteCommandType.seekForward), null);
        expect(playerB.seekTargets, isEmpty, reason: 'disposed owner callbacks must be inert');
      },
    );
  });

  testWidgets('every companion command slot is installed on bind and cleared on dispose', (tester) async {
    // An unwired receiver slot is a silently dead command that `flutter
    // analyze` cannot catch (the slot type exists, it is just never assigned).
    // This asserts _installCompanionCommandSlots wired all of them.
    final receiver = CompanionRemoteReceiver.instance;
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) async => null,
      eventHandler: (_) async => null,
      testBody: () async {
        final key = GlobalKey<VideoPlayerScreenState>();
        await tester.pumpWidget(_screen(key));
        expect(key.currentState, isNotNull);

        final slots = <String, Object?>{
          'onPlay': receiver.onPlay,
          'onPause': receiver.onPause,
          'onPlayPause': receiver.onPlayPause,
          'onSkipIntro': receiver.onSkipIntro,
          'onSkipCredits': receiver.onSkipCredits,
          'onSeekTo': receiver.onSeekTo,
          'onVolumeSet': receiver.onVolumeSet,
          'onSetSubtitleTrack': receiver.onSetSubtitleTrack,
          'onSetAudioTrack': receiver.onSetAudioTrack,
          'onSetQuality': receiver.onSetQuality,
          'onSetAudioDevice': receiver.onSetAudioDevice,
          'onSetSubtitleSync': receiver.onSetSubtitleSync,
          'onSetAudioSync': receiver.onSetAudioSync,
          'onSetSpeed': receiver.onSetSpeed,
          'onSetSecondarySubtitleTrack': receiver.onSetSecondarySubtitleTrack,
          'onSetZoom': receiver.onSetZoom,
          'onCommandHandled': receiver.onCommandHandled,
        };
        slots.forEach((name, value) {
          expect(value, isNotNull, reason: '$name was not installed by _installCompanionCommandSlots()');
        });

        await tester.pumpWidget(const SizedBox.shrink());
        expect(receiver.onPlay, isNull, reason: 'command slots must be cleared on dispose');
        expect(receiver.onSetQuality, isNull, reason: 'command slots must be cleared on dispose');
      },
    );
  });

  group('now-playing status frames', () {
    testWidgets('are not sent while no controller is connected', (tester) async {
      final remote = _RecordingRemote();
      addTearDown(remote.dispose);
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) async => null,
        eventHandler: (_) async => null,
        testBody: () async {
          final key = GlobalKey<VideoPlayerScreenState>();
          await tester.pumpWidget(_screen(key, remote: remote));
          CompanionRemoteReceiver.instance.onCommandHandled!();
          await tester.pump(const Duration(seconds: 6));
          await tester.pumpWidget(const SizedBox.shrink());

          expect(remote.statusFrames, isEmpty);
        },
      );
    });

    testWidgets('reach a connected controller', (tester) async {
      final remote = _RecordingRemote()..device = _controllerDevice();
      addTearDown(remote.dispose);
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) async => null,
        eventHandler: (_) async => null,
        testBody: () async {
          final key = GlobalKey<VideoPlayerScreenState>();
          await tester.pumpWidget(_screen(key, remote: remote));
          await tester.pumpWidget(const SizedBox.shrink());

          expect(remote.statusFrames.where((frame) => frame['playerActive'] == false), isNotEmpty);
        },
      );
    });

    testWidgets('do not name the item before the player is initialized', (tester) async {
      final nativeInitialize = Completer<bool>();
      final remote = _RecordingRemote()..device = _controllerDevice();
      addTearDown(remote.dispose);
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) {
          if (call.method == 'initialize') return nativeInitialize.future;
          return Future<Object?>.value(null);
        },
        eventHandler: (_) async => null,
        testBody: () async {
          final key = GlobalKey<VideoPlayerScreenState>();
          await tester.pumpWidget(_screen(key, remote: remote));
          CompanionRemoteReceiver.instance.onCommandHandled!();
          await tester.pump(const Duration(seconds: 6));

          expect(
            remote.statusFrames.where((frame) => frame['playerActive'] == true),
            isEmpty,
            reason: 'commands sent on this frame would reach a player that does not exist yet',
          );

          await tester.pumpWidget(const SizedBox.shrink());
          nativeInitialize.complete(true);
          await tester.pump();
        },
      );
    });
  });
}

Widget _screen(GlobalKey<VideoPlayerScreenState> key, {CompanionRemoteProvider? remote}) {
  final app = MaterialApp(
    home: VideoPlayerScreen(
      key: key,
      metadata: testMediaItem(title: 'Companion target test'),
      isOffline: true,
    ),
  );
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => PlaybackStateProvider()),
      if (remote != null) ChangeNotifierProvider<CompanionRemoteProvider>.value(value: remote),
    ],
    child: app,
  );
}

RemoteDevice _controllerDevice() =>
    RemoteDevice(id: 'controller', name: 'Controller', platform: 'windows', connectedAt: DateTime(2026));

/// A host session whose sends are recorded instead of encrypted onto a socket.
class _RecordingRemote extends CompanionRemoteProvider {
  RemoteDevice? device;
  final List<Map<String, dynamic>> frames = [];

  /// Frames carrying playback detail — the bare `{playerActive}` frames the base
  /// binding sends on open/close are excluded.
  Iterable<Map<String, dynamic>> get statusFrames => frames.where((frame) => frame.length > 1);

  @override
  bool get isHost => true;

  @override
  bool get isConnected => true;

  @override
  RemoteDevice? get connectedDevice => device;

  @override
  void sendCommand(RemoteCommandType type, {Map<String, dynamic>? data}) {
    if (type == RemoteCommandType.syncState) frames.add(data ?? const {});
  }
}

class _ControlledSeekPlayer implements Player {
  _ControlledSeekPlayer({required Duration position})
    : _state = PlayerState(position: position, duration: const Duration(minutes: 10), seekable: true);

  final PlayerState _state;
  final List<Duration> seekTargets = [];
  Completer<void>? _seekCompleter;

  void completeSeek() {
    _seekCompleter?.complete();
    _seekCompleter = null;
  }

  @override
  PlayerState get state => _state;

  @override
  Future<void> seek(Duration position) {
    seekTargets.add(position);
    return (_seekCompleter = Completer<void>()).future;
  }

  @override
  Future<void> dispose({bool preserveDisplayMode = false}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

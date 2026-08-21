import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/companion_remote/remote_command.dart';
import 'package:plezy/mpv/mpv.dart';
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
        expect(playerA.seekTargets, [const Duration(seconds: 37)]);
        key.currentState!.player = playerB;
        playerA.completeSeek();
        await tester.pump();
        expect(playerB.seekTargets, isEmpty);

        key.currentState!.player = playerA;
        CompanionRemoteReceiver.instance.handleCommand(const RemoteCommand(type: RemoteCommandType.seekBackward), null);
        expect(playerA.seekTargets.last, const Duration(seconds: 23));
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
}

Widget _screen(GlobalKey<VideoPlayerScreenState> key) {
  return ChangeNotifierProvider(
    create: (_) => PlaybackStateProvider(),
    child: MaterialApp(
      home: VideoPlayerScreen(
        key: key,
        metadata: testMediaItem(title: 'Companion target test'),
        isOffline: true,
      ),
    ),
  );
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

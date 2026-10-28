import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/games/game_models.dart';
import 'package:plezy/multiview/steam_game_workspace_surface.dart';
import 'package:plezy/services/gamepad_service.dart';
import 'package:universal_gamepad/universal_gamepad.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const channel = MethodChannel('com.plezy/games/steam_stream/99');
  Future<void> state(String state) {
    final done = Completer<void>();
    messenger.handlePlatformMessage(
      channel.name,
      const StandardMethodCodec().encodeMethodCall(MethodCall('sessionState', state)),
      (_) => done.complete(),
    );
    return done.future;
  }

  SteamGameWorkspaceSession session({void Function()? onFirstFrame}) {
    final host = GameHost(id: '123', name: 'Desktop', address: 'desktop.local', protocol: GameProtocol.steam);
    return SteamGameWorkspaceSession(
      host: host,
      game: StreamGame(hostKey: host.key, id: '620', name: 'Portal 2'),
      touchControls: false,
      onFirstFrame: onFirstFrame,
    );
  }

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('closing diagnostics cannot reclaim a retired input lease', () async {
    final commands = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      commands.add(call);
      return call.method == 'getSessionState' ? 'playing' : null;
    });
    final stream = session();
    addTearDown(stream.dispose);
    stream.attachPlatformView(99);
    await state('playing');
    await stream.setInputEnabled(true);
    final closed = Completer<void>(), opened = Completer<void>();
    final dialog = stream.withInputSuspended(() async {
      opened.complete();
      await closed.future;
    });
    await opened.future;
    expect(commands.last.arguments, {'enabled': false});
    await state('playing'); // A duplicate state callback must not restore input.
    expect(commands.last.arguments, {'enabled': false});
    await stream.setInputEnabled(false); // Another pane/profile took ownership.
    closed.complete();
    await dialog;
    expect(commands.last.arguments, {'enabled': false});
  });

  test('missing metrics support preserves the stream', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getSessionState') return 'playing';
      if (call.method == 'getStreamMetrics') throw MissingPluginException();
      return null;
    });
    final stream = session();
    addTearDown(stream.dispose);
    stream.attachPlatformView(99);
    await state('playing');
    expect(await stream.readMetrics(), isNull);
    expect(stream.sessionState.value, 'playing');
  });

  test('controller events retain device identity and disconnect releases only that controller', () async {
    final commands = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      commands.add(call);
      return call.method == 'getSessionState' ? 'playing' : null;
    });
    final stream = session();
    addTearDown(stream.dispose);
    stream.attachPlatformView(99);
    await state('playing');
    await stream.setInputEnabled(true);
    commands.clear();
    final gamepads = GamepadService.instance;
    gamepads.debugSetWindowFocused(true);
    gamepads.debugHandleGamepadEvent(
      GamepadButtonEvent(gamepadId: 12, timestamp: 1, button: GamepadButton.a, pressed: true, value: 1),
    );
    gamepads.debugHandleGamepadEvent(
      GamepadAxisEvent(gamepadId: 23, timestamp: 2, axis: GamepadAxis.leftStickX, value: .5),
    );
    gamepads.debugHandleGamepadEvent(
      GamepadConnectionEvent(
        gamepadId: 12,
        timestamp: 3,
        connected: false,
        info: const GamepadInfo(id: 12, name: 'First'),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(commands.map((c) => c.method), [
      'setControllerDeviceState',
      'setControllerDeviceState',
      'disconnectController',
    ]);
    expect(commands[0].arguments, {
      'deviceId': 12,
      'buttons': {'a': true},
    });
    expect(commands[1].arguments, {
      'deviceId': 23,
      'axes': {'leftStickX': .5},
    });
    expect(commands[2].arguments, {'deviceId': 12});
    await stream.setInputEnabled(false);
    expect(commands.any((c) => c.method == 'resetInput'), isTrue);
    commands.clear();
    stream.handleInput(
      GamepadButtonEvent(gamepadId: 23, timestamp: 4, button: GamepadButton.b, pressed: true, value: 1),
    );
    expect(commands, isEmpty);
  });

  test('late attachment replay cannot replace a newer first-frame event', () async {
    final replay = Completer<String>();
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getSessionState') return replay.future;
      return null;
    });
    final stream = session();
    addTearDown(stream.dispose);
    stream.attachPlatformView(99);
    await state('playing');
    replay.complete('connecting');
    await Future<void>.delayed(Duration.zero);
    expect(stream.sessionState.value, 'playing');
  });

  test('state replay records first frame once and input waits for playback', () async {
    var frames = 0;
    final commands = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      commands.add(call);
      return call.method == 'getSessionState' ? 'connecting' : null;
    });
    final stream = session(onFirstFrame: () => frames++);
    addTearDown(stream.dispose);
    stream.attachPlatformView(99);
    await stream.setInputEnabled(true);
    expect(commands.where((c) => c.method == 'setInputEnabled').last.arguments, {'enabled': false});
    await state('playing');
    await state('playing');
    expect(frames, 1);
    expect(commands.where((c) => c.method == 'setInputEnabled').last.arguments, {'enabled': true});
    await state('failed');
    expect(commands.where((c) => c.method == 'setInputEnabled').last.arguments, {'enabled': false});
    expect(commands.last.method, 'resetInput');
    await state('untrusted-unknown-state');
    expect(stream.sessionState.value, 'failed');
  });

  test('reconnect waits for teardown, coalesces taps and ignores stale native states', () async {
    final stopped = Completer<void>();
    var disconnects = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getSessionState') return 'disconnected';
      if (call.method == 'disconnect') {
        disconnects++;
        await stopped.future;
      }
      return null;
    });
    final stream = session();
    addTearDown(stream.dispose);
    stream.attachPlatformView(99);
    await state('disconnected');
    final pending = stream.reconnect();
    await stream.reconnect();
    await state('playing');
    expect(stream.sessionState.value, 'reconnecting');
    expect(stream.surfaceGeneration.value, 0);
    expect(disconnects, 1);
    stopped.complete();
    await pending;
    expect(stream.surfaceGeneration.value, 1);
    expect(stream.sessionState.value, 'connecting');
  });

  test('failed teardown does not create an overlapping session', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getSessionState') return 'failed';
      if (call.method == 'disconnect') throw PlatformException(code: 'STREAM_STOP_PENDING');
      return null;
    });
    final stream = session();
    addTearDown(stream.dispose);
    stream.attachPlatformView(99);
    await state('failed');
    await stream.reconnect();
    expect(stream.surfaceGeneration.value, 0);
    expect(stream.sessionState.value, 'failed');
  });

  test('profile retirement during teardown cannot recreate its surface', () async {
    final stopped = Completer<void>();
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getSessionState') return 'failed';
      if (call.method == 'disconnect') await stopped.future;
      return null;
    });
    final stream = session();
    stream.attachPlatformView(99);
    await state('failed');
    var creations = 0;
    stream.surfaceGeneration.addListener(() => creations++);
    final pending = stream.reconnect();
    stream.dispose();
    stopped.complete();
    await pending;
    expect(creations, 0);
  });

  test('Steam workspace surface arguments stay structured and non-secret', () {
    final host = GameHost(
      id: '76561198000000000',
      name: 'Living room PC',
      address: '192.168.1.10',
      protocol: GameProtocol.steam,
      port: 27036,
    );
    final game = StreamGame(hostKey: host.key, id: '0', name: 'Big Picture');
    final session = SteamGameWorkspaceSession(host: host, game: game, touchControls: false);

    expect(session.creationParams, containsPair('hostId', host.id));
    expect(session.creationParams, containsPair('hostKey', 'steam:${host.id}'));
    expect(session.creationParams, containsPair('address', host.address));
    expect(session.creationParams, containsPair('port', 27036));
    expect(session.creationParams, containsPair('appId', '0'));
    expect(session.creationParams, containsPair('touchControls', false));
    expect(session.creationParams, containsPair('audioChannels', 2));
    expect(session.creationParams.keys, isNot(contains('password')));
    expect(SteamGameWorkspaceSession.channelNameForViewId(7), 'com.plezy/games/steam_stream/7');
    expect(session.workspaceSurface().key, same(session.workspaceSurface().key));

    session.dispose();
  });
}

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/watch_together/providers/watch_together_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/screens/video_player_screen.dart';
import 'package:plezy/services/playback_coordinator.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/media_items.dart';
import '../../test_helpers/prefs.dart';
import '../../test_helpers/pump.dart';
import '../../test_helpers/watch_together_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The route-global wakelock queue must stay on one FakeAsync clock.
  testWidgets('external display lifecycle preserves playback and runs paused cleanup independently', (tester) async {
    final player = _ExternalDisplayPlayer()..externalDisplayActive = false;
    final wakelockToggles = await _mountPlayer(tester, player);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await pumpUntil(tester, () => wakelockToggles.isNotEmpty && wakelockToggles.last);

    // A slow hidden pause must not hold up the independent paused cleanup.
    final pauseHold = Completer<void>();
    player.nextCommandFuture = pauseHold.future;
    addTearDown(() {
      if (!pauseHold.isCompleted) pauseHold.complete();
    });
    _lock(tester);
    await pumpUntil(tester, () => player.commandLog.contains('pause') && !wakelockToggles.last);
    expect(pauseHold.isCompleted, isFalse, reason: 'Cleanup must run before the slow player pause completes');
    expect(wakelockToggles.last, isFalse);
    pauseHold.complete();
    await pumpUntil(tester, () => !player.state.isActive && player.visibility.contains(false));
    player.externalDisplayActive = true;
    await player.play();
    _resume(tester);
    await pumpUntil(tester, () => wakelockToggles.last);
    player.commandLog.clear();
    player.visibility.clear();

    // Locking with external output must preserve playback and its surface.
    _lock(tester);
    await pumpUntil(tester, () => !wakelockToggles.last);
    expect(player.state.playing, isTrue);
    expect(player.commandLog, isNot(contains('pause')));
    expect(player.visibility, isEmpty, reason: 'The external video surface must stay visible while locked');
    _resume(tester);
    await pumpUntil(tester, () => wakelockToggles.last);

    // A delayed native result must not undo cleanup after returning to the app.
    final hiddenQueries = player.externalQueries;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await pumpUntil(tester, () => player.externalQueries > hiddenQueries);
    await tester.pump();

    final query = Completer<bool>();
    player.nextExternalDisplayQuery = query.future;
    addTearDown(() {
      if (!query.isCompleted) query.complete(false);
    });
    final previousQueries = player.externalQueries;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await pumpUntil(tester, () => player.externalQueries > previousQueries);
    _resume(tester);
    await pumpUntil(tester, () => wakelockToggles.isNotEmpty && wakelockToggles.last);
    query.complete(false);
    await tester.pump();
    await tester.pump();
    expect(wakelockToggles.last, isTrue, reason: 'A stale paused query must not undo resumed cleanup');
    expect(player.state.isActive, isTrue);
  });
}

Future<List<bool>> _mountPlayer(WidgetTester tester, _ExternalDisplayPlayer player) async {
  await initializeDateFormatting('en');
  tester.view.physicalSize = const Size(1200, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(const MethodChannel('window_manager'), (_) async => false);
  addTearDown(() => messenger.setMockMethodCallHandler(const MethodChannel('window_manager'), null));
  messenger.setMockMethodCallHandler(const MethodChannel('com.plezy/window_utils'), (_) async => null);
  addTearDown(() => messenger.setMockMethodCallHandler(const MethodChannel('com.plezy/window_utils'), null));
  final wakelockToggles = <bool>[];
  messenger.setMockMessageHandler(_wakelockToggleChannel, (message) async {
    final args = _wakelockCodec.decodeMessage(message) as List<Object?>;
    wakelockToggles.add((args.single! as List<Object?>).single! as bool);
    return _wakelockCodec.encodeMessage(<Object?>[]);
  });
  addTearDown(() => messenger.setMockMessageHandler(_wakelockToggleChannel, null));
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(() => tester.runAsync(db.close));
  resetSharedPreferencesForTest();
  SettingsService.resetForTesting();
  await SettingsService.getInstance();

  final initializationHold = Completer<void>();
  Future<void> holdInitialization() => initializationHold.future;
  PlaybackCoordinator.instance.registerMusicSession(stopAndDispose: holdInitialization);
  final key = GlobalKey<VideoPlayerScreenState>();
  addTearDown(() async {
    _resume(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    PlaybackCoordinator.instance.unregisterMusicSession(holdInitialization);
    if (!initializationHold.isCompleted) initializationHold.complete();
    await tester.pump();
  });

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlaybackStateProvider()),
        ChangeNotifierProvider(create: (_) => WatchTogetherProvider()),
        Provider<AppDatabase>.value(value: db),
      ],
      child: MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: VideoPlayerScreen(key: key, metadata: testMediaItem(), isOffline: true),
      ),
    ),
  );
  key.currentState!.player = player;
  await key.currentState!.debugMarkPlaybackStartedForTesting();
  await tester.pump();

  return wakelockToggles;
}

const _wakelockToggleChannel = 'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle';
const _wakelockCodec = _PigeonListCodec();

class _PigeonListCodec extends StandardMessageCodec {
  const _PigeonListCodec();

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) =>
      type >= 128 ? readValue(buffer) : super.readValueOfType(type, buffer);
}

class _ExternalDisplayPlayer extends FakeSyncPlayer {
  _ExternalDisplayPlayer() : super(playing: true);

  bool externalDisplayActive = true;
  int externalQueries = 0;
  Future<bool>? nextExternalDisplayQuery;
  final visibility = <bool>[];

  @override
  Future<bool> isExternalDisplayActive() async {
    externalQueries++;
    final pending = nextExternalDisplayQuery;
    nextExternalDisplayQuery = null;
    return pending != null ? await pending : externalDisplayActive;
  }

  @override
  Future<bool> setVisible(bool visible, {bool restoreOnWindowVisible = false}) async {
    visibility.add(visible);
    return true;
  }

  @override
  Future<void> updateFrame() async {}

  @override
  Future<void> abandonAudioFocus() async {}
}

void _lock(WidgetTester tester) {
  for (final state in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

void _resume(WidgetTester tester) {
  for (final state in [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

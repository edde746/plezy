import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/screens/video_player/media_controls_screen_controller.dart';
import 'package:plezy/screens/video_player/wakelock_controller.dart';
import 'package:plezy/services/media_controls_manager.dart';
import 'package:plezy/services/settings_service.dart';

import '../../test_helpers/media_items.dart';
import '../../test_helpers/prefs.dart';
import '../../test_helpers/watch_together_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const mediaControlChannel = MethodChannel('com.edde746.os_media_controls/methods');
  const mediaControlEvents = MethodChannel('com.edde746.os_media_controls/events');
  final calls = <MethodCall>[];

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
    calls.clear();
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(mediaControlChannel, (call) async {
      calls.add(call);
      return null;
    });
    messenger.setMockMethodCallHandler(mediaControlEvents, (call) async => null);
    final previousPlatformOverride = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = previousPlatformOverride);
  });

  tearDown(() {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(mediaControlChannel, null);
    messenger.setMockMethodCallHandler(mediaControlEvents, null);
  });

  List<Object?> argumentsOf(String method) =>
      calls.where((call) => call.method == method).expand((call) => call.arguments as List<Object?>).toList();

  test('a movie advertises previous, which restarts it, but no next', () async {
    final manager = MediaControlsManager();
    addTearDown(manager.dispose);
    final controller = _vodController(
      manager: manager,
      player: FakeSyncPlayer(position: const Duration(minutes: 30)),
      metadata: testMediaItem(kind: MediaKind.movie, title: 'Film'),
    );

    await controller.syncAvailability();

    expect(argumentsOf('enableControls'), contains('previous'));
    expect(argumentsOf('disableControls'), contains('next'));
    expect(argumentsOf('disableControls'), isNot(contains('previous')));
  });

  test('a Watch Together guest gets no previous on a movie', () async {
    final manager = MediaControlsManager();
    addTearDown(manager.dispose);
    final controller = _vodController(
      manager: manager,
      player: FakeSyncPlayer(position: const Duration(minutes: 30)),
      metadata: testMediaItem(kind: MediaKind.movie, title: 'Film'),
      canNavigateMediaItems: false,
    );

    await controller.syncAvailability();

    expect(argumentsOf('disableControls'), containsAll(<String>['previous', 'next']));
  });
}

MediaControlsScreenController _vodController({
  required MediaControlsManager manager,
  required FakeSyncPlayer player,
  required MediaItem metadata,
  bool canNavigateMediaItems = true,
}) {
  return MediaControlsScreenController(
    manager: () => manager,
    player: () => player,
    isMounted: () => true,
    isLive: false,
    hasLiveSeekWindow: () => false,
    hasNextLiveChannel: () => false,
    hasPreviousLiveChannel: () => false,
    shouldSkipForPip: () => false,
    isPlayerInitialized: () => true,
    metadata: () => metadata,
    client: () => null,
    isPlaylistActive: () => false,
    canControlPlayback: () => true,
    canNavigateMediaItems: () => canNavigateMediaItems,
    rewindOnResumeSeconds: () => 10,
    seek: (_) async {},
    play: (_) async {},
    wasPlayingBeforeInactive: () => false,
    clearWasPlayingBeforeInactive: () {},
    wakelock: WakelockController(),
    recordLifecycle: (_, {action}) {},
  );
}

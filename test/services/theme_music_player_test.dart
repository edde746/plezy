import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/models.dart';
import 'package:plezy/mpv/player/player.dart';
import 'package:plezy/mpv/player/player_stream_controllers.dart';
import 'package:plezy/mpv/player/player_streams.dart';
import 'package:plezy/services/playback_coordinator.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/theme_music_player.dart';

import '../test_helpers/prefs.dart';

class _FakeThemePlayer with PlayerStreamControllersMixin implements Player {
  late final PlayerStreams _streams = createStreams();
  final List<double> volumes = [];
  final List<String> openedUris = [];
  int pauseCalls = 0;
  int playCalls = 0;

  @override
  PlayerStreams get streams => _streams;

  @override
  Future<void> open(
    Media media, {
    bool play = true,
    bool isLive = false,
    List<SubtitleTrack>? externalSubtitles,
    Duration? timelineDuration,
    Duration timelineOffset = Duration.zero,
  }) async {
    openedUris.add(media.uri);
  }

  @override
  Future<void> setProperty(String name, String value) async {}

  @override
  Future<void> setVolume(double volume) async => volumes.add(volume);

  @override
  Future<void> play() async => playCalls++;

  @override
  Future<void> pause() async => pauseCalls++;

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose({bool preserveDisplayMode = false}) async {
    await closeStreamControllers();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() async {
    resetSharedPreferencesForTest();
    await SettingsService.getInstance();
  });

  testWidgets('defaults to 35% and updates the active player independently of music volume', (tester) async {
    final settings = SettingsService.instance;
    final player = _FakeThemePlayer();
    final service = ThemeMusicService(playerFactory: () => player, coordinator: PlaybackCoordinator.forTesting());
    addTearDown(service.dispose);
    final owner = Object();

    expect(settings.read(SettingsService.themeMusicVolume), 35);
    await service.play(owner, 'https://example.test/theme');
    await tester.pump(const Duration(milliseconds: 1200));
    expect(player.volumes.last, closeTo(35, 0.001));

    await settings.write(SettingsService.themeMusicVolume, 80.0);
    await tester.pump();
    expect(player.volumes.last, closeTo(80, 0.001));
    expect(settings.read(SettingsService.musicVolume), 100);

    await settings.write(SettingsService.themeMusicVolume, 0.0);
    await tester.pump();
    expect(player.volumes.last, 0);

    await settings.write(SettingsService.themeMusicVolume, 100.0);
    await tester.pump();
    expect(player.volumes.last, closeTo(100, 0.001));

    service.dispose();
    await tester.pump();
  });

  testWidgets('changing the volume during a fade preserves the fade and its new target', (tester) async {
    final settings = SettingsService.instance;
    final player = _FakeThemePlayer();
    final service = ThemeMusicService(playerFactory: () => player, coordinator: PlaybackCoordinator.forTesting());
    addTearDown(service.dispose);

    await service.play(Object(), 'https://example.test/theme');
    await tester.pump(const Duration(milliseconds: 600));
    expect(player.volumes.last, closeTo(17.5, 0.001));

    await settings.write(SettingsService.themeMusicVolume, 80.0);
    await tester.pump();
    expect(player.volumes.last, closeTo(40, 0.001));

    await tester.pump(const Duration(milliseconds: 600));
    expect(player.volumes.last, closeTo(80, 0.001));

    service.dispose();
    await tester.pump();
  });

  testWidgets('a volume change while paused takes effect on resume', (tester) async {
    final settings = SettingsService.instance;
    final player = _FakeThemePlayer();
    final service = ThemeMusicService(playerFactory: () => player, coordinator: PlaybackCoordinator.forTesting());
    addTearDown(service.dispose);
    final owner = Object();

    await service.play(owner, 'https://example.test/theme');
    await tester.pump(const Duration(milliseconds: 1200));

    final paused = service.pause(owner);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await paused;
    expect(player.pauseCalls, 1);
    expect(player.volumes.last, closeTo(0, 0.001));

    await settings.write(SettingsService.themeMusicVolume, 65.0);
    await tester.pump();
    expect(player.volumes.last, closeTo(0, 0.001));

    final resumed = service.resume(owner);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));
    await resumed;
    expect(player.playCalls, 1);
    expect(player.volumes.last, closeTo(65, 0.001));

    service.dispose();
    await tester.pump();
  });

  testWidgets('stopping during a fade starts from the actual current level', (tester) async {
    final player = _FakeThemePlayer();
    final service = ThemeMusicService(playerFactory: () => player, coordinator: PlaybackCoordinator.forTesting());
    addTearDown(service.dispose);
    final owner = Object();

    await service.play(owner, 'https://example.test/theme');
    await tester.pump(const Duration(milliseconds: 600));
    expect(player.volumes.last, closeTo(17.5, 0.001));

    final stopped = service.stop(owner);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(player.volumes.last, closeTo(8.75, 0.001));
    await tester.pump(const Duration(milliseconds: 200));
    await stopped;
    expect(player.volumes.last, closeTo(0, 0.001));

    service.dispose();
    await tester.pump();
  });

  testWidgets('replayed themes use the saved volume and disposal stops observing it', (tester) async {
    final settings = SettingsService.instance;
    await settings.write(SettingsService.themeMusicVolume, 60.0);
    final player = _FakeThemePlayer();
    final service = ThemeMusicService(playerFactory: () => player, coordinator: PlaybackCoordinator.forTesting());
    addTearDown(service.dispose);

    await service.play(Object(), 'https://example.test/theme');
    await tester.pump(const Duration(milliseconds: 1200));
    player.completedController.add(true);
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 1200));
    expect(player.openedUris, hasLength(2));
    expect(player.volumes.last, closeTo(60, 0.001));

    service.dispose();
    await tester.pump();
    final callsAfterDispose = player.volumes.length;
    await settings.write(SettingsService.themeMusicVolume, 25.0);
    await tester.pump();
    expect(player.volumes, hasLength(callsAfterDispose));
  });
}

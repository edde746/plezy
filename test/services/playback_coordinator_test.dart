import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/playback_coordinator.dart';

void main() {
  final coordinator = PlaybackCoordinator.instance;

  test('music claim releases the theme session', () async {
    var themeStops = 0;
    Future<void> stopTheme() async => themeStops++;

    coordinator.registerThemeSession(stopAndDispose: stopTheme);
    addTearDown(() => coordinator.unregisterThemeSession(stopTheme));

    await coordinator.claimMusic();

    expect(themeStops, 1);
  });

  test('theme claim releases the music session', () async {
    var musicStops = 0;
    Future<void> stopMusic() async => musicStops++;

    coordinator.registerMusicSession(stopAndDispose: stopMusic);
    addTearDown(() => coordinator.unregisterMusicSession(stopMusic));

    await coordinator.claimTheme();

    expect(musicStops, 1);
  });

  test('video claim releases music before theme', () async {
    final stops = <String>[];
    Future<void> stopMusic() async => stops.add('music');
    Future<void> stopTheme() async => stops.add('theme');

    coordinator.registerMusicSession(stopAndDispose: stopMusic);
    coordinator.registerThemeSession(stopAndDispose: stopTheme);
    addTearDown(() {
      coordinator.unregisterMusicSession(stopMusic);
      coordinator.unregisterThemeSession(stopTheme);
    });

    await coordinator.claimVideo();

    expect(stops, ['music', 'theme']);
  });
}
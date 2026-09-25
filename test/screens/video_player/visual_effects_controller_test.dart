import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plezy/mpv/player/player.dart';
import 'package:plezy/mpv/player/player_state.dart';
import 'package:plezy/providers/shader_provider.dart';
import 'package:plezy/screens/video_player/visual_effects_controller.dart';
import 'package:plezy/services/ambient_lighting_service.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/video_filter_manager.dart';
import 'package:plezy/widgets/video_controls/widgets/player_toast_indicator.dart';

import '../../test_helpers/io_fakes.dart';
import '../../test_helpers/media_items.dart';
import '../../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PathProviderPlatform previousPathProvider;
  late Directory tmpRoot;

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    final settings = await SettingsService.getInstance();
    await settings.write(SettingsService.ambientLighting, true);
    previousPathProvider = PathProviderPlatform.instance;
    tmpRoot = Directory.systemTemp.createTempSync('plezy_visual_effects_test_');
    PathProviderPlatform.instance = FakePathProvider(tmpRoot);
  });

  tearDown(() {
    SettingsService.resetForTesting();
    PathProviderPlatform.instance = previousPathProvider;
    tmpRoot.deleteSync(recursive: true);
  });

  // #2447: the next episode played in place with ambient lighting on placed
  // its subtitles against the whole window. The first-frame pass re-reads the
  // picture aspect from dwidth/dheight, and the fill used to come from
  // video-aspect-override, which mpv folds into exactly those properties.
  test('an in-place swap places subtitles against the new picture, not the window', () async {
    final player = _MpvGeometryPlayer(width: 1920, height: 1080);
    final ambientLighting = AmbientLightingService(player);
    // A 20:9 phone in landscape, so the window aspect differs from both items.
    final filterManager = VideoFilterManager(player: player, initialPlayerSize: const Size(2400, 1080));
    final shaderProvider = ShaderProvider();
    final toast = PlayerToastController();
    addTearDown(filterManager.dispose);
    addTearDown(shaderProvider.dispose);
    addTearDown(toast.dispose);

    final controller = VisualEffectsController(
      player: () => player,
      shaderService: () => null,
      ambientLighting: () => ambientLighting,
      filterManager: () => filterManager,
      metadata: () => testMediaItem(),
      shaderProvider: () => shaderProvider,
      isMounted: () => true,
      requestRebuild: () {},
      toast: toast,
    );

    controller.armAmbientRestore();
    await controller.onFirstFrame();
    expect(ambientLighting.isEnabled, isTrue);
    expect(player.subtitleRectAspect, closeTo(16 / 9, 0.0001));

    // The next item loads into the same player with the effect still on.
    player.loadPicture(width: 1920, height: 800);
    await controller.onFirstFrame();

    expect(ambientLighting.isEnabled, isTrue);
    expect(player.subtitleRectAspect, closeTo(2.4, 0.0001));
  });
}

/// Answers picture geometry the way mpv does: `video-aspect-override` rewrites
/// the display size `dwidth`/`dheight` report, `keepaspect` only changes how
/// the VO scales the frame and leaves them alone.
class _MpvGeometryPlayer implements Player {
  _MpvGeometryPlayer({required this._width, required this._height});

  int _width;
  int _height;
  double? _aspectOverride;
  double? subtitleRectAspect;

  void loadPicture({required int width, required int height}) {
    _width = width;
    _height = height;
  }

  @override
  PlayerState get state => const PlayerState();

  @override
  String get playerType => 'mpv';

  @override
  Future<String?> getProperty(String name) async {
    final override = _aspectOverride;
    return switch (name) {
      'dwidth' => '$_width',
      'dheight' => override == null ? '$_height' : '${(_width / override).round()}',
      _ => null,
    };
  }

  @override
  Future<void> setProperty(String name, String value) async {
    switch (name) {
      case 'video-aspect-override':
        _aspectOverride = value == 'no' ? null : double.parse(value);
      case 'sub-video-rect-aspect':
        subtitleRectAspect = value == 'no' ? null : double.parse(value);
    }
  }

  @override
  Future<void> command(List<String> args) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

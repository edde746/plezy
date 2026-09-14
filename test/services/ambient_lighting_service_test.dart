import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plezy/mpv/player/player.dart';
import 'package:plezy/mpv/player/player_state.dart';
import 'package:plezy/services/ambient_lighting_service.dart';

import '../test_helpers/io_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PathProviderPlatform originalPathProvider;
  late Directory temporaryRoot;

  setUp(() {
    originalPathProvider = PathProviderPlatform.instance;
    temporaryRoot = Directory.systemTemp.createTempSync('plezy_ambient_test_');
    PathProviderPlatform.instance = FakePathProvider(temporaryRoot);
  });

  tearDown(() {
    PathProviderPlatform.instance = originalPathProvider;
    temporaryRoot.deleteSync(recursive: true);
  });

  test('resize property failure is contained while ambient lighting remains enabled', () async {
    final player = _AmbientPlayer();
    final service = AmbientLightingService(player);

    await service.enable(16 / 9, 4 / 3);
    expect(service.isEnabled, isTrue);

    player.setPropertyError = StateError('rejected');
    service.updateOutputAspect(2);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(service.isEnabled, isTrue);
    expect(player.propertyWrites.last, ('video-aspect-override', '2.0'));
  });

  test('valid resize property write is applied once', () async {
    final player = _AmbientPlayer();
    final service = AmbientLightingService(player);

    await service.enable(16 / 9, 4 / 3);
    final writesBeforeResize = player.propertyWrites.length;

    service.updateOutputAspect(2);
    await Future<void>.delayed(Duration.zero);

    expect(player.propertyWrites, hasLength(writesBeforeResize + 1));
    expect(player.propertyWrites.last, ('video-aspect-override', '2.0'));
  });

  test('enable hands mpv the picture aspect for subtitle placement before overriding the frame', () async {
    final player = _AmbientPlayer();
    final service = AmbientLightingService(player);

    await service.enable(16 / 9, 20 / 9);

    final subRect = player.propertyWrites.indexWhere((write) => write.$1 == 'sub-video-rect-aspect');
    final override = player.propertyWrites.indexWhere((write) => write.$1 == 'video-aspect-override');
    expect(subRect, isNot(-1));
    expect(override, isNot(-1));
    expect(subRect, lessThan(override));
    expect(double.parse(player.propertyWrites[subRect].$2), closeTo(16 / 9, 0.0001));
    expect(double.parse(player.propertyWrites[override].$2), closeTo(20 / 9, 0.0001));
  });

  test('disable restores subtitle placement to the displayed video rect', () async {
    final player = _AmbientPlayer();
    final service = AmbientLightingService(player);

    await service.enable(16 / 9, 20 / 9);
    player.propertyWrites.clear();
    await service.disable();

    expect(service.isEnabled, isFalse);
    expect(player.propertyWrites, containsAll([('video-aspect-override', 'no'), ('sub-video-rect-aspect', 'no')]));
  });

  test('a rejected subtitle rect write leaves the frame aspect untouched', () async {
    final player = _AmbientPlayer()..setPropertyError = StateError('unknown property');
    final service = AmbientLightingService(player);

    await service.enable(16 / 9, 20 / 9);

    expect(service.isEnabled, isFalse);
    expect(player.propertyWrites.map((write) => write.$1), isNot(contains('video-aspect-override')));
  });
}

class _AmbientPlayer implements Player {
  final List<(String, String)> propertyWrites = [];
  Object? setPropertyError;

  @override
  PlayerState get state => const PlayerState();

  @override
  String get playerType => 'mpv';

  @override
  Future<void> command(List<String> command) async {}

  @override
  Future<void> setProperty(String name, String value) {
    propertyWrites.add((name, value));
    final error = setPropertyError;
    if (error != null) return Future<void>.error(error);
    return Future<void>.value();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

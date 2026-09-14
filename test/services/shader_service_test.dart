import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plezy/models/shader_preset.dart';
import 'package:plezy/mpv/player/player.dart';
import 'package:plezy/services/shader_service.dart';

import '../test_helpers/io_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PathProviderPlatform originalPathProvider;
  late Directory root;

  setUp(() async {
    originalPathProvider = PathProviderPlatform.instance;
    root = await Directory.systemTemp.createTemp('plezy_shader_service_test_');
    PathProviderPlatform.instance = FakePathProvider(root);
  });

  tearDown(() async {
    PathProviderPlatform.instance = originalPathProvider;
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('an escaped custom preset never reaches the MPV shader append command', () async {
    final supportDirectory = Directory(path.join(root.path, 'support'))..createSync(recursive: true);
    final sentinel = File(path.join(supportDirectory.path, 'sentinel.glsl'))..writeAsStringSync('sentinel');
    final player = _RecordingPlayer();
    final service = ShaderService(player);
    const preset = ShaderPreset(
      id: 'custom_traversal',
      name: 'Traversal',
      type: ShaderPresetType.custom,
      fileName: '../sentinel.glsl',
    );

    await service.applyPreset(preset);

    expect(player.commands.where((command) => command.length > 2 && command[2] == 'append'), isEmpty);
    expect(player.commands.single, ['change-list', 'glsl-shaders', 'clr', '']);
    expect(await sentinel.readAsString(), 'sentinel');
  });
}

class _RecordingPlayer implements Player {
  final commands = <List<String>>[];

  @override
  String get playerType => 'mpv';

  @override
  Future<void> command(List<String> args) async {
    commands.add(List.unmodifiable(args));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

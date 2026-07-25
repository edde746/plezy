import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plezy/models/shader_preset.dart';
import 'package:plezy/services/shader_asset_loader.dart';

import '../test_helpers/io_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PathProviderPlatform originalPathProvider;
  late Directory root;
  late Directory supportDirectory;
  late File sentinel;

  setUp(() async {
    originalPathProvider = PathProviderPlatform.instance;
    root = await Directory.systemTemp.createTemp('plezy_shader_asset_loader_test_');
    PathProviderPlatform.instance = FakePathProvider(root);
    supportDirectory = Directory(path.join(root.path, 'support'))..createSync(recursive: true);
    sentinel = File(path.join(supportDirectory.path, 'sentinel.glsl'))..writeAsStringSync('sentinel');
    ShaderAssetLoader.clearCache();
  });

  tearDown(() async {
    PathProviderPlatform.instance = originalPathProvider;
    ShaderAssetLoader.clearCache();
    if (await root.exists()) await root.delete(recursive: true);
  });

  ShaderPreset customPreset(String fileName) {
    return ShaderPreset(id: 'custom_$fileName', name: fileName, type: ShaderPresetType.custom, fileName: fileName);
  }

  Future<List<int>> bundledBytes(String assetPath) async {
    final data = await rootBundle.load('assets/shaders/$assetPath');
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  Future<void> expectBundledFile(String filePath, String assetPath) async {
    expect(await File(filePath).readAsBytes(), await bundledBytes(assetPath));
  }

  test('traversal and absolute names cannot load or delete outside managed directory', () async {
    for (final fileName in ['../sentinel.glsl', sentinel.path]) {
      expect(await ShaderAssetLoader.getShadersForPreset(customPreset(fileName)), isEmpty);
      await ShaderAssetLoader.deleteCustomShader(fileName);
      expect(await sentinel.readAsString(), 'sentinel');
    }
  });

  test('repairs stale built-in bytes in the application cache without touching temporary storage', () async {
    final cacheFile = File(path.join(root.path, 'cache', 'shaders', 'nvscaler', 'NVScaler.glsl'))
      ..createSync(recursive: true)
      ..writeAsStringSync('stale');
    final oldTemporaryFile = File(path.join(root.path, 'temp', 'shaders', 'nvscaler', 'NVScaler.glsl'))
      ..createSync(recursive: true)
      ..writeAsStringSync('old temporary sentinel');

    final shaders = await ShaderAssetLoader.getShadersForPreset(ShaderPreset.nvscalerDefault);

    expect(shaders, [cacheFile.path]);
    await expectBundledFile(shaders.single, 'nvscaler/NVScaler.glsl');
    expect(await oldTemporaryFile.readAsString(), 'old temporary sentinel');
  });

  test('recovers a truncated built-in final through a complete staged replacement', () async {
    final targetDirectory = Directory(path.join(root.path, 'cache', 'shaders', 'nvscaler'))
      ..createSync(recursive: true);
    final target = File(path.join(targetDirectory.path, 'NVScaler.glsl'))..writeAsBytesSync([1, 2, 3]);
    final unrelatedPending = File('${target.path}.pending.interrupted')..writeAsBytesSync([1]);

    final shaders = await ShaderAssetLoader.getNVScalerShaders();

    expect(shaders, [target.path]);
    await expectBundledFile(target.path, 'nvscaler/NVScaler.glsl');
    expect(unrelatedPending.existsSync(), isTrue);
    final ownedPending = await targetDirectory
        .list()
        .where((entry) => entry.path.contains('.pending.') && entry.path != unrelatedPending.path)
        .toList();
    expect(ownedPending, isEmpty);
  });

  test('does not return a partial path when final-file promotion fails', () async {
    final target = Directory(path.join(root.path, 'cache', 'shaders', 'nvscaler', 'NVScaler.glsl'))
      ..createSync(recursive: true);

    expect(await ShaderAssetLoader.getNVScalerShaders(), isEmpty);

    final siblings = await target.parent.list().toList();
    expect(siblings.where((entry) => entry.path.contains('.pending.')), isEmpty);
    expect(target.existsSync(), isTrue);
  });

  test('coalesces concurrent built-in loads onto one complete final path', () async {
    final results = await Future.wait([ShaderAssetLoader.getNVScalerShaders(), ShaderAssetLoader.getNVScalerShaders()]);

    expect(results[0], results[1]);
    expect(results[0], hasLength(1));
    await expectBundledFile(results[0].single, 'nvscaler/NVScaler.glsl');
    final directory = File(results[0].single).parent;
    expect((await directory.list().toList()).where((entry) => entry.path.contains('.pending.')), isEmpty);
  });

  test('materializes representative built-in chains in MPV order with bundled bytes', () async {
    final nvscaler = await ShaderAssetLoader.getNVScalerShaders();
    final artcnn = await ShaderAssetLoader.getArtCNNShaders(
      const ArtCNNConfig(model: ArtCNNModel.c4f16, variant: ArtCNNVariant.denoise),
    );
    final anime4k = await ShaderAssetLoader.getAnime4KShaders(
      const Anime4KConfig(quality: Anime4KQuality.fast, mode: Anime4KMode.modeB),
    );

    final expected = {
      nvscaler.single: 'nvscaler/NVScaler.glsl',
      artcnn.single: 'artcnn/ArtCNN_C4F16_DN.glsl',
      anime4k[0]: 'anime4k/Anime4K_Clamp_Highlights.glsl',
      anime4k[1]: 'anime4k/Anime4K_Restore_CNN_M.glsl',
      anime4k[2]: 'anime4k/Anime4K_Upscale_CNN_x2_M.glsl',
      anime4k[3]: 'anime4k/Anime4K_AutoDownscalePre_x2.glsl',
    };
    expect(anime4k.map(path.basename).toList(), [
      'Anime4K_Clamp_Highlights.glsl',
      'Anime4K_Restore_CNN_M.glsl',
      'Anime4K_Upscale_CNN_x2_M.glsl',
      'Anime4K_AutoDownscalePre_x2.glsl',
    ]);
    for (final entry in expected.entries) {
      expect(path.isWithin(path.join(root.path, 'cache'), entry.key), isTrue);
      await expectBundledFile(entry.key, entry.value);
    }
  });

  test('nested and non-GLSL names are rejected without touching matching files', () async {
    final customDirectory = Directory(path.join(supportDirectory.path, 'custom_shaders'))..createSync(recursive: true);
    final nested = File(path.join(customDirectory.path, 'subdir', 'name.glsl'))
      ..createSync(recursive: true)
      ..writeAsStringSync('nested');
    final extraExtension = File(path.join(customDirectory.path, 'name.glsl.txt'))..writeAsStringSync('extra');

    for (final fileName in ['subdir/name.glsl', r'subdir\name.glsl', '.', '..', 'name.glsl.txt', 'name.txt']) {
      expect(ShaderAssetLoader.isValidCustomShaderFileName(fileName), isFalse);
      expect(await ShaderAssetLoader.getShadersForPreset(customPreset(fileName)), isEmpty);
      await ShaderAssetLoader.deleteCustomShader(fileName);
    }

    expect(await nested.readAsString(), 'nested');
    expect(await extraExtension.readAsString(), 'extra');
  });

  test('non-GLSL import fails before creating a managed file', () async {
    final source = File(path.join(root.path, 'shader.txt'))..writeAsStringSync('not glsl');

    await expectLater(ShaderAssetLoader.importCustomShader(source.path), throwsArgumentError);

    final customDirectory = Directory(path.join(supportDirectory.path, 'custom_shaders'));
    expect(customDirectory.existsSync(), isFalse);
  });

  test('imports a direct UUID GLSL child and deletes only that file', () async {
    final source = File(path.join(root.path, 'shader.GLSL'))..writeAsStringSync('shader');

    final storedName = await ShaderAssetLoader.importCustomShader(source.path);
    expect(storedName, matches(RegExp(r'^[0-9a-f-]+\.glsl$')));
    expect(ShaderAssetLoader.isValidCustomShaderFileName(storedName), isTrue);

    final shaders = await ShaderAssetLoader.getShadersForPreset(customPreset(storedName));
    expect(shaders, hasLength(1));
    expect(path.equals(path.dirname(shaders.single), path.join(supportDirectory.path, 'custom_shaders')), isTrue);
    expect(await File(shaders.single).readAsString(), 'shader');

    await ShaderAssetLoader.deleteCustomShader(storedName);
    expect(File(shaders.single).existsSync(), isFalse);
    expect(await source.readAsString(), 'shader');
  });

  test('legacy base-36 managed names remain loadable and deletable', () async {
    const storedName = 'ks9p7.glsl';
    final customDirectory = Directory(path.join(supportDirectory.path, 'custom_shaders'))..createSync(recursive: true);
    final managedFile = File(path.join(customDirectory.path, storedName))..writeAsStringSync('legacy');

    expect(ShaderAssetLoader.isValidCustomShaderFileName(storedName), isTrue);
    final shaders = await ShaderAssetLoader.getShadersForPreset(customPreset(storedName));
    expect(shaders, hasLength(1));
    expect(path.equals(shaders.single, managedFile.path), isTrue);

    await ShaderAssetLoader.deleteCustomShader(storedName);
    expect(managedFile.existsSync(), isFalse);
  });
}

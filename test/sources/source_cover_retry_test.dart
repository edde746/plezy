import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plezy/sources/source_controller.dart';
import 'package:plezy/sources/source_database.dart';
import 'package:plezy/sources/source_models.dart';

import '../test_helpers/io_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('retry replaces a cached cover miss and repairs a corrupt cached file', () async {
    final root = Directory.systemTemp.createTempSync('plezy-cover-retry-');
    final previous = PathProviderPlatform.instance;
    PathProviderPlatform.instance = FakePathProvider(root);
    final repository = SourceRepository(SourceDatabase(NativeDatabase.memory()));
    final controller = SourceController(repository: repository);
    await controller.ready;
    controller.profileId = 'alice';
    controller.blocked = false;
    controller.sources = [
      FileSource(id: 'local', profileId: 'alice', kind: FileSourceKind.local, name: 'Local', root: root.path),
    ];
    const entry = SourceEntry(
      id: 'book',
      sourceId: 'local',
      title: 'Book',
      kind: SourceItemKind.ebook,
      coverId: 'cover.png',
    );
    try {
      expect(await controller.cover(entry), isNull);
      File('${root.path}/cover.png').writeAsBytesSync(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAFklEQVR4nGOcFmDEwMDAxMDAwMDAAAANrgEcyQYr6AAAAABJRU5ErkJggg==',
        ),
      );
      expect(await controller.cover(entry), isNull);
      final recovered = await controller.cover(entry, refresh: true);
      expect(recovered, isNotNull);
      expect(recovered!.existsSync(), isTrue);
      final original = recovered.readAsBytesSync();
      recovered.writeAsStringSync('corrupt cached image');
      final repaired = await controller.cover(entry, refresh: true);
      expect(repaired!.readAsBytesSync(), original);
      controller.blocked = true;
      expect(await controller.cover(entry, refresh: true), isNull);
    } finally {
      controller.dispose();
      await Future<void>.delayed(Duration.zero);
      PathProviderPlatform.instance = previous;
      root.deleteSync(recursive: true);
    }
  });
}

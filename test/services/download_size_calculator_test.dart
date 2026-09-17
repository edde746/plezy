import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plezy/services/download_size_calculator.dart';
import 'package:plezy/services/download_storage_service.dart';
import 'package:plezy/services/saf_storage_service.dart';
import 'package:saf_util/saf_util_platform_interface.dart';

import '../test_helpers/io_fakes.dart';

/// Answers [stat] from a fixed URI → length map; nothing else is reachable.
class _StatOnlySafStorage implements SafStorageOperations {
  _StatOnlySafStorage(this.lengths);

  final Map<String, int> lengths;

  @override
  Future<SafDocumentFile?> stat(String uri, {required bool isDir}) async {
    final length = lengths[uri];
    if (length == null) return null;
    return SafDocumentFile(uri: uri, name: p.basename(uri), isDir: isDir, length: length, lastModified: 0);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError('${invocation.memberName}');
}

void main() {
  late Directory tmpRoot;
  late PathProviderPlatform previousPathProvider;

  setUp(() async {
    DownloadStorageService.resetForTesting();
    tmpRoot = await Directory.systemTemp.createTemp('dsc_test_');
    previousPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = FakePathProvider(tmpRoot);
  });

  tearDown(() async {
    DownloadStorageService.resetForTesting();
    PathProviderPlatform.instance = previousPathProvider;
    if (await tmpRoot.exists()) await tmpRoot.delete(recursive: true);
  });

  Future<File> writeBytes(String filePath, int length) async {
    final file = File(filePath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(List.filled(length, 0));
    return file;
  }

  DownloadSizeCalculator calculator({Map<String, int> safLengths = const {}}) =>
      DownloadSizeCalculator(storage: DownloadStorageService.instance, saf: _StatOnlySafStorage(safLengths));

  group('DownloadSizeCalculator', () {
    test('counts the media file, same-name sidecars, and the subtitles folder', () async {
      final seasonDir = p.join(tmpRoot.path, 'downloads', 'TV Shows', 'Show (2020)', 'Season 01');
      final video = await writeBytes(p.join(seasonDir, 'S01E01 - Pilot.mkv'), 1000);
      await writeBytes(p.join(seasonDir, 'S01E01 - Pilot.jpg'), 50);
      await writeBytes(p.join(seasonDir, 'S01E01 - Pilot_subs', '3.srt'), 20);
      await writeBytes(p.join(seasonDir, 'S01E01 - Pilot_subs', 'nested', '4.ass'), 5);
      // A sibling episode in the same season folder must not be counted.
      await writeBytes(p.join(seasonDir, 'S01E02 - Next.mkv'), 9000);
      await writeBytes(p.join(seasonDir, 'S01E02 - Next_subs', '3.srt'), 900);

      expect(await calculator().measure(video.path), 1075);
    });

    test('returns null when the media file is missing', () async {
      final missing = p.join(tmpRoot.path, 'downloads', 'Movies', 'Gone (2001)', 'Gone (2001).mkv');

      expect(await calculator().measure(missing), isNull);
    });

    test('uses the SAF document length for content:// downloads', () async {
      const uri = 'content://downloads/movie.mkv';

      expect(await calculator(safLengths: {uri: 4096}).measure(uri), 4096);
      expect(await calculator().measure(uri), isNull);
    });
  });
}

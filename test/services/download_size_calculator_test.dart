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
      // A sibling episode that was not asked about must not be counted.
      await writeBytes(p.join(seasonDir, 'S01E02 - Next.mkv'), 9000);
      await writeBytes(p.join(seasonDir, 'S01E02 - Next_subs', '3.srt'), 900);

      expect(await calculator().measureAll({'ep1': video.path}), {'ep1': 1075});
    });

    test('attributes files in a shared folder to each download', () async {
      final seasonDir = p.join(tmpRoot.path, 'downloads', 'TV Shows', 'Show (2020)', 'Season 01');
      final first = await writeBytes(p.join(seasonDir, 'S01E01 - Pilot.mkv'), 1000);
      await writeBytes(p.join(seasonDir, 'S01E01 - Pilot.jpg'), 50);
      final second = await writeBytes(p.join(seasonDir, 'S01E02 - Next.mp4'), 2000);
      await writeBytes(p.join(seasonDir, 'S01E02 - Next_subs', '3.srt'), 30);

      expect(await calculator().measureAll({'ep1': first.path, 'ep2': second.path}), {'ep1': 1050, 'ep2': 2030});
    });

    test('leaves out downloads whose media file is missing', () async {
      final movieDir = p.join(tmpRoot.path, 'downloads', 'Movies', 'Gone (2001)');
      // Sidecars alone do not make a download present.
      await writeBytes(p.join(movieDir, 'Gone (2001)_subs', '3.srt'), 20);
      final present = await writeBytes(
        p.join(tmpRoot.path, 'downloads', 'Movies', 'Here (2002)', 'Here (2002).mkv'),
        10,
      );

      expect(
        await calculator().measureAll({
          'gone': p.join(movieDir, 'Gone (2001).mkv'),
          'noFolder': p.join(tmpRoot.path, 'downloads', 'Movies', 'Never (2003)', 'Never (2003).mkv'),
          'here': present.path,
        }),
        {'here': 10},
      );
    });

    test('uses the SAF document length for content:// downloads', () async {
      const uri = 'content://downloads/movie.mkv';

      expect(await calculator(safLengths: {uri: 4096}).measureAll({'movie': uri}), {'movie': 4096});
      expect(await calculator().measureAll({'movie': uri}), isEmpty);
    });
  });
}

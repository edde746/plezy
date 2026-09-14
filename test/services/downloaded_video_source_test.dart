import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/database/download_operations.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/models/download_models.dart';
import 'package:plezy/services/download_storage_service.dart';
import 'package:plezy/services/downloaded_video_source.dart';
import 'package:plezy/services/saf_storage_service.dart';
import 'package:plezy/services/settings_service.dart';

import '../test_helpers/download_fixtures.dart';
import '../test_helpers/io_fakes.dart';
import '../test_helpers/prefs.dart';
import '../test_helpers/saf_fakes.dart';

/// A downloaded row only backs playback while its stored copy is actually
/// reachable. Returning null is what lets the caller stream from the server
/// instead of handing the player a dead path (issue #2101): a removable SAF
/// volume can be unmounted, and its documents disappear with it, while the row
/// still reads `completed`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late Directory tmpRoot;
  late PathProviderPlatform previousPathProvider;

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    DownloadStorageService.resetForTesting();
    tmpRoot = await Directory.systemTemp.createTemp('downloaded_video_source_test_');
    previousPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = FakePathProvider(tmpRoot);
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
    DownloadStorageService.resetForTesting();
    SafStorageService.setOpsForTesting(null);
    SettingsService.resetForTesting();
    PathProviderPlatform.instance = previousPathProvider;
    if (await tmpRoot.exists()) {
      await tmpRoot.delete(recursive: true);
    }
  });

  Future<DownloadedMediaItem> completedRow(String storedPath) async {
    const globalKey = 'srv-1:movie-1';
    await db.insertDownload(
      serverId: ServerId('srv-1'),
      ratingKey: 'movie-1',
      globalKey: globalKey,
      type: 'movie',
      status: DownloadStatus.completed.index,
      mediaIndex: 0,
      mediaSourceId: 'source-a',
    );
    await db.updateVideoFilePath(globalKey, storedPath);
    return (db.select(db.downloadedMedia)..where((t) => t.globalKey.equals(globalKey))).getSingle();
  }

  group('SAF copies', () {
    const safUri = 'content://com.android.externalstorage.documents/tree/79F7-B648%3A/document/movie-1.mkv';

    test('an unmounted volume yields no source so the caller can stream', () async {
      final row = await completedRow(safUri);
      final saf = FakeSafStorage(reachable: false);
      SafStorageService.setOpsForTesting(saf);

      expect(await resolveDownloadedVideoSource(row, requestedMediaIndex: 0), isNull);
      expect(saf.existsCalls, [safUri], reason: 'the stored document URI is what must be probed');
    });

    test('a reachable document plays from the stored URI', () async {
      final row = await completedRow(safUri);
      SafStorageService.setOpsForTesting(FakeSafStorage(existing: {safUri}));

      final source = await resolveDownloadedVideoSource(row, requestedMediaIndex: 0);

      expect(source?.path, safUri);
      expect(source?.mediaIndex, 0);
      expect(source?.mediaSourceId, 'source-a');
    });

    test('reachability is not consulted for a version that would be skipped anyway', () async {
      final row = await completedRow(safUri);
      final saf = FakeSafStorage();
      SafStorageService.setOpsForTesting(saf);

      expect(await resolveDownloadedVideoSource(row, requestedMediaIndex: 1), isNull);
      expect(saf.existsCalls, isEmpty);
    });
  });

  group('file copies', () {
    test('a deleted file yields no source', () async {
      final row = await completedRow('${tmpRoot.path}/gone.mkv');

      expect(await resolveDownloadedVideoSource(row, requestedMediaIndex: 0), isNull);
    });

    test('a present file resolves to its absolute path', () async {
      final video = File('${tmpRoot.path}/movie-1.mkv');
      await video.writeAsBytes(const <int>[0]);
      final row = await completedRow(video.path);

      final source = await resolveDownloadedVideoSource(row, requestedMediaIndex: 0);

      expect(source?.path, video.path);
    });
  });
}

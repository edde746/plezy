import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/services/download_storage_service.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../test_helpers/prefs.dart';

/// In-test fake PathProviderPlatform that points all directories at a real
/// on-disk temp folder. Required because the production service calls
/// [getApplicationDocumentsDirectory] / [getApplicationSupportDirectory] —
/// both of which fail outside an app context unless the platform interface
/// is mocked.
class _FakePathProvider extends PathProviderPlatform with MockPlatformInterfaceMixin {
  _FakePathProvider(this.root);

  final Directory root;
  String get _docs => p.join(root.path, 'documents');
  String get _support => p.join(root.path, 'support');
  String get _cache => p.join(root.path, 'cache');
  String get _temp => p.join(root.path, 'temp');

  @override
  Future<String?> getApplicationDocumentsPath() async => _ensure(_docs);

  @override
  Future<String?> getApplicationSupportPath() async => _ensure(_support);

  @override
  Future<String?> getApplicationCachePath() async => _ensure(_cache);

  @override
  Future<String?> getTemporaryPath() async => _ensure(_temp);

  String _ensure(String dir) {
    Directory(dir).createSync(recursive: true);
    return dir;
  }
}

void main() {
  late Directory tmpRoot;

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    DownloadStorageService.resetForTesting();
    tmpRoot = await Directory.systemTemp.createTemp('dss_test_');
    PathProviderPlatform.instance = _FakePathProvider(tmpRoot);
  });

  tearDown(() async {
    DownloadStorageService.resetForTesting();
    SettingsService.resetForTesting();
    if (await tmpRoot.exists()) {
      await tmpRoot.delete(recursive: true);
    }
  });

  // ============================================================
  // Singleton + reset
  // ============================================================

  group('singleton', () {
    test('instance returns same object across calls', () {
      final a = DownloadStorageService.instance;
      final b = DownloadStorageService.instance;
      expect(identical(a, b), isTrue);
    });

    test('resetForTesting yields a fresh instance', () {
      final first = DownloadStorageService.instance;
      DownloadStorageService.resetForTesting();
      final second = DownloadStorageService.instance;
      expect(identical(first, second), isFalse);
    });
  });

  // ============================================================
  // SAF mode (Android-only). On host (macOS/Linux) it is always false.
  // ============================================================

  group('SAF mode', () {
    test('isUsingSaf is false on the host (non-Android)', () async {
      final settings = await SettingsService.getInstance();
      // Even with SAF-shaped settings, host platform check must short-circuit.
      await settings.write(SettingsService.customDownloadPathType, 'saf');
      await settings.write(
        SettingsService.customDownloadPath,
        'content://com.android.externalstorage.documents/tree/primary%3ADownload',
      );

      final dss = DownloadStorageService.instance;
      await dss.initialize(settings);

      expect(Platform.isAndroid, isFalse, reason: 'host preflight: this test is meaningless on Android');
      expect(dss.isUsingSaf, isFalse);
      expect(dss.safBaseUri, isNull);
    });

    test('isSafUri detects content:// URIs regardless of platform', () {
      final dss = DownloadStorageService.instance;
      expect(dss.isSafUri('content://com.android.externalstorage.documents/tree/primary%3ADownload'), isTrue);
      expect(dss.isSafUri('/var/mobile/Containers/Data/Application/abc/Documents/downloads/x.mkv'), isFalse);
      expect(dss.isSafUri('file:///tmp/foo'), isFalse);
    });
  });

  // ============================================================
  // Default download directory + custom-path switching
  // ============================================================

  group('downloads directory resolution', () {
    test('defaults to <appSupport>/downloads on desktop hosts', () async {
      final settings = await SettingsService.getInstance();
      final dss = DownloadStorageService.instance;
      await dss.initialize(settings);

      final dir = await dss.getDownloadsDirectory();
      expect(dir.existsSync(), isTrue);
      // _getBaseAppDir returns getApplicationSupportDirectory() on desktop.
      expect(dir.path, p.join(p.join(tmpRoot.path, 'support'), 'downloads'));
      expect(dss.isUsingCustomPath(), isFalse);
    });

    test('honors a writable custom file-type path', () async {
      final settings = await SettingsService.getInstance();
      final customDir = Directory(p.join(tmpRoot.path, 'custom-downloads'))..createSync(recursive: true);

      await settings.write(SettingsService.customDownloadPathType, 'file');
      await settings.write(SettingsService.customDownloadPath, customDir.path);

      final dss = DownloadStorageService.instance;
      await dss.initialize(settings);

      final dir = await dss.getDownloadsDirectory();
      expect(dir.path, customDir.path);
      expect(dss.isUsingCustomPath(), isTrue);

      final display = await dss.getCurrentDownloadPathDisplay();
      expect(display, customDir.path);
    });

    test('falls back to default when custom path is non-writable', () async {
      final settings = await SettingsService.getInstance();

      // Point the custom path to a path inside a read-only parent.
      final readOnlyParent = Directory(p.join(tmpRoot.path, 'readonly'))..createSync(recursive: true);
      try {
        // Make parent unwritable so writing inside fails. Skip if the OS
        // ignores the chmod (e.g. when running as root).
        await Process.run('chmod', ['000', readOnlyParent.path]);
        final blocked = p.join(readOnlyParent.path, 'forbidden');
        await settings.write(SettingsService.customDownloadPathType, 'file');
        await settings.write(SettingsService.customDownloadPath, blocked);

        final dss = DownloadStorageService.instance;
        await dss.initialize(settings);

        final dir = await dss.getDownloadsDirectory();
        // Either the chmod worked → we fall back to default,
        // or it didn't → we used the custom path. Both are valid; the
        // important contract is that the call doesn't throw.
        expect(dir.existsSync(), isTrue);
        if (dir.path == blocked) {
          // chmod was a no-op (root or a filesystem that ignores it). Skip the
          // strict assertion — the fallback branch only runs when writes fail.
          return;
        }
        expect(dir.path, p.join(p.join(tmpRoot.path, 'support'), 'downloads'));
      } finally {
        await Process.run('chmod', ['755', readOnlyParent.path]);
      }
    });

    test('refreshCustomPath picks up settings changes', () async {
      final settings = await SettingsService.getInstance();
      final dss = DownloadStorageService.instance;
      await dss.initialize(settings);

      expect(dss.isUsingCustomPath(), isFalse);

      final newDir = Directory(p.join(tmpRoot.path, 'after-refresh'))..createSync(recursive: true);
      await settings.write(SettingsService.customDownloadPathType, 'file');
      await settings.write(SettingsService.customDownloadPath, newDir.path);

      await dss.refreshCustomPath();
      expect(dss.isUsingCustomPath(), isTrue);

      final dir = await dss.getDownloadsDirectory();
      expect(dir.path, newDir.path);
    });
  });

  // ============================================================
  // Artwork directory
  // ============================================================

  group('artwork directory', () {
    test('initializes alongside support directory by default and caches sync path', () async {
      final settings = await SettingsService.getInstance();
      final dss = DownloadStorageService.instance;
      await dss.initialize(settings);

      final artworkDir = await dss.getArtworkDirectory();
      expect(artworkDir.existsSync(), isTrue);
      expect(artworkDir.path, p.join(tmpRoot.path, 'support', 'artwork'));
      // After initialize() the sync path getter is populated.
      expect(dss.artworkDirectoryPath, artworkDir.path);
    });

    test('places artwork next to a custom downloads path', () async {
      final settings = await SettingsService.getInstance();

      final customDir = Directory(p.join(tmpRoot.path, 'media-root', 'downloads'))..createSync(recursive: true);
      await settings.write(SettingsService.customDownloadPathType, 'file');
      await settings.write(SettingsService.customDownloadPath, customDir.path);

      final dss = DownloadStorageService.instance;
      await dss.initialize(settings);

      final artworkDir = await dss.getArtworkDirectory();
      expect(artworkDir.path, p.join(customDir.parent.path, 'artwork'));
      expect(artworkDir.existsSync(), isTrue);
    });

    test('getArtworkPathSync returns null before initialize, deduplicates after', () async {
      final dss = DownloadStorageService.instance;
      // Before initialize() the sync getter is null.
      expect(dss.artworkDirectoryPath, isNull);
      expect(dss.getArtworkPathSync('srv', '/library/metadata/1/thumb'), isNull);

      final settings = await SettingsService.getInstance();
      await dss.initialize(settings);

      final p1 = dss.getArtworkPathSync('srv', '/library/metadata/1/thumb');
      final p2 = dss.getArtworkPathSync('srv', '/library/metadata/1/thumb');
      final p3 = dss.getArtworkPathSync('srv', '/library/metadata/2/thumb');
      expect(p1, isNotNull);
      // Same input → same path (MD5 of `serverId:thumbPath`).
      expect(p1, p2);
      expect(p1, isNot(p3));
      expect(p1!.endsWith('.jpg'), isTrue);
    });

    test('async + sync artwork paths agree for the same input', () async {
      final settings = await SettingsService.getInstance();
      final dss = DownloadStorageService.instance;
      await dss.initialize(settings);

      final asyncPath = await dss.getArtworkPathFromThumb('srv', '/library/metadata/9/thumb');
      final syncPath = dss.getArtworkPathSync('srv', '/library/metadata/9/thumb');
      expect(asyncPath, syncPath);
    });

    test('artworkExists reflects on-disk state', () async {
      final settings = await SettingsService.getInstance();
      final dss = DownloadStorageService.instance;
      await dss.initialize(settings);

      expect(await dss.artworkExists('srv', '/thumb/1'), isFalse);

      final filePath = await dss.getArtworkPathFromThumb('srv', '/thumb/1');
      await File(filePath).writeAsString('fake-artwork');
      expect(await dss.artworkExists('srv', '/thumb/1'), isTrue);
    });
  });

  // ============================================================
  // Path resolution helpers (relative <-> absolute)
  // ============================================================

  group('toRelativePath / toAbsolutePath', () {
    test('strips a single base-dir prefix to make a path relative', () async {
      final settings = await SettingsService.getInstance();
      final dss = DownloadStorageService.instance;
      await dss.initialize(settings);

      // Compute the support base the production code uses.
      final base = p.join(tmpRoot.path, 'support');
      final abs = p.join(base, 'downloads', 'srv', '42', 'video.mp4');
      final rel = await dss.toRelativePath(abs);
      expect(rel, p.join('downloads', 'srv', '42', 'video.mp4'));
    });

    test('returns input unchanged for absolute paths outside the base dir', () async {
      final settings = await SettingsService.getInstance();
      final dss = DownloadStorageService.instance;
      await dss.initialize(settings);

      // Content URIs and non-base absolute paths must round-trip untouched —
      // the production code only strips paths that literally start with the
      // base dir.
      const uri = '/Volumes/External/Movies/x.mkv';
      expect(await dss.toRelativePath(uri), uri);
    });

    test('returns the input unchanged when not under the base dir', () async {
      final settings = await SettingsService.getInstance();
      final dss = DownloadStorageService.instance;
      await dss.initialize(settings);

      const foreign = '/some/other/place/file.mkv';
      expect(await dss.toRelativePath(foreign), foreign);
    });

    test('toAbsolutePath joins relative paths against the base dir', () async {
      final settings = await SettingsService.getInstance();
      final dss = DownloadStorageService.instance;
      await dss.initialize(settings);

      final base = p.join(tmpRoot.path, 'support');
      final abs = await dss.toAbsolutePath(p.join('downloads', 'srv', '1', 'video.mp4'));
      expect(abs, p.join(base, 'downloads', 'srv', '1', 'video.mp4'));
    });

    test('toAbsolutePath returns absolute paths unchanged', () async {
      final settings = await SettingsService.getInstance();
      final dss = DownloadStorageService.instance;
      await dss.initialize(settings);

      const already = '/Volumes/Data/Movies/m.mkv';
      expect(await dss.toAbsolutePath(already), already);
    });

    test('toRelativePath then toAbsolutePath round-trips', () async {
      final settings = await SettingsService.getInstance();
      final dss = DownloadStorageService.instance;
      await dss.initialize(settings);

      final base = p.join(tmpRoot.path, 'support');
      final abs = p.join(base, 'downloads', 'srv', '7', 'video.mp4');
      final rel = await dss.toRelativePath(abs);
      final back = await dss.toAbsolutePath(rel);
      expect(back, abs);
    });
  });

  // ============================================================
  // ensureAbsolutePath / getReadablePath
  // ============================================================

  group('ensureAbsolutePath', () {
    test('keeps an existing absolute path that points at a real file', () async {
      final settings = await SettingsService.getInstance();
      final dss = DownloadStorageService.instance;
      await dss.initialize(settings);

      final dir = await dss.getDownloadsDirectory();
      final filePath = p.join(dir.path, 'concrete.mkv');
      await File(filePath).writeAsString('hi');

      final resolved = await dss.ensureAbsolutePath(filePath);
      expect(resolved, filePath);
    });

    test('joins a relative path against the base dir and finds the file', () async {
      final settings = await SettingsService.getInstance();
      final dss = DownloadStorageService.instance;
      await dss.initialize(settings);

      final dir = await dss.getDownloadsDirectory();
      final filePath = p.join(dir.path, 'rel-found.mkv');
      await File(filePath).writeAsString('ok');

      final base = p.join(tmpRoot.path, 'support');
      final relativeStored = p.relative(filePath, from: base);
      final resolved = await dss.ensureAbsolutePath(relativeStored);
      expect(resolved, filePath);
    });

    test('recovers from a doubled base-dir prefix when the recovered file exists', () async {
      final settings = await SettingsService.getInstance();
      final dss = DownloadStorageService.instance;
      await dss.initialize(settings);

      final base = p.join(tmpRoot.path, 'support');
      final realDir = Directory(p.join(base, 'downloads', 'srv-x'))..createSync(recursive: true);
      final realFile = File(p.join(realDir.path, 'recovered.mkv'));
      await realFile.writeAsString('found');

      // Simulate the bug: the stored absolute path doubles the base dir.
      final corrupted = '$base$base${p.separator}downloads${p.separator}srv-x${p.separator}recovered.mkv';
      final resolved = await dss.ensureAbsolutePath(corrupted);
      expect(resolved, realFile.path);
    });

    test('falls back to the first candidate when nothing exists on disk', () async {
      final settings = await SettingsService.getInstance();
      final dss = DownloadStorageService.instance;
      await dss.initialize(settings);

      // Relative path that won't resolve to anything that exists. The fallback
      // returns the toAbsolutePath() candidate (joined under the base dir).
      const stored = 'downloads/missing/never.mkv';
      final resolved = await dss.ensureAbsolutePath(stored);
      final expected = p.join(tmpRoot.path, 'support', stored);
      expect(resolved, expected);
    });

    test('absolute path shorter than the base dir does not throw RangeError', () async {
      final settings = await SettingsService.getInstance();
      final dss = DownloadStorageService.instance;
      await dss.initialize(settings);

      // Stored absolute path is 9 chars; base dir is much longer. Previously,
      // the doubled-base-prefix recovery passed `firstBaseIndex + baseDir.path.length`
      // (negative + len > storedPath.length) to a second `indexOf`, throwing.
      const stored = '/nope.mkv';
      final resolved = await dss.ensureAbsolutePath(stored);
      // Falls back to the original absolute path (it doesn't exist on disk,
      // and no other candidate could be derived from it).
      expect(resolved, stored);
    });
  });

  group('getReadablePath', () {
    test('passes content:// URIs through unchanged', () async {
      final settings = await SettingsService.getInstance();
      final dss = DownloadStorageService.instance;
      await dss.initialize(settings);

      const uri = 'content://com.android.externalstorage.documents/tree/primary%3ADownload/document/x';
      expect(await dss.getReadablePath(uri), uri);
    });

    test('falls back to ensureAbsolutePath for non-content paths', () async {
      final settings = await SettingsService.getInstance();
      final dss = DownloadStorageService.instance;
      await dss.initialize(settings);

      final dir = await dss.getDownloadsDirectory();
      final realFile = File(p.join(dir.path, 'readable.mkv'));
      await realFile.writeAsString('x');

      final relStored = p.relative(realFile.path, from: p.join(tmpRoot.path, 'support'));
      final readable = await dss.getReadablePath(relStored);
      expect(readable, realFile.path);
    });
  });

  // ============================================================
  // SAF path-component helpers (no platform calls — pure formatting)
  // ============================================================

  group('SAF path components & names', () {
    test('movie components/filename use sanitized "Title (Year)"', () async {
      final dss = DownloadStorageService.instance;
      // Movies need a title and may have a year.
      final movie = _movie(title: 'My/Movie:Name?', year: 2023);

      expect(dss.getMovieSafPathComponents(movie), ['Movies', 'MyMovieName (2023)']);
      expect(dss.getMovieSafFileName(movie, 'mkv'), 'MyMovieName (2023).mkv');
    });

    test('movie without year: no parenthesized suffix', () async {
      final dss = DownloadStorageService.instance;
      final movie = _movie(title: 'Untitled');
      expect(dss.getMovieSafPathComponents(movie), ['Movies', 'Untitled']);
      expect(dss.getMovieSafFileName(movie, 'mp4'), 'Untitled.mp4');
    });

    test('episode components use show + season + S{XX}E{XX} - {Title}', () async {
      final dss = DownloadStorageService.instance;
      final episode = _episode(
        showTitle: 'My Show',
        showYear: 2010,
        seasonNumber: 1,
        episodeNumber: 5,
        episodeTitle: 'Pilot:Pt 1',
      );

      expect(dss.getEpisodeSafPathComponents(episode), ['TV Shows', 'My Show (2010)', 'Season 01']);
      expect(dss.getEpisodeSafFileName(episode, 'mkv'), 'S01E05 - PilotPt 1.mkv');
      expect(dss.getEpisodeSafBaseName(episode), 'S01E05 - PilotPt 1');
    });

    test('show components default to metadata title when grandparentTitle is absent', () async {
      final dss = DownloadStorageService.instance;
      final show = _show(title: 'Solo Show', year: 2024);
      expect(dss.getShowSafPathComponents(show), ['TV Shows', 'Solo Show (2024)']);
    });

    test('season components use season.index for the season number', () async {
      final dss = DownloadStorageService.instance;
      final season = _season(showTitle: 'Show A', showYear: 2019, seasonNumber: 3);
      expect(dss.getSeasonSafPathComponents(season), ['TV Shows', 'Show A (2019)', 'Season 03']);
    });

    test('explicit showYear overrides episode.year for the show folder', () async {
      final dss = DownloadStorageService.instance;
      final episode = _episode(
        showTitle: 'Year Mismatch',
        showYear: 2010, // metadata.year on episode
        seasonNumber: 2,
        episodeNumber: 1,
        episodeTitle: 'Title',
      );
      // Pass a different show year explicitly.
      expect(dss.getEpisodeSafPathComponents(episode, showYear: 2008), [
        'TV Shows',
        'Year Mismatch (2008)',
        'Season 02',
      ]);
    });
  });

  // ============================================================
  // Real on-disk media directory helpers
  // ============================================================

  group('media directories on disk', () {
    test('getMediaDirectory creates serverId/ratingKey under downloads', () async {
      final settings = await SettingsService.getInstance();
      final dss = DownloadStorageService.instance;
      await dss.initialize(settings);

      final dir = await dss.getMediaDirectory('srv-1', '42');
      expect(dir.existsSync(), isTrue);
      final downloads = await dss.getDownloadsDirectory();
      expect(dir.path, p.join(downloads.path, 'srv-1', '42'));
    });

    test('getMovieDirectory + getMovieVideoPath produce consistent output', () async {
      final settings = await SettingsService.getInstance();
      final dss = DownloadStorageService.instance;
      await dss.initialize(settings);

      final movie = _movie(title: 'Big Movie', year: 2020);
      final dir = await dss.getMovieDirectory(movie);
      final video = await dss.getMovieVideoPath(movie, 'mkv');
      expect(dir.existsSync(), isTrue);
      expect(p.dirname(video), dir.path);
      expect(p.basename(video), 'Big Movie (2020).mkv');
    });

    test('getEpisodeVideoPath + thumbnail path share the same season directory', () async {
      final settings = await SettingsService.getInstance();
      final dss = DownloadStorageService.instance;
      await dss.initialize(settings);

      final episode = _episode(
        showTitle: 'Demo Show',
        showYear: 2015,
        seasonNumber: 2,
        episodeNumber: 4,
        episodeTitle: 'Pilot',
      );

      final video = await dss.getEpisodeVideoPath(episode, 'mkv');
      final thumb = await dss.getEpisodeThumbnailPath(episode);
      expect(p.dirname(video), p.dirname(thumb));
      expect(p.basename(video), 'S02E04 - Pilot.mkv');
      expect(p.basename(thumb), 'S02E04 - Pilot.jpg');

      final subsDir = await dss.getEpisodeSubtitlesDirectory(episode);
      expect(subsDir.existsSync(), isTrue);
      expect(p.basename(subsDir.path), 'S02E04 - Pilot_subs');
    });
  });

  // ============================================================
  // DownloadStorageException
  // ============================================================

  group('DownloadStorageException', () {
    test('toString embeds message, path, and cause', () {
      final ex = DownloadStorageException('boom', '/tmp/x', StateError('inner'));
      final s = ex.toString();
      expect(s, contains('boom'));
      expect(s, contains('/tmp/x'));
      expect(s, contains('inner'));
    });
  });
}

// ============================================================
// MediaItem fixtures (only the fields the SUT actually reads)
// ============================================================

MediaItem _movie({required String title, int? year}) {
  return MediaItem(
    id: 'm-${title.hashCode}',
    backend: MediaBackend.plex,
    kind: MediaKind.movie,
    title: title,
    year: year,
  );
}

MediaItem _show({required String title, int? year}) {
  return MediaItem(
    id: 's-${title.hashCode}',
    backend: MediaBackend.plex,
    kind: MediaKind.show,
    title: title,
    year: year,
  );
}

MediaItem _season({required String showTitle, int? showYear, required int seasonNumber}) {
  return MediaItem(
    id: 'season-$showTitle-$seasonNumber',
    backend: MediaBackend.plex,
    kind: MediaKind.season,
    title: 'Season $seasonNumber',
    grandparentTitle: showTitle,
    year: showYear,
    index: seasonNumber,
  );
}

MediaItem _episode({
  required String showTitle,
  int? showYear,
  required int seasonNumber,
  required int episodeNumber,
  required String episodeTitle,
}) {
  return MediaItem(
    id: 'ep-$showTitle-$seasonNumber-$episodeNumber',
    backend: MediaBackend.plex,
    kind: MediaKind.episode,
    title: episodeTitle,
    grandparentTitle: showTitle,
    year: showYear,
    parentIndex: seasonNumber,
    index: episodeNumber,
  );
}

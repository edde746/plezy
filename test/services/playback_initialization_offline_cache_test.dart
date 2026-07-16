import 'dart:convert';
import 'package:plezy/media/ids.dart';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/media_backend.dart';

import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/models/download_models.dart';
import 'package:plezy/services/cached_playback_metadata_service.dart';
import 'package:plezy/services/download_storage_service.dart';
import 'package:plezy/services/jellyfin_api_cache.dart';
import 'package:plezy/services/jellyfin_media_info_mapper.dart';
import 'package:plezy/services/playback_initialization_service.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/plex_mappers.dart';
import 'package:plezy/services/settings_service.dart';

import '../test_helpers/io_fakes.dart';
import '../test_helpers/prefs.dart';
import '../test_helpers/media_items.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late Directory tmpRoot;

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    DownloadStorageService.resetForTesting();
    tmpRoot = await Directory.systemTemp.createTemp('playback_init_test_');
    PathProviderPlatform.instance = FakePathProvider(tmpRoot);
    db = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(db);
    JellyfinApiCache.initialize(db);
  });

  tearDown(() async {
    await db.close();
    DownloadStorageService.resetForTesting();
    SettingsService.resetForTesting();
    if (await tmpRoot.exists()) {
      await tmpRoot.delete(recursive: true);
    }
  });

  test('pure-offline playback loads cached Plex media source info without a client', () async {
    await _insertDownloaded(
      db,
      serverId: ServerId('srv-1'),
      ratingKey: 'movie-1',
      videoFilePath: 'content://offline/movie-1',
    );
    await PlexApiCache.instance.put(ServerId('srv-1'), '/library/metadata/movie-1', _plexMetadataEnvelope());

    final result = await PlaybackInitializationService(database: db).getPlaybackData(
      metadata: testMediaItem(
        id: 'movie-1',
        backend: MediaBackend.plex,
        kind: MediaKind.movie,
        serverId: ServerId('srv-1'),
      ),
      selectedMediaIndex: 0,
      preferOffline: true,
    );

    expect(result.isOffline, isTrue);
    expect(result.videoUrl, 'content://offline/movie-1');
    expect(result.mediaInfo?.audioTracks.single.languageCode, 'eng');
  });

  test('downloaded track resolves to its local file through the offline path', () async {
    // Same globalKey shape queueDownload writes (`serverId:ratingKey`) —
    // the music resolver reaches this via preferOffline=true (original
    // audio preset), so a downloaded track must play from disk.
    await _insertDownloaded(
      db,
      serverId: ServerId('srv-1'),
      ratingKey: 'track-1',
      type: 'track',
      videoFilePath: 'content://offline/track-1',
    );
    final client = _FailingPlaybackClient(serverId: ServerId('srv-1'));

    final result = await PlaybackInitializationService(client: client, database: db).getPlaybackData(
      metadata: testMediaItem(
        id: 'track-1',
        backend: MediaBackend.plex,
        kind: MediaKind.track,
        serverId: ServerId('srv-1'),
      ),
      selectedMediaIndex: 0,
      preferOffline: true,
    );

    expect(client.playbackInitializationCalls, 0);
    expect(result.isOffline, isTrue);
    expect(result.videoUrl, 'content://offline/track-1');
    expect(result.playMethod, 'DirectPlay');
  });

  test('preferOffline uses cache without calling live client when local file exists', () async {
    await _insertDownloaded(
      db,
      serverId: ServerId('srv-1'),
      ratingKey: 'movie-1',
      videoFilePath: 'content://offline/movie-1',
    );
    await PlexApiCache.instance.put(ServerId('srv-1'), '/library/metadata/movie-1', _plexMetadataEnvelope());
    final client = _FailingPlaybackClient(serverId: ServerId('srv-1'));

    final result = await PlaybackInitializationService(client: client, database: db).getPlaybackData(
      metadata: testMediaItem(
        id: 'movie-1',
        backend: MediaBackend.plex,
        kind: MediaKind.movie,
        serverId: ServerId('srv-1'),
      ),
      selectedMediaIndex: 0,
      preferOffline: true,
    );

    expect(client.playbackInitializationCalls, 0);
    expect(result.isOffline, isTrue);
    expect(result.videoUrl, 'content://offline/movie-1');
    expect(result.availableVersions, isEmpty);
    expect(result.mediaInfo?.audioTracks.single.languageCode, 'eng');
  });

  test('pure-offline playback uses cached Plex media source for selected version', () async {
    await _insertDownloaded(
      db,
      serverId: ServerId('srv-1'),
      ratingKey: 'movie-1',
      videoFilePath: 'content://offline/movie-1-v2',
      mediaIndex: 1,
    );
    await PlexApiCache.instance.put(
      ServerId('srv-1'),
      '/library/metadata/movie-1',
      _plexMetadataEnvelope(includeSecondVersion: true),
    );

    final result = await PlaybackInitializationService(database: db).getPlaybackData(
      metadata: testMediaItem(
        id: 'movie-1',
        backend: MediaBackend.plex,
        kind: MediaKind.movie,
        serverId: ServerId('srv-1'),
      ),
      selectedMediaIndex: 1,
      preferOffline: true,
    );

    expect(result.videoUrl, 'content://offline/movie-1-v2');
    expect(result.mediaInfo?.audioTracks.single.languageCode, 'fre');
  });

  test('no-client playback falls back to the downloaded version on a default request', () async {
    // Issue #1440: only the non-default version (index 1) is downloaded, but
    // plain Play requests the default (index 0). With no client to stream
    // from, the downloaded copy must play — with its own version metadata.
    await _insertDownloaded(
      db,
      serverId: ServerId('srv-1'),
      ratingKey: 'movie-1',
      videoFilePath: 'content://offline/movie-1-v2',
      mediaIndex: 1,
      mediaSourceId: 'source-b',
    );
    await PlexApiCache.instance.put(
      ServerId('srv-1'),
      '/library/metadata/movie-1',
      _plexMetadataEnvelope(includeSecondVersion: true),
    );

    final result = await PlaybackInitializationService(database: db).getPlaybackData(
      metadata: testMediaItem(
        id: 'movie-1',
        backend: MediaBackend.plex,
        kind: MediaKind.movie,
        serverId: ServerId('srv-1'),
      ),
      selectedMediaIndex: 0,
    );

    expect(result.isOffline, isTrue);
    expect(result.videoUrl, 'content://offline/movie-1-v2');
    expect(result.selectedMediaIndex, 1);
    expect(result.selectedMediaSourceId, 'source-b');
    expect(result.mediaInfo?.audioTracks.single.languageCode, 'fre');
  });

  test('no-client playback plays the local copy even on an explicit version mismatch', () async {
    await _insertDownloaded(
      db,
      serverId: ServerId('srv-1'),
      ratingKey: 'movie-1',
      videoFilePath: 'content://offline/movie-1-v2',
      mediaIndex: 1,
      mediaSourceId: 'source-b',
    );

    final result = await PlaybackInitializationService(database: db).getPlaybackData(
      metadata: testMediaItem(
        id: 'movie-1',
        backend: MediaBackend.plex,
        kind: MediaKind.movie,
        serverId: ServerId('srv-1'),
      ),
      selectedMediaIndex: 0,
      selectedMediaSourceId: 'source-a',
    );

    expect(result.isOffline, isTrue);
    expect(result.videoUrl, 'content://offline/movie-1-v2');
    expect(result.selectedMediaIndex, 1);
  });

  test('online explicit version mismatch keeps streaming from the server', () async {
    // Online pinning guard: Play Version + Original on a NON-downloaded
    // version runs the offline check first (preferOffline), but the strict
    // mismatch must send it to the server, not the downloaded file.
    await _insertDownloaded(
      db,
      serverId: ServerId('srv-1'),
      ratingKey: 'movie-1',
      videoFilePath: 'content://offline/movie-1-v2',
      mediaIndex: 1,
      mediaSourceId: 'source-b',
    );
    final client = _StreamingPlaybackClient(serverId: ServerId('srv-1'));

    final result = await PlaybackInitializationService(client: client, database: db).getPlaybackData(
      metadata: testMediaItem(
        id: 'movie-1',
        backend: MediaBackend.plex,
        kind: MediaKind.movie,
        serverId: ServerId('srv-1'),
      ),
      selectedMediaIndex: 0,
      selectedMediaSourceId: 'source-a',
      preferOffline: true,
    );

    expect(client.playbackInitializationCalls, 1);
    expect(result.isOffline, isFalse);
    expect(result.videoUrl, 'https://server/stream/0');
  });

  test('offline path falls back to media index when caller has no source id', () async {
    await _insertDownloaded(
      db,
      serverId: ServerId('srv-1'),
      ratingKey: 'movie-1',
      videoFilePath: 'content://offline/movie-1-v1',
      mediaIndex: 0,
      mediaSourceId: 'source-a',
    );

    final service = PlaybackInitializationService(database: db);

    expect(await service.getOfflineVideoPath(ServerId('srv-1'), 'movie-1', mediaIndex: 1), null);
    expect(
      await service.getOfflineVideoPath(ServerId('srv-1'), 'movie-1', mediaIndex: 0),
      'content://offline/movie-1-v1',
    );
  });

  test('pure-offline Jellyfin cache works without a connection row', () async {
    await _insertDownloaded(
      db,
      serverId: ServerId('jf-machine'),
      clientScopeId: 'jf-machine/user-a',
      ratingKey: 'item-1',
      videoFilePath: 'content://offline/jf-item-1',
    );
    await db
        .into(db.apiCache)
        .insert(
          ApiCacheCompanion.insert(
            cacheKey: 'jf-machine/user-a:/Users/user-a/Items/item-1',
            data: jsonEncode(_jellyfinItemRaw()),
            pinned: const Value(true),
          ),
        );

    final result = await PlaybackInitializationService(database: db).getPlaybackData(
      metadata: testMediaItem(
        id: 'item-1',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.movie,
        serverId: ServerId('jf-machine'),
      ),
      selectedMediaIndex: 0,
      preferOffline: true,
    );

    expect(result.videoUrl, 'content://offline/jf-item-1');
    expect(result.mediaInfo?.audioTracks.single.languageCode, 'eng');
    expect(result.mediaInfo?.chapters.single.title, 'Chapter 1');
  });

  test('SAF offline playback discovers app-managed sidecar subtitles', () async {
    await _insertDownloaded(
      db,
      serverId: ServerId('srv-1'),
      ratingKey: 'movie-1',
      videoFilePath: 'content://offline/movie-1',
    );
    final subtitlePath = await DownloadStorageService.instance.getSubtitlePath(ServerId('srv-1'), 'movie-1', 2, 'srt');
    final subtitleFile = File(subtitlePath);
    await subtitleFile.parent.create(recursive: true);
    await subtitleFile.writeAsString('1\n00:00:00,000 --> 00:00:01,000\nHello');

    final result = await PlaybackInitializationService(database: db).getPlaybackData(
      metadata: testMediaItem(
        id: 'movie-1',
        backend: MediaBackend.plex,
        kind: MediaKind.movie,
        serverId: ServerId('srv-1'),
      ),
      selectedMediaIndex: 0,
      preferOffline: true,
    );

    expect(result.videoUrl, 'content://offline/movie-1');
    expect(result.externalSubtitles, hasLength(1));
    expect(result.externalSubtitles.single.uri, Uri.file(subtitlePath).toString());
  });

  test('cache-only playback extras fills missing Plex marker types from chapters', () async {
    await PlexApiCache.instance.put(ServerId('srv-1'), '/library/metadata/movie-1', _plexMetadataEnvelope());

    final extras = await CachedPlaybackMetadataService.fetchPlaybackExtras(
      backend: MediaBackend.plex,
      cacheServerId: 'srv-1',
      itemId: 'movie-1',
    );

    expect(extras?.chapters.single.title, 'Intro');
    expect(extras?.markers.map((m) => m.type), ['intro', 'credits']);
  });

  test('Plex extras parser skips malformed entries and keeps valid ones', () async {
    await PlexApiCache.instance.put(
      ServerId('srv-1'),
      '/library/metadata/movie-1',
      _plexMetadataEnvelope(malformedExtras: true),
    );

    final extras = await CachedPlaybackMetadataService.fetchPlaybackExtras(
      backend: MediaBackend.plex,
      cacheServerId: 'srv-1',
      itemId: 'movie-1',
    );

    expect(extras?.chapters.map((c) => c.title), ['Intro']);
    expect(extras?.markers.map((m) => m.type), ['intro', 'credits']);
  });

  test('Plex extras parser can force chapter fallback over native marker timings', () {
    final extras = plexPlaybackExtrasFromCacheJson({
      'Chapter': [
        {'id': 1, 'index': 0, 'startTimeOffset': 5000, 'endTimeOffset': 45000, 'tag': 'Intro'},
        {'id': 2, 'index': 1, 'startTimeOffset': 90000, 'endTimeOffset': 100000, 'tag': 'Credits'},
      ],
      'Marker': [
        {'id': 10, 'type': 'intro', 'startTimeOffset': 12000, 'endTimeOffset': 30000},
        {'id': 11, 'type': 'credits', 'startTimeOffset': 93000, 'endTimeOffset': 98000},
      ],
    }, forceChapterFallback: true);

    final intro = extras.markers.firstWhere((m) => m.type == 'intro');
    final credits = extras.markers.firstWhere((m) => m.type == 'credits');
    expect(intro.startTimeOffset, 5000);
    expect(intro.endTimeOffset, 45000);
    expect(credits.startTimeOffset, 90000);
    expect(credits.endTimeOffset, 100000);
    expect(extras.markers.any((m) => m.id == 10 || m.id == 11), isFalse);
  });

  test('Jellyfin extras parser tolerates non-string chapter names', () {
    final extras = jellyfinPlaybackExtrasFromRaw({
      'Chapters': [
        {'Name': 123, 'StartPositionTicks': 10000000},
      ],
    }, 'item-1');

    expect(extras.chapters.single.title, '123');
  });

  test('cache-only Jellyfin playback extras uses chapter fallback patterns', () async {
    await JellyfinApiCache.instance.put(ServerId('srv-1/user-1'), '/Users/user-1/Items/item-1', {
      'Id': 'item-1',
      'Type': 'Episode',
      'Name': 'Episode',
      'RunTimeTicks': 1200000000,
      'Chapters': [
        {'Name': 'OP', 'StartPositionTicks': 100000000},
        {'Name': 'Episode', 'StartPositionTicks': 450000000},
        {'Name': 'ED', 'StartPositionTicks': 900000000},
      ],
    });

    final extras = await CachedPlaybackMetadataService.fetchPlaybackExtras(
      backend: MediaBackend.jellyfin,
      cacheServerId: 'srv-1/user-1',
      itemId: 'item-1',
    );

    expect(extras?.markers.map((m) => m.type), ['intro', 'credits']);
    expect(extras?.markers.last.endTimeOffset, 120000);
  });

  test('cache-only Jellyfin playback extras uses cached native media segments', () async {
    await JellyfinApiCache.instance.put(ServerId('srv-1/user-1'), '/Users/user-1/Items/item-1', {
      'Id': 'item-1',
      'Type': 'Episode',
      'Name': 'Episode',
      'Chapters': [],
    });
    await JellyfinApiCache.instance.put(ServerId('srv-1/user-1'), '/MediaSegments/item-1', {
      'Items': [
        {'Type': 'Intro', 'StartTicks': 50000000, 'EndTicks': 450000000},
        {'Type': 'Outro', 'StartTicks': 900000000, 'EndTicks': 1000000000},
      ],
    });

    final extras = await CachedPlaybackMetadataService.fetchPlaybackExtras(
      backend: MediaBackend.jellyfin,
      cacheServerId: 'srv-1/user-1',
      itemId: 'item-1',
    );

    expect(extras?.markers.map((m) => m.type), ['intro', 'credits']);
    expect(extras?.markers.first.startTimeOffset, 5000);
    expect(extras?.markers.last.endTimeOffset, 100000);
  });
}

class _StreamingPlaybackClient implements MediaServerClient {
  _StreamingPlaybackClient({required this.serverId});

  @override
  final ServerId serverId;

  int playbackInitializationCalls = 0;

  @override
  Future<PlaybackInitializationResult> getPlaybackInitialization(PlaybackInitializationOptions options) async {
    playbackInitializationCalls++;
    return PlaybackInitializationResult(
      availableVersions: const [],
      videoUrl: 'https://server/stream/${options.selectedMediaIndex}',
      selectedMediaIndex: options.selectedMediaIndex,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FailingPlaybackClient implements MediaServerClient {
  _FailingPlaybackClient({required this.serverId});

  @override
  final ServerId serverId;

  int playbackInitializationCalls = 0;

  @override
  Future<PlaybackInitializationResult> getPlaybackInitialization(PlaybackInitializationOptions options) async {
    playbackInitializationCalls++;
    throw StateError('live playback initialization should not be called for downloaded playback');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _insertDownloaded(
  AppDatabase db, {
  required ServerId serverId,
  String? clientScopeId,
  required String ratingKey,
  required String videoFilePath,
  String type = 'movie',
  int mediaIndex = 0,
  String? mediaSourceId,
}) async {
  await db
      .into(db.downloadedMedia)
      .insert(
        DownloadedMediaCompanion.insert(
          serverId: serverId,
          clientScopeId: Value(clientScopeId),
          ratingKey: ratingKey,
          globalKey: '$serverId:$ratingKey',
          type: type,
          status: DownloadStatus.completed.index,
          videoFilePath: Value(videoFilePath),
          mediaIndex: Value(mediaIndex),
          mediaSourceId: Value(mediaSourceId),
        ),
      );
}

Map<String, dynamic> _plexMetadataEnvelope({bool includeSecondVersion = false, bool malformedExtras = false}) {
  final chapters = <Map<String, dynamic>>[
    if (malformedExtras) {'id': 'bad'},
    {'id': 1, 'index': 0, 'startTimeOffset': 0, 'endTimeOffset': 10000, 'tag': 'Intro'},
  ];
  final markers = <Map<String, dynamic>>[
    if (malformedExtras) {'id': 99, 'type': 'broken'},
    {'id': 2, 'type': 'credits', 'startTimeOffset': 90000, 'endTimeOffset': 100000},
  ];
  final media = <Map<String, dynamic>>[
    _plexMediaWithAudio('English', 'eng'),
    if (includeSecondVersion) _plexMediaWithAudio('French', 'fre'),
  ];
  return {
    'MediaContainer': {
      'Metadata': [
        {
          'ratingKey': 'movie-1',
          'type': 'movie',
          'title': 'Movie',
          'Chapter': chapters,
          'Marker': markers,
          'Media': media,
        },
      ],
    },
  };
}

Map<String, dynamic> _plexMediaWithAudio(String language, String languageCode) {
  return {
    'Part': [
      {
        'Stream': [
          {'id': 10, 'streamType': 2, 'index': 1, 'language': language, 'languageCode': languageCode},
        ],
      },
    ],
  };
}

Map<String, dynamic> _jellyfinItemRaw() {
  return {
    'Id': 'item-1',
    'Type': 'Movie',
    'Name': 'Jellyfin Movie',
    'Chapters': [
      {'Name': 'Chapter 1', 'StartPositionTicks': 0},
    ],
    'MediaSources': [
      {
        'Id': 'src-1',
        'MediaStreams': [
          {'Type': 'Audio', 'Index': 1, 'Language': 'eng', 'DisplayLanguage': 'English', 'IsDefault': true},
        ],
      },
    ],
  };
}

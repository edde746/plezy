import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/services/jellyfin_client.dart';
import 'package:plezy/services/jellyfin_mappers.dart';

import '../test_helpers/backend_client_fixtures.dart';

const _serverId = 'jf-machine-1';

/// Captured (trimmed) from a live Jellyfin 10.11 server — an `Audio` row
/// from `/Items?AlbumIds=...&IncludeItemTypes=Audio`.
Map<String, dynamic> _audioJson() => {
  'Name': 'Intro (Live)',
  'ServerId': '9c23dc6d65044485b4ee44287e723c90',
  'Id': '425f9ab168792a3be733d169b770853f',
  'HasLyrics': false,
  'Container': 'flac',
  'SortName': '0001 - 0001 - Intro (Live)',
  'PremiereDate': '2022-01-01T00:00:00.0000000Z',
  'RunTimeTicks': 120000000,
  'ProductionYear': 2022,
  'IndexNumber': 1,
  'ParentIndexNumber': 1,
  'Type': 'Audio',
  'UserData': {'PlaybackPositionTicks': 0, 'PlayCount': 0, 'IsFavorite': false, 'Played': false},
  'Artists': ['The Synth Pops'],
  'ArtistItems': [
    {'Name': 'The Synth Pops', 'Id': 'a603621309dc866c91b6c5fe10cee64d'},
  ],
  'Album': 'Live at Testhalle',
  'AlbumId': '27511f928761c3f5c080d43d6799ea09',
  'AlbumPrimaryImageTag': '233dccb8ad84d8ac473dbffb86c35e6c',
  'AlbumArtist': 'The Synth Pops',
  'AlbumArtists': [
    {'Name': 'The Synth Pops', 'Id': 'a603621309dc866c91b6c5fe10cee64d'},
  ],
  'ImageTags': {'Primary': '1ed1281fd45ff9b8b5ad62b6f6a34d17'},
  'BackdropImageTags': <String>[],
  'MediaType': 'Audio',
};

/// Captured (trimmed) `MusicAlbum` row from the same server.
Map<String, dynamic> _albumJson() => {
  'Name': 'Live at Testhalle',
  'Id': '27511f928761c3f5c080d43d6799ea09',
  'SortName': 'live at testhalle',
  'PremiereDate': '2022-01-01T00:00:00.0000000Z',
  'RunTimeTicks': 1610000000,
  'ProductionYear': 2022,
  'IsFolder': true,
  'Type': 'MusicAlbum',
  'UserData': {'PlayCount': 0, 'IsFavorite': false, 'Played': false},
  'RecursiveItemCount': 8,
  'ChildCount': 8,
  'Artists': ['The Synth Pops'],
  'AlbumArtist': 'The Synth Pops',
  'AlbumArtists': [
    {'Name': 'The Synth Pops', 'Id': 'a603621309dc866c91b6c5fe10cee64d'},
  ],
  'ImageTags': {'Primary': '233dccb8ad84d8ac473dbffb86c35e6c'},
  'MediaType': 'Unknown',
};

JellyfinConnection _conn() => testJellyfinConnection(
  userName: 'edde',
  accessToken: 'tok-abc',
  deviceId: 'dev-xyz',
  createdAt: DateTime.fromMillisecondsSinceEpoch(0),
);

void main() {
  group('JellyfinMappers.mediaItem music mapping', () {
    test('maps an Audio track with album/artist hierarchy fallbacks', () {
      final item = JellyfinMappers.mediaItem(_audioJson(), serverId: ServerId(_serverId), absolutizer: null)!;

      expect(item.kind, MediaKind.track);
      expect(item.title, 'Intro (Live)');
      // Track parent = album, grandparent = album artist (episode-shaped).
      expect(item.parentId, '27511f928761c3f5c080d43d6799ea09');
      expect(item.parentTitle, 'Live at Testhalle');
      expect(item.grandparentId, 'a603621309dc866c91b6c5fe10cee64d');
      expect(item.grandparentTitle, 'The Synth Pops');
      // Derived music getters.
      expect(item.trackNumber, 1);
      expect(item.discNumber, 1);
      expect(item.albumTitle, 'Live at Testhalle');
      expect(item.albumYear, 2022);
      expect(item.albumArtistTitle, 'The Synth Pops');
      // Artists == [AlbumArtist] → no per-track performer override.
      expect(item.originalTitle, isNull);
      expect(item.trackArtistTitle, 'The Synth Pops');
      // Embedded art wins over the album fallback.
      expect(
        item.thumbPath,
        '/Items/425f9ab168792a3be733d169b770853f/Images/Primary?tag=1ed1281fd45ff9b8b5ad62b6f6a34d17',
      );
      expect(
        item.posterThumbFallback(),
        '/Items/27511f928761c3f5c080d43d6799ea09/Images/Primary?tag=233dccb8ad84d8ac473dbffb86c35e6c',
      );
      expect(item.durationMs, 12000);
    });

    test('compilation track maps differing Artists into originalTitle', () {
      final json = _audioJson()
        ..['Artists'] = ['Artist One', 'Artist Two']
        ..['AlbumArtist'] = 'Various Artists'
        ..['AlbumArtists'] = [
          {'Name': 'Various Artists', 'Id': 'va-1'},
        ];

      final item = JellyfinMappers.mediaItem(json, serverId: ServerId(_serverId), absolutizer: null)!;

      expect(item.originalTitle, 'Artist One, Artist Two');
      expect(item.trackArtistTitle, 'Artist One, Artist Two');
      expect(item.albumArtistTitle, 'Various Artists');
      expect(item.grandparentId, 'va-1');
    });

    test('track without embedded art falls back to the album primary image', () {
      final json = _audioJson()..['ImageTags'] = <String, dynamic>{};

      final item = JellyfinMappers.mediaItem(json, serverId: ServerId(_serverId), absolutizer: null)!;

      expect(
        item.thumbPath,
        '/Items/27511f928761c3f5c080d43d6799ea09/Images/Primary?tag=233dccb8ad84d8ac473dbffb86c35e6c',
      );
    });

    test('track without image tags still tries the album primary endpoint', () {
      final json = _audioJson()
        ..['ImageTags'] = <String, dynamic>{}
        ..remove('AlbumPrimaryImageTag');

      final item = JellyfinMappers.mediaItem(json, serverId: ServerId(_serverId), absolutizer: null)!;

      expect(item.thumbPath, '/Items/27511f928761c3f5c080d43d6799ea09/Images/Primary');
      expect(item.posterThumbFallback(), isNull);
    });

    test('maps a MusicAlbum with artist hierarchy and track counts', () {
      final item = JellyfinMappers.mediaItem(_albumJson(), serverId: ServerId(_serverId), absolutizer: null)!;

      expect(item.kind, MediaKind.album);
      expect(item.title, 'Live at Testhalle');
      expect(item.albumTitle, 'Live at Testhalle');
      expect(item.year, 2022);
      // An album's parent is its artist (Plex parity — Jellyfin albums link
      // artists via tags, not ParentId), so navigation/getters can rely on
      // parentId across backends.
      expect(item.parentId, 'a603621309dc866c91b6c5fe10cee64d');
      expect(item.parentTitle, 'The Synth Pops');
      expect(item.albumArtistTitle, 'The Synth Pops');
      expect(item.grandparentId, isNull);
      expect(item.grandparentTitle, isNull);
      expect(item.leafCount, 8);
      // Artists mirrors AlbumArtist on album rows — no override.
      expect(item.originalTitle, isNull);
      expect(
        item.thumbPath,
        '/Items/27511f928761c3f5c080d43d6799ea09/Images/Primary?tag=233dccb8ad84d8ac473dbffb86c35e6c',
      );
    });

    test('episode hierarchy fields keep priority over music fallbacks', () {
      // Defensive: Season*/Series* must always win should a row ever carry
      // both (the music fallbacks are appended with `??`).
      final json = _audioJson()
        ..['Type'] = 'Episode'
        ..['SeasonId'] = 'season-1'
        ..['SeasonName'] = 'Season 1'
        ..['SeriesId'] = 'series-1'
        ..['SeriesName'] = 'Show';

      final item = JellyfinMappers.mediaItem(json, serverId: ServerId(_serverId), absolutizer: null)!;

      expect(item.parentId, 'season-1');
      expect(item.parentTitle, 'Season 1');
      expect(item.grandparentId, 'series-1');
      expect(item.grandparentTitle, 'Show');
    });
  });

  group('JellyfinClient.fetchLyrics', () {
    JellyfinClient clientWith(Future<http.Response> Function(http.Request) handler) =>
        JellyfinClient.forTesting(connection: _conn(), httpClient: MockClient(handler));

    final track = JellyfinMappers.mediaItem(_audioJson(), serverId: ServerId(_serverId), absolutizer: null)!;

    test('parses tick offsets to ms and infers synced from Start presence', () async {
      final client = clientWith((request) async {
        expect(request.url.path, '/Audio/425f9ab168792a3be733d169b770853f/Lyrics');
        return http.Response(
          jsonEncode({
            'Metadata': <String, dynamic>{},
            'Lyrics': [
              {'Text': 'First light breaking over the test grid', 'Start': 5000000},
              {'Text': 'Synthetic voices humming in time', 'Start': 40000000},
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      addTearDown(client.close);

      final lyrics = await client.fetchLyrics(track);

      expect(lyrics, isNotNull);
      expect(lyrics!.synced, isTrue);
      expect(lyrics.lines, hasLength(2));
      expect(lyrics.lines.first.text, 'First light breaking over the test grid');
      expect(lyrics.lines.first.startMs, 500);
      expect(lyrics.lines[1].startMs, 4000);
    });

    test('treats missing Start offsets as unsynced plain text', () async {
      final client = clientWith((request) async {
        return http.Response(
          jsonEncode({
            'Lyrics': [
              {'Text': 'Line one'},
              {'Text': 'Line two'},
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      addTearDown(client.close);

      final lyrics = await client.fetchLyrics(track);

      expect(lyrics, isNotNull);
      expect(lyrics!.synced, isFalse);
      expect(lyrics.lines.map((l) => l.startMs), everyElement(isNull));
    });

    test('returns null on 404 (track has no lyrics)', () async {
      final client = clientWith((request) async => http.Response('Not Found', 404));
      addTearDown(client.close);

      expect(await client.fetchLyrics(track), isNull);
    });
  });
}

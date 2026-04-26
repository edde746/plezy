import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_stream.dart';
import 'package:plezy/services/jellyfin_mappers.dart';

const _serverId = 'jf-machine-1';

void main() {
  group('JellyfinMappers.mediaItem', () {
    test('maps a movie with watch state, ratings, genres, and people', () {
      final json = {
        'Id': 'abc123',
        'Name': 'Inception',
        'OriginalTitle': 'Inception',
        'Type': 'Movie',
        'Overview': 'Dream within a dream.',
        'Taglines': ['Your mind is the scene of the crime.'],
        'ProductionYear': 2010,
        'PremiereDate': '2010-07-16T00:00:00.0000000Z',
        'OfficialRating': 'PG-13',
        'CommunityRating': 8.8,
        'Genres': ['Action', 'Sci-Fi'],
        'People': [
          {'Type': 'Actor', 'Name': 'Leo', 'Id': 'p1', 'PrimaryImageTag': 'tag1', 'Role': 'Cobb'},
          {'Type': 'Director', 'Name': 'Christopher Nolan'},
        ],
        'Studios': [
          {'Name': 'Warner Bros'},
        ],
        'ProductionLocations': ['United States'],
        'RunTimeTicks': 88800000000, // 8880 sec * 10_000_000
        'UserData': {
          'PlayCount': 1,
          'PlaybackPositionTicks': 30000000000, // 3000 sec
          'Played': true,
          'LastPlayedDate': '2026-04-25T20:00:00.0000000Z',
        },
        'DateCreated': '2025-01-15T10:00:00.0000000Z',
        'DateLastSaved': '2026-03-01T10:00:00.0000000Z',
        'ImageTags': {'Primary': 'thumbtag', 'Logo': 'logotag'},
        'BackdropImageTags': ['backtag'],
      };

      final item = JellyfinMappers.mediaItem(json, serverId: _serverId, serverName: 'Home', absolutizer: null)!;

      expect(item.id, 'abc123');
      expect(item.backend, MediaBackend.jellyfin);
      expect(item.kind, MediaKind.movie);
      expect(item.title, 'Inception');
      expect(item.summary, 'Dream within a dream.');
      expect(item.tagline, 'Your mind is the scene of the crime.');
      expect(item.year, 2010);
      expect(item.originallyAvailableAt, '2010-07-16');
      expect(item.contentRating, 'PG-13');
      expect(item.studio, 'Warner Bros');
      expect(item.rating, 8.8);
      expect(item.genres, ['Action', 'Sci-Fi']);
      expect(item.directors, ['Christopher Nolan']);
      expect(item.countries, ['United States']);
      expect(item.roles, isNotNull);
      expect(item.roles!.length, 1);
      expect(item.roles![0].tag, 'Leo');
      expect(item.roles![0].role, 'Cobb');
      expect(item.roles![0].thumbPath, '/Items/p1/Images/Primary?tag=tag1');

      // Tick conversion: 100ns ticks → ms.
      expect(item.durationMs, 8880000); // 8880s in ms
      expect(item.viewOffsetMs, 3000000); // 3000s in ms
      expect(item.viewCount, 1);

      // Image paths.
      expect(item.thumbPath, '/Items/abc123/Images/Primary?tag=thumbtag');
      expect(item.artPath, '/Items/abc123/Images/Backdrop/0?tag=backtag');
      expect(item.clearLogoPath, '/Items/abc123/Images/Logo?tag=logotag');

      // Multi-server fields.
      expect(item.serverId, _serverId);
      expect(item.serverName, 'Home');
    });

    test('episode preserves series/season hierarchy', () {
      final json = {
        'Id': 'ep1',
        'Name': 'Pilot',
        'Type': 'Episode',
        'IndexNumber': 1,
        'ParentIndexNumber': 1,
        'SeriesId': 'series-1',
        'SeriesName': 'Breaking Bad',
        'SeriesPrimaryImageTag': 'seriesPrimary',
        'SeasonId': 'season-1',
        'SeasonName': 'Season 1',
        'SeasonPrimaryImageTag': 'seasonPrimary',
        'UserData': {'UnplayedItemCount': 0},
      };

      final item = JellyfinMappers.mediaItem(json, serverId: _serverId, absolutizer: null)!;

      expect(item.kind, MediaKind.episode);
      expect(item.index, 1);
      expect(item.parentIndex, 1);
      expect(item.parentId, 'season-1');
      expect(item.parentTitle, 'Season 1');
      expect(item.parentThumbPath, '/Items/season-1/Images/Primary?tag=seasonPrimary');
      expect(item.grandparentId, 'series-1');
      expect(item.grandparentTitle, 'Breaking Bad');
      expect(item.grandparentThumbPath, '/Items/series-1/Images/Primary?tag=seriesPrimary');
      expect(item.grandparentArtPath, '/Items/series-1/Images/Backdrop/0');
    });

    test('series viewedLeafCount derived from total - UnplayedItemCount', () {
      final json = {
        'Id': 's1',
        'Name': 'Show',
        'Type': 'Series',
        'ChildCount': 12,
        'RecursiveItemCount': 12,
        'UserData': {'UnplayedItemCount': 4},
      };

      final item = JellyfinMappers.mediaItem(json, serverId: _serverId, absolutizer: null)!;

      expect(item.leafCount, 12);
      expect(item.viewedLeafCount, 8);
      expect(item.isPartiallyWatched, isTrue);
      expect(item.isWatched, isFalse);
    });

    test('path-encodes image ids and tag query values', () {
      final item = JellyfinMappers.mediaItem(
        {
          'Id': 'folder/item #1?x',
          'Type': 'Episode',
          'Name': 'Reserved IDs',
          'SeriesId': 'series/id #1?x',
          'SeriesPrimaryImageTag': 'series/tag ?x',
          'ParentLogoItemId': 'logo/id #1?x',
          'ParentLogoImageTag': 'logo/tag ?x',
          'ImageTags': {'Primary': 'primary/tag ?x'},
          'People': [
            {'Type': 'Actor', 'Name': 'Actor', 'Id': 'person/id #1?x', 'PrimaryImageTag': 'person/tag ?x'},
          ],
        },
        serverId: _serverId,
        absolutizer: null,
      )!;

      expect(item.thumbPath, '/Items/folder%2Fitem%20%231%3Fx/Images/Primary?tag=primary%2Ftag%20%3Fx');
      expect(item.grandparentThumbPath, '/Items/series%2Fid%20%231%3Fx/Images/Primary?tag=series%2Ftag%20%3Fx');
      expect(item.clearLogoPath, '/Items/logo%2Fid%20%231%3Fx/Images/Logo?tag=logo%2Ftag%20%3Fx');
      expect(item.roles!.single.thumbPath, '/Items/person%2Fid%20%231%3Fx/Images/Primary?tag=person%2Ftag%20%3Fx');
    });

    test('series leafCount uses RecursiveItemCount over ChildCount', () {
      // Realistic Jellyfin shape for a Series: ChildCount = season count,
      // RecursiveItemCount = total episode count. Plex `leafCount` semantics
      // are leaves (episodes), so we must prefer the recursive total or the
      // unwatched badge ends up showing seasons instead of episodes.
      final json = {
        'Id': 's2',
        'Name': 'Show with seasons',
        'Type': 'Series',
        'ChildCount': 4, // 4 seasons
        'RecursiveItemCount': 50, // 50 episodes
        'UserData': {'UnplayedItemCount': 7},
      };

      final item = JellyfinMappers.mediaItem(json, serverId: _serverId, absolutizer: null)!;

      expect(item.leafCount, 50);
      expect(item.viewedLeafCount, 43);
    });

    test('media versions map MediaSources + MediaStreams faithfully', () {
      final json = {
        'Id': 'movie-1',
        'Name': 'Movie',
        'Type': 'Movie',
        'MediaSources': [
          {
            'Id': 'src-1',
            'Container': 'mkv',
            'Bitrate': 8000000,
            'Size': 10737418240,
            'RunTimeTicks': 60000000000,
            'MediaStreams': [
              {
                'Index': 0,
                'Type': 'Video',
                'Codec': 'h264',
                'IsDefault': true,
                'RealFrameRate': 23.976,
                'Width': 1920,
                'Height': 1080,
              },
              {
                'Index': 1,
                'Type': 'Audio',
                'Codec': 'eac3',
                'Language': 'eng',
                'DisplayLanguage': 'English',
                'Channels': 6,
                'IsDefault': true,
              },
              {
                'Index': 2,
                'Type': 'Subtitle',
                'Codec': 'srt',
                'Language': 'eng',
                'IsExternal': true,
                'IsForced': true,
                'DeliveryUrl': '/Videos/movie-1/movie-1/Subtitles/2/Stream.srt',
              },
            ],
          },
        ],
      };

      final item = JellyfinMappers.mediaItem(json, serverId: _serverId, absolutizer: null)!;
      expect(item.mediaVersions, isNotNull);
      final v = item.mediaVersions!.single;
      expect(v.id, 'src-1');
      expect(v.width, 1920);
      expect(v.height, 1080);
      expect(v.videoResolution, '1080');
      expect(v.videoCodec, 'h264');
      // Jellyfin's `Bitrate` (8 Mbps in bps) is converted to kbps to match
      // MediaVersion.bitrate's contract (and Plex's encoding).
      expect(v.bitrate, 8000);
      expect(v.container, 'mkv');

      final part = v.parts.single;
      expect(part.id, 'src-1');
      expect(part.streamPath, '/Videos/src-1/stream');
      expect(part.sizeBytes, 10737418240);
      expect(part.durationMs, 6000000); // 6000s

      final video = part.streams.firstWhere((s) => s.kind == MediaStreamKind.video);
      expect(video.codec, 'h264');
      expect(video.frameRate, closeTo(23.976, 0.001));
      expect(video.selected, isTrue);

      final audio = part.streams.firstWhere((s) => s.kind == MediaStreamKind.audio);
      expect(audio.codec, 'eac3');
      expect(audio.channels, 6);
      expect(audio.languageCode, 'eng');

      final subtitle = part.streams.firstWhere((s) => s.kind == MediaStreamKind.subtitle);
      expect(subtitle.forced, isTrue);
      expect(subtitle.isExternal, isTrue);
      expect(subtitle.sidecarPath, '/Videos/movie-1/movie-1/Subtitles/2/Stream.srt');
    });
  });

  group('JellyfinMappers.library', () {
    test('translates Jellyfin CollectionType to neutral MediaKind', () {
      final cases = {
        'movies': MediaKind.movie,
        'tvshows': MediaKind.show,
        'music': MediaKind.artist,
        'photos': MediaKind.photo,
        'boxsets': MediaKind.collection,
      };
      for (final entry in cases.entries) {
        final lib = JellyfinMappers.library({
          'Id': 'view-${entry.key}',
          'Name': 'Library',
          'CollectionType': entry.key,
        }, serverId: _serverId)!;
        expect(lib.kind, entry.value, reason: 'CollectionType ${entry.key}');
        expect(lib.backend, MediaBackend.jellyfin);
      }
    });

    test('falls back to MediaKind.unknown for unrecognised collections', () {
      final lib = JellyfinMappers.library({
        'Id': 'view-x',
        'Name': 'Mixed',
        'CollectionType': 'mixed',
      }, serverId: _serverId)!;
      expect(lib.kind, MediaKind.unknown);
    });
  });

  // Past regression: a Jellyfin server can omit any of these fields when
  // the item is freshly created or the user has restricted permissions.
  // Confirms the mapper degrades gracefully — none of these inputs should
  // throw and every output field should have a sane fallback.
  group('JellyfinMappers.mediaItem null-tolerance', () {
    test('minimal payload (just Id + Type) yields a MediaItem with sane defaults', () {
      final item = JellyfinMappers.mediaItem(
        {'Id': 'bare-1', 'Type': 'Movie'},
        serverId: _serverId,
        serverName: 'Home',
        absolutizer: null,
      )!;
      expect(item.id, 'bare-1');
      expect(item.kind, MediaKind.movie);
      expect(item.summary, isNull);
      expect(item.year, isNull);
      expect(item.isWatched, isFalse);
      // Optional list fields can be null OR empty — both are sane.
      expect(item.genres, anyOf(isNull, isEmpty));
      expect(item.directors, anyOf(isNull, isEmpty));
    });

    test('missing UserData leaves watch state nullable without throwing', () {
      final item = JellyfinMappers.mediaItem(
        {'Id': 'i', 'Type': 'Movie', 'Name': 'X'},
        serverId: _serverId,
        absolutizer: null,
      )!;
      // Either 0 or null is acceptable as long as we don't crash.
      expect(item.viewCount, anyOf(isNull, 0));
      expect(item.viewOffsetMs, isNull);
      expect(item.lastViewedAt, isNull);
    });

    test('null People array does not crash', () {
      final item = JellyfinMappers.mediaItem(
        {'Id': 'i', 'Type': 'Movie', 'Name': 'X', 'People': null},
        serverId: _serverId,
        absolutizer: null,
      )!;
      expect(item.directors, anyOf(isNull, isEmpty));
      expect(item.writers, anyOf(isNull, isEmpty));
      expect(item.roles, anyOf(isNull, isEmpty));
    });

    test('null Genres / Studios / ProductionLocations degrade gracefully', () {
      final item = JellyfinMappers.mediaItem(
        {'Id': 'i', 'Type': 'Movie', 'Name': 'X', 'Genres': null, 'Studios': null, 'ProductionLocations': null},
        serverId: _serverId,
        absolutizer: null,
      )!;
      expect(item.genres, anyOf(isNull, isEmpty));
      expect(item.studio, isNull);
      expect(item.countries, anyOf(isNull, isEmpty));
    });

    test('malformed RunTimeTicks does not throw — duration left null', () {
      final item = JellyfinMappers.mediaItem(
        {'Id': 'i', 'Type': 'Movie', 'Name': 'X', 'RunTimeTicks': 'not-a-number'},
        serverId: _serverId,
        absolutizer: null,
      )!;
      expect(item.durationMs, isNull);
    });

    test('null MediaSources does not crash', () {
      final item = JellyfinMappers.mediaItem(
        {'Id': 'i', 'Type': 'Movie', 'Name': 'X', 'MediaSources': null},
        serverId: _serverId,
        absolutizer: null,
      )!;
      expect(item.mediaVersions, anyOf(isNull, isEmpty));
    });
  });

  group('JellyfinMappers.mediaItem missing-Id rejection', () {
    test('returns null when Id is absent', () {
      expect(
        JellyfinMappers.mediaItem({'Type': 'Movie', 'Name': 'noId'}, serverId: _serverId, absolutizer: null),
        isNull,
      );
    });

    test('returns null when Id is empty string', () {
      expect(
        JellyfinMappers.mediaItem(
          {'Id': '', 'Type': 'Movie', 'Name': 'emptyId'},
          serverId: _serverId,
          absolutizer: null,
        ),
        isNull,
      );
    });

    test('drops MediaSources entries with missing Id', () {
      final item = JellyfinMappers.mediaItem(
        {
          'Id': 'movie-x',
          'Type': 'Movie',
          'MediaSources': [
            {'Container': 'mkv', 'Bitrate': 8000000, 'MediaStreams': []},
            {'Id': 'src-ok', 'Container': 'mp4', 'Bitrate': 4000000, 'MediaStreams': []},
          ],
        },
        serverId: _serverId,
        absolutizer: null,
      )!;
      expect(item.mediaVersions!.length, 1);
      expect(item.mediaVersions!.single.id, 'src-ok');
    });
  });

  group('JellyfinMappers.library missing-Id rejection', () {
    test('returns null when Id is absent', () {
      expect(JellyfinMappers.library({'Name': 'Library', 'CollectionType': 'movies'}, serverId: _serverId), isNull);
    });
  });
}

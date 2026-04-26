import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/services/plex_mappers.dart';

const _serverId = 'plex-machine-1';
const _serverName = 'Home';

void main() {
  group('PlexMappers.mediaItem (movie)', () {
    test('maps a Plex movie with watch state, ratings, genres, and people', () {
      final json = {
        'ratingKey': '12345',
        'key': '/library/metadata/12345',
        'guid': 'plex://movie/5d776b59ad5437001f7be94b',
        'studio': 'Warner Bros.',
        'type': 'movie',
        'title': 'Inception',
        'titleSort': 'Inception',
        'originalTitle': 'Inception',
        'tagline': 'Your mind is the scene of the crime.',
        'contentRating': 'PG-13',
        'summary': 'Dom Cobb is a thief.',
        'rating': 8.8,
        'audienceRating': 9.1,
        'userRating': 9.5,
        'year': 2010,
        'originallyAvailableAt': '2010-07-16',
        'thumb': '/library/metadata/12345/thumb/1700000000',
        'art': '/library/metadata/12345/art/1700000000',
        'duration': 8880000,
        'addedAt': 1600000000,
        'updatedAt': 1700000000,
        'lastViewedAt': 1750000000,
        'viewOffset': 3000000,
        'viewCount': 1,
        'librarySectionID': 1,
        'librarySectionTitle': 'Movies',
        'ratingImage': 'rottentomatoes://image.rating.ripe',
        'audienceRatingImage': 'rottentomatoes://image.rating.upright',
        'Genre': [
          {'tag': 'Action'},
          {'tag': 'Sci-Fi'},
        ],
        'Director': [
          {'tag': 'Christopher Nolan'},
        ],
        'Writer': [
          {'tag': 'Christopher Nolan'},
        ],
        'Producer': [
          {'tag': 'Emma Thomas'},
        ],
        'Country': [
          {'tag': 'United States'},
        ],
        'Role': [
          {'id': 1, 'tag': 'Leonardo DiCaprio', 'role': 'Cobb', 'thumb': '/library/metadata/role/1/thumb'},
          {'id': 2, 'tag': 'Joseph Gordon-Levitt', 'role': 'Arthur'},
        ],
      };

      final item = PlexMappers.mediaItemFromJson(json, serverId: _serverId, serverName: _serverName);

      expect(item.id, '12345');
      expect(item.backend, MediaBackend.plex);
      expect(item.kind, MediaKind.movie);
      expect(item.guid, 'plex://movie/5d776b59ad5437001f7be94b');
      expect(item.title, 'Inception');
      expect(item.titleSort, 'Inception');
      expect(item.originalTitle, 'Inception');
      expect(item.tagline, 'Your mind is the scene of the crime.');
      expect(item.summary, 'Dom Cobb is a thief.');
      expect(item.studio, 'Warner Bros.');
      expect(item.year, 2010);
      expect(item.originallyAvailableAt, '2010-07-16');
      expect(item.contentRating, 'PG-13');
      expect(item.rating, 8.8);
      expect(item.audienceRating, 9.1);
      expect(item.userRating, 9.5);
      expect(item.ratingImage, 'rottentomatoes://image.rating.ripe');
      expect(item.audienceRatingImage, 'rottentomatoes://image.rating.upright');

      // Plex stores all temporal fields in milliseconds — pass-through.
      expect(item.durationMs, 8880000);
      expect(item.viewOffsetMs, 3000000);
      expect(item.viewCount, 1);
      expect(item.lastViewedAt, 1750000000);
      expect(item.addedAt, 1600000000);
      expect(item.updatedAt, 1700000000);

      // Image paths kept relative — token-aware resolution lives on the client.
      expect(item.thumbPath, '/library/metadata/12345/thumb/1700000000');
      expect(item.artPath, '/library/metadata/12345/art/1700000000');

      // Tag lists from the heterogeneous `[{tag: ...}, ...]` shape.
      expect(item.genres, ['Action', 'Sci-Fi']);
      expect(item.directors, ['Christopher Nolan']);
      expect(item.writers, ['Christopher Nolan']);
      expect(item.producers, ['Emma Thomas']);
      expect(item.countries, ['United States']);

      // Roles preserve role string and thumb path.
      expect(item.roles, isNotNull);
      expect(item.roles!.length, 2);
      expect(item.roles![0].id, '1');
      expect(item.roles![0].tag, 'Leonardo DiCaprio');
      expect(item.roles![0].role, 'Cobb');
      expect(item.roles![0].thumbPath, '/library/metadata/role/1/thumb');
      expect(item.roles![1].thumbPath, isNull);

      // Library identification.
      expect(item.libraryId, '1');
      expect(item.libraryTitle, 'Movies');

      // Server-tagging.
      expect(item.serverId, _serverId);
      expect(item.serverName, _serverName);
    });
  });

  group('PlexMappers.mediaItem (show + season + episode)', () {
    test('show preserves leaf counts and child counts', () {
      final json = {
        'ratingKey': '500',
        'key': '/library/metadata/500',
        'type': 'show',
        'title': 'Breaking Bad',
        'leafCount': 62,
        'viewedLeafCount': 62,
        'childCount': 5,
        'year': 2008,
      };

      final item = PlexMappers.mediaItemFromJson(json, serverId: _serverId);
      expect(item.kind, MediaKind.show);
      expect(item.leafCount, 62);
      expect(item.viewedLeafCount, 62);
      expect(item.childCount, 5);
      expect(item.isWatched, isTrue);
    });

    test('season carries parent (show) reference', () {
      final json = {
        'ratingKey': '510',
        'type': 'season',
        'title': 'Season 1',
        'index': 1,
        'parentRatingKey': '500',
        'parentTitle': 'Breaking Bad',
        'parentThumb': '/library/metadata/500/thumb/1',
        'leafCount': 7,
        'viewedLeafCount': 3,
      };

      final item = PlexMappers.mediaItemFromJson(json, serverId: _serverId);
      expect(item.kind, MediaKind.season);
      expect(item.index, 1);
      expect(item.parentId, '500');
      expect(item.parentTitle, 'Breaking Bad');
      expect(item.parentThumbPath, '/library/metadata/500/thumb/1');
      expect(item.leafCount, 7);
      expect(item.viewedLeafCount, 3);
      expect(item.isPartiallyWatched, isTrue);
    });

    test('episode carries parent (season) and grandparent (show) refs', () {
      final json = {
        'ratingKey': '520',
        'type': 'episode',
        'title': 'Pilot',
        'index': 1,
        'parentIndex': 1,
        'parentRatingKey': '510',
        'parentTitle': 'Season 1',
        'parentThumb': '/library/metadata/510/thumb/1',
        'grandparentRatingKey': '500',
        'grandparentTitle': 'Breaking Bad',
        'grandparentThumb': '/library/metadata/500/thumb/1',
        'grandparentArt': '/library/metadata/500/art/1',
        'duration': 2820000,
        'viewOffset': 1410000,
      };

      final item = PlexMappers.mediaItemFromJson(json, serverId: _serverId);
      expect(item.kind, MediaKind.episode);
      expect(item.index, 1);
      expect(item.parentIndex, 1);
      expect(item.parentId, '510');
      expect(item.parentTitle, 'Season 1');
      expect(item.parentThumbPath, '/library/metadata/510/thumb/1');
      expect(item.grandparentId, '500');
      expect(item.grandparentTitle, 'Breaking Bad');
      expect(item.grandparentThumbPath, '/library/metadata/500/thumb/1');
      expect(item.grandparentArtPath, '/library/metadata/500/art/1');
      expect(item.durationMs, 2820000);
      expect(item.viewOffsetMs, 1410000);
    });
  });

  group('PlexMappers.mediaItem (music)', () {
    test('album preserves studio and parent (artist) reference', () {
      final json = {
        'ratingKey': '700',
        'type': 'album',
        'title': 'Random Access Memories',
        'parentRatingKey': '699',
        'parentTitle': 'Daft Punk',
        'studio': 'Columbia Records',
        'year': 2013,
        'leafCount': 13,
      };

      final item = PlexMappers.mediaItemFromJson(json, serverId: _serverId);
      expect(item.kind, MediaKind.album);
      expect(item.title, 'Random Access Memories');
      expect(item.parentId, '699');
      expect(item.parentTitle, 'Daft Punk');
      expect(item.studio, 'Columbia Records');
      expect(item.year, 2013);
      expect(item.leafCount, 13);
    });

    test('track maps "audio" type to MediaKind.track', () {
      final json = {
        'ratingKey': '710',
        'type': 'track',
        'title': 'Get Lucky',
        'index': 8,
        'parentRatingKey': '700',
        'parentTitle': 'Random Access Memories',
        'grandparentRatingKey': '699',
        'grandparentTitle': 'Daft Punk',
        'duration': 369000,
      };

      final item = PlexMappers.mediaItemFromJson(json, serverId: _serverId);
      expect(item.kind, MediaKind.track);
      expect(item.title, 'Get Lucky');
      expect(item.index, 8);
      expect(item.durationMs, 369000);
      expect(item.parentId, '700');
      expect(item.parentTitle, 'Random Access Memories');
      expect(item.grandparentId, '699');
      expect(item.grandparentTitle, 'Daft Punk');
    });
  });

  group('PlexMappers.mediaItem (media versions + image arrays)', () {
    test('Media + Part list yields a MediaVersion with one MediaPart', () {
      final json = {
        'ratingKey': '12345',
        'type': 'movie',
        'title': 'Inception',
        'Media': [
          {
            'id': 1,
            'videoResolution': '1080',
            'videoCodec': 'h264',
            'bitrate': 8000,
            'width': 1920,
            'height': 1080,
            'container': 'mkv',
            'Part': [
              {'key': '/library/parts/1/file.mkv'},
            ],
          },
        ],
      };

      final item = PlexMappers.mediaItemFromJson(json, serverId: _serverId);
      expect(item.mediaVersions, isNotNull);
      final v = item.mediaVersions!.single;
      expect(v.id, '1');
      expect(v.videoResolution, '1080');
      expect(v.videoCodec, 'h264');
      expect(v.bitrate, 8000);
      expect(v.width, 1920);
      expect(v.height, 1080);
      expect(v.container, 'mkv');
      expect(v.parts.single.streamPath, '/library/parts/1/file.mkv');
    });

    test('Image array (clearLogo, backgroundSquare) is hoisted onto top-level fields', () {
      final json = {
        'ratingKey': '12345',
        'type': 'movie',
        'title': 'Inception',
        'Image': [
          {'type': 'clearLogo', 'url': '/library/metadata/12345/clearLogo'},
          {'type': 'backgroundSquare', 'url': '/library/metadata/12345/squareBg'},
          {'type': 'snapshot', 'url': '/library/metadata/12345/snap'},
        ],
      };

      final item = PlexMappers.mediaItemFromJson(json, serverId: _serverId);
      expect(item.clearLogoPath, '/library/metadata/12345/clearLogo');
      expect(item.backgroundSquarePath, '/library/metadata/12345/squareBg');
    });
  });

  group('PlexMappers.mediaLibrary', () {
    test('library Directory entry maps to MediaLibrary with kind from type', () {
      final json = {
        'key': '1',
        'title': 'Movies',
        'type': 'movie',
        'agent': 'tv.plex.agents.movie',
        'language': 'en-US',
        'updatedAt': 1700000000,
        'createdAt': 1600000000,
        'hidden': 0,
      };

      final lib = PlexMappers.mediaLibraryFromJson(json, serverId: _serverId, serverName: _serverName);
      expect(lib.id, '1');
      expect(lib.backend, MediaBackend.plex);
      expect(lib.title, 'Movies');
      expect(lib.kind, MediaKind.movie);
      expect(lib.language, 'en-US');
      expect(lib.updatedAt, 1700000000);
      expect(lib.createdAt, 1600000000);
      expect(lib.hidden, isFalse);
      expect(lib.isShared, isFalse);
      expect(lib.serverId, _serverId);
      expect(lib.serverName, _serverName);
    });

    test('shared library is marked isShared', () {
      final json = {'key': 'shared', 'title': 'Shared with you', 'type': 'movie'};
      final lib = PlexMappers.mediaLibraryFromJson(json, serverId: _serverId, isShared: true);
      expect(lib.isShared, isTrue);
    });

    test('hidden=1 maps to true', () {
      final json = {'key': '2', 'title': 'Hidden', 'type': 'show', 'hidden': 1};
      final lib = PlexMappers.mediaLibraryFromJson(json, serverId: _serverId);
      expect(lib.hidden, isTrue);
    });

    test('library with missing title/type falls back to empty strings', () {
      // Past regression: bare `as String` casts on title/type in
      // PlexLibraryDto.fromJson would throw TypeError when Plex omitted
      // either field. Confirms graceful degradation.
      final json = {'key': '99'};
      final lib = PlexMappers.mediaLibraryFromJson(json, serverId: _serverId);
      expect(lib.id, '99');
      expect(lib.title, '');
      expect(lib.kind, MediaKind.unknown);
    });
  });

  group('PlexMappers.mediaHub', () {
    test('hub with mixed-type items maps to MediaHub with neutral items', () {
      final json = {
        'key': '/hubs/movie.recentlyAdded',
        'title': 'Recently Added Movies',
        'type': 'movie',
        'hubIdentifier': 'movie.recentlyAdded.1',
        'size': 2,
        'more': true,
        'Metadata': [
          {'ratingKey': '1', 'type': 'movie', 'title': 'Movie A'},
          {'ratingKey': '2', 'type': 'movie', 'title': 'Movie B'},
        ],
      };

      final hub = PlexMappers.mediaHubFromJson(json, serverId: _serverId, serverName: _serverName);
      expect(hub.id, '/hubs/movie.recentlyAdded');
      expect(hub.identifier, 'movie.recentlyAdded.1');
      expect(hub.title, 'Recently Added Movies');
      expect(hub.type, 'movie');
      expect(hub.size, 2);
      expect(hub.more, isTrue);
      expect(hub.items.length, 2);
      expect(hub.items[0].title, 'Movie A');
      expect(hub.items[0].kind, MediaKind.movie);
      expect(hub.items[1].title, 'Movie B');
      expect(hub.items[0].serverId, _serverId);
      expect(hub.items[0].serverName, _serverName);
      expect(hub.serverId, _serverId);
      expect(hub.serverName, _serverName);
    });

    test('Directory entries without type are inferred (folder vs show)', () {
      final json = {
        'key': '/hubs/foo',
        'title': 'Foo',
        'type': 'mixed',
        'Directory': [
          // Has leafCount → looks like a show
          {'ratingKey': '10', 'title': 'A Show', 'leafCount': 24},
          // Plain folder
          {'ratingKey': '11', 'title': 'A Folder'},
        ],
      };

      final hub = PlexMappers.mediaHubFromJson(json, serverId: _serverId);
      expect(hub.items.length, 2);
      expect(hub.items[0].kind, MediaKind.show);
      expect(hub.items[1].kind, MediaKind.unknown);
    });

    test('parses Metadata + Directory together', () {
      final json = {
        'key': '/hubs/foo',
        'title': 'Foo',
        'type': 'mixed',
        'Metadata': [
          {'ratingKey': '1', 'type': 'movie', 'title': 'Movie A'},
        ],
        'Directory': [
          {'ratingKey': '10', 'type': 'show', 'title': 'Show B'},
        ],
      };

      final hub = PlexMappers.mediaHubFromJson(json, serverId: _serverId);
      expect(hub.items.length, 2);
      expect(hub.items[0].kind, MediaKind.movie);
      expect(hub.items[1].kind, MediaKind.show);
    });
  });

  group('PlexMappers.mediaPlaylist', () {
    test('video playlist maps with summary and counts', () {
      final json = {
        'ratingKey': '999',
        'key': '/playlists/999/items',
        'type': 'playlist',
        'title': 'Date Night',
        'summary': 'Movies for date night',
        'smart': false,
        'playlistType': 'video',
        'duration': 14400000,
        'leafCount': 5,
        'composite': '/playlists/999/composite/1700000000',
        'addedAt': 1600000000,
        'updatedAt': 1700000000,
        'lastViewedAt': 1750000000,
        'viewCount': 3,
        'thumb': '/playlists/999/thumb',
      };

      final p = PlexMappers.mediaPlaylistFromJson(json, serverId: _serverId, serverName: _serverName);
      expect(p.id, '999');
      expect(p.backend, MediaBackend.plex);
      expect(p.title, 'Date Night');
      expect(p.summary, 'Movies for date night');
      expect(p.smart, isFalse);
      expect(p.playlistType, 'video');
      expect(p.durationMs, 14400000);
      expect(p.leafCount, 5);
      expect(p.viewCount, 3);
      expect(p.addedAt, 1600000000);
      expect(p.updatedAt, 1700000000);
      expect(p.lastViewedAt, 1750000000);
      expect(p.compositeImagePath, '/playlists/999/composite/1700000000');
      expect(p.thumbPath, '/playlists/999/thumb');
      expect(p.serverId, _serverId);
      expect(p.serverName, _serverName);
    });

    test('smart playlist preserves the smart flag', () {
      final json = {
        'ratingKey': '888',
        'key': '/playlists/888/items',
        'type': 'playlist',
        'title': 'Recently Added',
        'smart': true,
        'playlistType': 'audio',
      };

      final p = PlexMappers.mediaPlaylistFromJson(json, serverId: _serverId);
      expect(p.smart, isTrue);
      expect(p.playlistType, 'audio');
    });

    test('playlist with missing key/type/smart/playlistType falls back to safe defaults', () {
      // Past regression: bare `as String` / `as bool` casts in
      // PlexPlaylistDto.fromJson would throw TypeError when Plex omitted
      // optional fields. Confirms graceful degradation.
      final json = {'ratingKey': '777', 'title': 'Bare', 'summary': null};
      final p = PlexMappers.mediaPlaylistFromJson(json, serverId: _serverId);
      expect(p.id, '777');
      expect(p.title, 'Bare');
      expect(p.smart, isFalse);
      expect(p.playlistType, '');
    });
  });

  group('PlexMappers DTO direct entry points', () {
    test('mediaItem (DTO) preserves data identical to JSON path', () {
      final json = {'ratingKey': '1', 'type': 'movie', 'title': 'Test', 'year': 2024};
      final dto = PlexMetadataDto.fromJsonWithImages(json).copyWith(serverId: _serverId);
      final item = PlexMappers.mediaItem(dto);
      expect(item.id, '1');
      expect(item.title, 'Test');
      expect(item.year, 2024);
      expect(item.serverId, _serverId);
    });

    test('mediaVersion (DTO) maps version + part', () {
      final json = {
        'id': 42,
        'videoResolution': '4k',
        'videoCodec': 'hevc',
        'bitrate': 25000,
        'width': 3840,
        'height': 2160,
        'container': 'mp4',
        'Part': [
          {'key': '/library/parts/42/file.mp4'},
        ],
      };
      final v = PlexMappers.mediaVersionFromJson(json);
      expect(v.id, '42');
      expect(v.videoResolution, '4k');
      expect(v.videoCodec, 'hevc');
      expect(v.bitrate, 25000);
      expect(v.width, 3840);
      expect(v.height, 2160);
      expect(v.container, 'mp4');
      expect(v.parts.single.streamPath, '/library/parts/42/file.mp4');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/plex_metadata.dart';

void main() {
  group('PlexMediaType enum', () {
    group('isVideo', () {
      test('movie is video', () {
        expect(PlexMediaType.movie.isVideo, true);
      });

      test('episode is video', () {
        expect(PlexMediaType.episode.isVideo, true);
      });

      test('clip is video', () {
        expect(PlexMediaType.clip.isVideo, true);
      });

      test('show is not video', () {
        expect(PlexMediaType.show.isVideo, false);
      });

      test('season is not video', () {
        expect(PlexMediaType.season.isVideo, false);
      });

      test('track is not video', () {
        expect(PlexMediaType.track.isVideo, false);
      });
    });

    group('isShowRelated', () {
      test('show is show related', () {
        expect(PlexMediaType.show.isShowRelated, true);
      });

      test('season is show related', () {
        expect(PlexMediaType.season.isShowRelated, true);
      });

      test('episode is show related', () {
        expect(PlexMediaType.episode.isShowRelated, true);
      });

      test('movie is not show related', () {
        expect(PlexMediaType.movie.isShowRelated, false);
      });
    });

    group('isMusic', () {
      test('artist is music', () {
        expect(PlexMediaType.artist.isMusic, true);
      });

      test('album is music', () {
        expect(PlexMediaType.album.isMusic, true);
      });

      test('track is music', () {
        expect(PlexMediaType.track.isMusic, true);
      });

      test('movie is not music', () {
        expect(PlexMediaType.movie.isMusic, false);
      });
    });

    group('isPlayable', () {
      test('movie is playable', () {
        expect(PlexMediaType.movie.isPlayable, true);
      });

      test('episode is playable', () {
        expect(PlexMediaType.episode.isPlayable, true);
      });

      test('clip is playable', () {
        expect(PlexMediaType.clip.isPlayable, true);
      });

      test('track is playable', () {
        expect(PlexMediaType.track.isPlayable, true);
      });

      test('show is not playable', () {
        expect(PlexMediaType.show.isPlayable, false);
      });

      test('season is not playable', () {
        expect(PlexMediaType.season.isPlayable, false);
      });
    });
  });

  group('PlexMetadata', () {
    PlexMetadata createTestMetadata({
      String ratingKey = '12345',
      String key = '/library/metadata/12345',
      String type = 'movie',
      String title = 'Test Movie',
      String? serverId,
      String? serverName,
    }) {
      return PlexMetadata(
        ratingKey: ratingKey,
        key: key,
        type: type,
        title: title,
        serverId: serverId,
        serverName: serverName,
      );
    }

    group('mediaType', () {
      test('returns movie for movie type', () {
        final metadata = createTestMetadata(type: 'movie');
        expect(metadata.mediaType, PlexMediaType.movie);
      });

      test('returns show for show type', () {
        final metadata = createTestMetadata(type: 'show');
        expect(metadata.mediaType, PlexMediaType.show);
      });

      test('returns season for season type', () {
        final metadata = createTestMetadata(type: 'season');
        expect(metadata.mediaType, PlexMediaType.season);
      });

      test('returns episode for episode type', () {
        final metadata = createTestMetadata(type: 'episode');
        expect(metadata.mediaType, PlexMediaType.episode);
      });

      test('returns artist for artist type', () {
        final metadata = createTestMetadata(type: 'artist');
        expect(metadata.mediaType, PlexMediaType.artist);
      });

      test('returns album for album type', () {
        final metadata = createTestMetadata(type: 'album');
        expect(metadata.mediaType, PlexMediaType.album);
      });

      test('returns track for track type', () {
        final metadata = createTestMetadata(type: 'track');
        expect(metadata.mediaType, PlexMediaType.track);
      });

      test('returns collection for collection type', () {
        final metadata = createTestMetadata(type: 'collection');
        expect(metadata.mediaType, PlexMediaType.collection);
      });

      test('returns playlist for playlist type', () {
        final metadata = createTestMetadata(type: 'playlist');
        expect(metadata.mediaType, PlexMediaType.playlist);
      });

      test('returns clip for clip type', () {
        final metadata = createTestMetadata(type: 'clip');
        expect(metadata.mediaType, PlexMediaType.clip);
      });

      test('returns photo for photo type', () {
        final metadata = createTestMetadata(type: 'photo');
        expect(metadata.mediaType, PlexMediaType.photo);
      });

      test('returns unknown for unknown type', () {
        final metadata = createTestMetadata(type: 'unknown_type');
        expect(metadata.mediaType, PlexMediaType.unknown);
      });

      test('is case insensitive', () {
        final metadata = createTestMetadata(type: 'MOVIE');
        expect(metadata.mediaType, PlexMediaType.movie);
      });
    });

    group('globalKey', () {
      test('returns serverId:ratingKey when serverId is present', () {
        final metadata = createTestMetadata(
          ratingKey: '12345',
          serverId: 'server-abc',
        );

        expect(metadata.globalKey, 'server-abc:12345');
      });

      test('returns just ratingKey when serverId is null', () {
        final metadata = createTestMetadata(ratingKey: '12345');

        expect(metadata.globalKey, '12345');
      });
    });

    group('copyWith', () {
      test('copies all fields when no overrides provided', () {
        final original = PlexMetadata(
          ratingKey: '12345',
          key: '/library/metadata/12345',
          type: 'movie',
          title: 'Test Movie',
          year: 2024,
          duration: 7200000,
          serverId: 'server-123',
          serverName: 'My Server',
        );

        final copy = original.copyWith();

        expect(copy.ratingKey, original.ratingKey);
        expect(copy.key, original.key);
        expect(copy.type, original.type);
        expect(copy.title, original.title);
        expect(copy.year, original.year);
        expect(copy.duration, original.duration);
        expect(copy.serverId, original.serverId);
        expect(copy.serverName, original.serverName);
      });

      test('overrides specified fields', () {
        final original = PlexMetadata(
          ratingKey: '12345',
          key: '/library/metadata/12345',
          type: 'movie',
          title: 'Test Movie',
        );

        final copy = original.copyWith(
          title: 'Updated Title',
          year: 2025,
        );

        expect(copy.title, 'Updated Title');
        expect(copy.year, 2025);
        expect(copy.ratingKey, original.ratingKey);
      });

      test('can set serverId and serverName', () {
        final original = createTestMetadata();

        final copy = original.copyWith(
          serverId: 'new-server',
          serverName: 'New Server Name',
        );

        expect(copy.serverId, 'new-server');
        expect(copy.serverName, 'New Server Name');
      });
    });

    group('episode metadata', () {
      test('creates episode with show hierarchy', () {
        final episode = PlexMetadata(
          ratingKey: '11111',
          key: '/library/metadata/11111',
          type: 'episode',
          title: 'Pilot',
          grandparentTitle: 'Test Show',
          parentTitle: 'Season 1',
          parentIndex: 1,
          index: 1,
          grandparentRatingKey: '99999',
          parentRatingKey: '88888',
        );

        expect(episode.mediaType, PlexMediaType.episode);
        expect(episode.grandparentTitle, 'Test Show');
        expect(episode.parentTitle, 'Season 1');
        expect(episode.parentIndex, 1);
        expect(episode.index, 1);
        expect(episode.mediaType.isShowRelated, true);
        expect(episode.mediaType.isPlayable, true);
      });
    });

    group('playback tracking', () {
      test('tracks view offset', () {
        final metadata = PlexMetadata(
          ratingKey: '12345',
          key: '/library/metadata/12345',
          type: 'movie',
          title: 'Test Movie',
          duration: 7200000,
          viewOffset: 3600000, // 1 hour watched
        );

        expect(metadata.viewOffset, 3600000);
        expect(metadata.duration, 7200000);
      });

      test('tracks view count', () {
        final metadata = PlexMetadata(
          ratingKey: '12345',
          key: '/library/metadata/12345',
          type: 'movie',
          title: 'Test Movie',
          viewCount: 5,
        );

        expect(metadata.viewCount, 5);
      });
    });

    group('series progress', () {
      test('tracks leaf counts for series', () {
        final show = PlexMetadata(
          ratingKey: '99999',
          key: '/library/metadata/99999',
          type: 'show',
          title: 'Test Show',
          leafCount: 20,
          viewedLeafCount: 10,
        );

        expect(show.leafCount, 20);
        expect(show.viewedLeafCount, 10);
      });
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/plex_playlist.dart';

void main() {
  group('PlexPlaylist', () {
    PlexPlaylist createTestPlaylist({
      String ratingKey = '12345',
      String key = '/playlists/12345',
      String type = 'playlist',
      String title = 'Test Playlist',
      String? summary,
      bool smart = false,
      String playlistType = 'video',
      int? duration,
      int? leafCount,
      String? composite,
      int? addedAt,
      int? updatedAt,
      int? lastViewedAt,
      int? viewCount,
      String? content,
      String? guid,
      String? thumb,
      String? serverId,
      String? serverName,
    }) {
      return PlexPlaylist(
        ratingKey: ratingKey,
        key: key,
        type: type,
        title: title,
        summary: summary,
        smart: smart,
        playlistType: playlistType,
        duration: duration,
        leafCount: leafCount,
        composite: composite,
        addedAt: addedAt,
        updatedAt: updatedAt,
        lastViewedAt: lastViewedAt,
        viewCount: viewCount,
        content: content,
        guid: guid,
        thumb: thumb,
        serverId: serverId,
        serverName: serverName,
      );
    }

    group('basic properties', () {
      test('stores required fields', () {
        final playlist = createTestPlaylist(
          ratingKey: '99999',
          key: '/playlists/99999',
          title: 'My Playlist',
          playlistType: 'video',
        );

        expect(playlist.ratingKey, '99999');
        expect(playlist.key, '/playlists/99999');
        expect(playlist.title, 'My Playlist');
        expect(playlist.type, 'playlist');
        expect(playlist.playlistType, 'video');
      });

      test('stores optional fields', () {
        final playlist = createTestPlaylist(
          summary: 'A great playlist',
          duration: 7200000,
          leafCount: 25,
          composite: '/composite/image',
          addedAt: 1609459200,
          updatedAt: 1609545600,
          lastViewedAt: 1609632000,
          viewCount: 10,
          content: '/content/uri',
          guid: 'plex://playlist/12345',
          thumb: '/thumb/image',
        );

        expect(playlist.summary, 'A great playlist');
        expect(playlist.duration, 7200000);
        expect(playlist.leafCount, 25);
        expect(playlist.composite, '/composite/image');
        expect(playlist.addedAt, 1609459200);
        expect(playlist.updatedAt, 1609545600);
        expect(playlist.lastViewedAt, 1609632000);
        expect(playlist.viewCount, 10);
        expect(playlist.content, '/content/uri');
        expect(playlist.guid, 'plex://playlist/12345');
        expect(playlist.thumb, '/thumb/image');
      });
    });

    group('smart property', () {
      test('can be true', () {
        final playlist = createTestPlaylist(smart: true);
        expect(playlist.smart, true);
      });

      test('can be false', () {
        final playlist = createTestPlaylist(smart: false);
        expect(playlist.smart, false);
      });
    });

    group('displayImage', () {
      test('returns composite when available', () {
        final playlist = createTestPlaylist(
          composite: '/composite/image',
          thumb: '/thumb/image',
        );

        expect(playlist.displayImage, '/composite/image');
      });

      test('returns thumb when composite is null', () {
        final playlist = createTestPlaylist(
          composite: null,
          thumb: '/thumb/image',
        );

        expect(playlist.displayImage, '/thumb/image');
      });

      test('returns null when both are null', () {
        final playlist = createTestPlaylist(
          composite: null,
          thumb: null,
        );

        expect(playlist.displayImage, isNull);
      });
    });

    group('displayTitle', () {
      test('returns title', () {
        final playlist = createTestPlaylist(title: 'My Awesome Playlist');
        expect(playlist.displayTitle, 'My Awesome Playlist');
      });
    });

    group('isEditable', () {
      test('returns true when not smart', () {
        final playlist = createTestPlaylist(smart: false);
        expect(playlist.isEditable, true);
      });

      test('returns false when smart', () {
        final playlist = createTestPlaylist(smart: true);
        expect(playlist.isEditable, false);
      });
    });

    group('globalKey', () {
      test('returns serverId:ratingKey when serverId is present', () {
        final playlist = createTestPlaylist(
          ratingKey: '12345',
          serverId: 'server-abc',
        );

        expect(playlist.globalKey, 'server-abc:12345');
      });

      test('returns just ratingKey when serverId is null', () {
        final playlist = createTestPlaylist(ratingKey: '12345');

        expect(playlist.globalKey, '12345');
      });
    });

    group('MediaCard compatibility properties', () {
      test('isWatched is always false', () {
        final playlist = createTestPlaylist();
        expect(playlist.isWatched, false);
      });

      test('viewOffset is always null', () {
        final playlist = createTestPlaylist();
        expect(playlist.viewOffset, isNull);
      });

      test('parentIndex is always null', () {
        final playlist = createTestPlaylist();
        expect(playlist.parentIndex, isNull);
      });

      test('index is always null', () {
        final playlist = createTestPlaylist();
        expect(playlist.index, isNull);
      });

      test('parentTitle is always null', () {
        final playlist = createTestPlaylist();
        expect(playlist.parentTitle, isNull);
      });

      test('displaySubtitle is always null', () {
        final playlist = createTestPlaylist();
        expect(playlist.displaySubtitle, isNull);
      });

      test('year is always null', () {
        final playlist = createTestPlaylist();
        expect(playlist.year, isNull);
      });

      test('contentRating is always null', () {
        final playlist = createTestPlaylist();
        expect(playlist.contentRating, isNull);
      });

      test('rating is always null', () {
        final playlist = createTestPlaylist();
        expect(playlist.rating, isNull);
      });

      test('studio is always null', () {
        final playlist = createTestPlaylist();
        expect(playlist.studio, isNull);
      });

      test('childCount returns leafCount', () {
        final playlist = createTestPlaylist(leafCount: 42);
        expect(playlist.childCount, 42);
      });

      test('viewedLeafCount is always null', () {
        final playlist = createTestPlaylist();
        expect(playlist.viewedLeafCount, isNull);
      });
    });

    group('copyWith', () {
      test('copies all fields when no overrides provided', () {
        final original = PlexPlaylist(
          ratingKey: '12345',
          key: '/playlists/12345',
          type: 'playlist',
          title: 'Test Playlist',
          summary: 'A summary',
          smart: true,
          playlistType: 'video',
          duration: 7200000,
          leafCount: 25,
          composite: '/composite',
          addedAt: 1609459200,
          updatedAt: 1609545600,
          lastViewedAt: 1609632000,
          viewCount: 10,
          content: '/content',
          guid: 'guid-123',
          thumb: '/thumb',
          serverId: 'server-123',
          serverName: 'My Server',
        );

        final copy = original.copyWith();

        expect(copy.ratingKey, original.ratingKey);
        expect(copy.key, original.key);
        expect(copy.type, original.type);
        expect(copy.title, original.title);
        expect(copy.summary, original.summary);
        expect(copy.smart, original.smart);
        expect(copy.playlistType, original.playlistType);
        expect(copy.duration, original.duration);
        expect(copy.leafCount, original.leafCount);
        expect(copy.composite, original.composite);
        expect(copy.addedAt, original.addedAt);
        expect(copy.updatedAt, original.updatedAt);
        expect(copy.lastViewedAt, original.lastViewedAt);
        expect(copy.viewCount, original.viewCount);
        expect(copy.content, original.content);
        expect(copy.guid, original.guid);
        expect(copy.thumb, original.thumb);
        expect(copy.serverId, original.serverId);
        expect(copy.serverName, original.serverName);
      });

      test('overrides specified fields', () {
        final original = createTestPlaylist(
          title: 'Original Title',
          leafCount: 10,
        );

        final copy = original.copyWith(
          title: 'Updated Title',
          leafCount: 50,
        );

        expect(copy.title, 'Updated Title');
        expect(copy.leafCount, 50);
        expect(copy.ratingKey, original.ratingKey);
      });

      test('can set serverId and serverName', () {
        final original = createTestPlaylist();

        final copy = original.copyWith(
          serverId: 'new-server',
          serverName: 'New Server Name',
        );

        expect(copy.serverId, 'new-server');
        expect(copy.serverName, 'New Server Name');
      });

      test('can change smart flag', () {
        final original = createTestPlaylist(smart: false);

        final copy = original.copyWith(smart: true);

        expect(copy.smart, true);
        expect(copy.isEditable, false);
      });
    });

    group('playlistType', () {
      test('can be video', () {
        final playlist = createTestPlaylist(playlistType: 'video');
        expect(playlist.playlistType, 'video');
      });

      test('can be audio', () {
        final playlist = createTestPlaylist(playlistType: 'audio');
        expect(playlist.playlistType, 'audio');
      });

      test('can be photo', () {
        final playlist = createTestPlaylist(playlistType: 'photo');
        expect(playlist.playlistType, 'photo');
      });
    });

    group('multi-server support', () {
      test('stores serverId', () {
        final playlist = createTestPlaylist(serverId: 'server-abc-123');
        expect(playlist.serverId, 'server-abc-123');
      });

      test('stores serverName', () {
        final playlist = createTestPlaylist(serverName: 'My Home Server');
        expect(playlist.serverName, 'My Home Server');
      });
    });
  });
}

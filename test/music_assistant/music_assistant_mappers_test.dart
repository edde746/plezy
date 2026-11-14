import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/services/music_assistant/music_assistant_models.dart';
import 'package:plezy/services/music_assistant_mappers.dart';

import 'fake_ma_server.dart';

void main() {
  final images = MusicAssistantImageResolver(Uri.parse('http://10.0.2.107:8095'));
  final serverId = ServerId('fe2f5b6f');

  MediaItem? map(Map<String, dynamic> json) => MusicAssistantMappers.mediaItem(
    MaItem.fromJson(json),
    serverId: serverId,
    serverName: 'Basement NAS',
    images: images,
    libraryId: 'music',
    libraryTitle: 'Basement NAS',
  );

  group('track mapping', () {
    test('follows the established music field conventions', () {
      final track = map(maTrack('68057', name: 'Higher Power'))!;

      expect(track.kind, MediaKind.track);
      expect(track.backend, MediaBackend.musicAssistant);
      // The uri, not item_id: item_id is scoped to provider *and* media type,
      // so it is not unique on its own.
      expect(track.id, 'library://track/68057');
      expect(track.guid, 'library://track/68057');
      expect(track.title, 'Higher Power');
      expect(track.index, 9, reason: 'track number lives in index');
      expect(track.parentIndex, 1, reason: 'disc number lives in parentIndex');
      expect(track.parentId, 'library://album/7058', reason: 'a track parents to its album');
      expect(track.parentTitle, 'Music of the Spheres');
      expect(track.grandparentId, 'library://artist/36', reason: 'a track grandparents to its artist');
      expect(track.grandparentTitle, 'Coldplay');
      expect(track.durationMs, 21000);
      expect(track.serverId, 'fe2f5b6f');
      expect(track.libraryId, 'music');
    });

    test('falls back to the album cover when the track carries no image', () {
      final track = map(maTrack('68057'))!;

      // Nested album objects use a bare `image` key rather than
      // `metadata.images`, and the provider has to survive with the path.
      expect(track.thumbPath, contains('path=al-7058'));
      expect(track.thumbPath, contains('provider=opensubsonic--pu5hhsYV'));
    });

    test('keeps a null duration null rather than collapsing it to zero', () {
      final track = map({...maTrack('1')}..remove('duration'))!;

      expect(track.durationMs, isNull);
    });
  });

  group('album mapping', () {
    test('parents an album to its artist, matching the other backends', () {
      final album = map(maAlbum('9560', name: '+ (plus)'))!;

      expect(album.kind, MediaKind.album);
      expect(album.parentId, 'library://artist/46');
      expect(album.parentTitle, 'Ed Sheeran');
      expect(album.grandparentId, isNull, reason: 'an album has no grandparent');
      expect(album.year, 2011);
    });

    test('carries the favourite flag through', () {
      expect(map(maAlbum('1', favorite: true))!.isFavorite, isTrue);
      expect(map(maAlbum('2'))!.isFavorite, isFalse);
    });

    test('keeps sort_name separate from name so pages are not re-sorted by title', () {
      final album = map({...maAlbum('9560', name: 'The 100 Greatest Hits'), 'sort_name': '100 greatest hits'})!;

      expect(album.title, 'The 100 Greatest Hits');
      expect(album.titleSort, '100 greatest hits');
    });
  });

  test('artist mapping has no parent chain', () {
    final artist = map(maArtist('46', name: 'Ed Sheeran'))!;

    expect(artist.kind, MediaKind.artist);
    expect(artist.parentId, isNull);
    expect(artist.grandparentId, isNull);
  });

  group('kinds', () {
    test('maps the four browseable media types', () {
      expect(MusicAssistantMappers.kindFor('album'), MediaKind.album);
      expect(MusicAssistantMappers.kindFor('artist'), MediaKind.artist);
      expect(MusicAssistantMappers.kindFor('track'), MediaKind.track);
      expect(MusicAssistantMappers.kindFor('playlist'), MediaKind.playlist);
    });

    test('leaves types with no UI here unknown rather than coercing them', () {
      // The server also serves radio, podcasts and audiobooks. Calling any of
      // them a track would put them in music lists that cannot play them.
      expect(MusicAssistantMappers.kindFor('radio'), MediaKind.unknown);
      expect(MusicAssistantMappers.kindFor('podcast'), MediaKind.unknown);
      expect(MusicAssistantMappers.kindFor('audiobook'), MediaKind.unknown);
    });
  });

  group('artwork', () {
    test('builds an imageproxy URL carrying path, provider and size', () {
      final url = Uri.parse(images.imageUrl('al-4e9Hni', 'opensubsonic--pu5hhsYV', size: 300)!);

      expect(url.path, '/imageproxy');
      // The proxy 404s without `provider`, and serves the multi-megabyte
      // original without `size`.
      expect(url.queryParameters, {'path': 'al-4e9Hni', 'provider': 'opensubsonic--pu5hhsYV', 'size': '300'});
    });

    test('is null when the item has no image at all', () {
      expect(images.imageUrl(null, 'opensubsonic'), isNull);
      expect(images.imageUrl('', 'opensubsonic'), isNull);
      expect(map(maArtist('46'))!.thumbPath, isNull);
    });

    test('is null when the server URL is not known yet', () {
      expect(const MusicAssistantImageResolver(null).imageUrl('al-1', 'p'), isNull);
    });

    test('resizes only its own proxy URLs', () {
      final original = images.imageUrl('al-1', 'p', size: 512)!;

      expect(Uri.parse(MusicAssistantImageResolver.resized(original, 128)).queryParameters['size'], '128');
      // A URL from anywhere else has no size to rewrite and must survive intact.
      const foreign = 'https://example.com/cover.jpg';
      expect(MusicAssistantImageResolver.resized(foreign, 128), foreign);
    });
  });

  test('playlist mapping is always an audio playlist', () {
    final playlist = MusicAssistantMappers.playlist(
      MaItem.fromJson({
        'item_id': '4',
        'provider': 'library',
        'name': '500 Random tracks',
        'uri': 'library://playlist/4',
        'media_type': 'playlist',
      }),
      serverId: serverId,
      serverName: 'Basement NAS',
      images: images,
    )!;

    expect(playlist.id, 'library://playlist/4');
    expect(playlist.backend, MediaBackend.musicAssistant);
    expect(playlist.playlistType, 'audio');
    // The wire shape carries no track count; guessing one would show a wrong
    // number next to every playlist.
    expect(playlist.leafCount, isNull);
  });

  test('the synthetic library is an artist library so grouping is offered', () {
    final library = MusicAssistantMappers.library(serverId: serverId, serverName: 'Basement NAS', libraryId: 'music');

    expect(library.backend, MediaBackend.musicAssistant);
    expect(library.title, 'Basement NAS');
    // MediaKind.artist is what makes the browse screen offer Artists / Albums /
    // Tracks, which is the whole reason a synthetic library exists.
    expect(library.kind, MediaKind.artist);
  });

  group('serverDisplayName', () {
    test('keeps a name the user chose', () {
      expect(MusicAssistantMappers.serverDisplayName('Basement NAS'), 'Basement NAS');
      // One word with no dots is a label, not an address.
      expect(MusicAssistantMappers.serverDisplayName('Attic'), 'Attic');
      expect(MusicAssistantMappers.serverDisplayName("Jack's music"), "Jack's music");
    });

    test('refuses to let an address be the name of someone\'s music', () {
      // Every one of these was a real default at some point, or is one keystroke
      // away from it. None of them is a name.
      for (final address in [
        '10.0.2.107',
        '10.0.2.107:8095',
        'http://10.0.2.107:8095',
        'ws://10.0.2.107:8095/',
        '[fe80::1]',
        'localhost',
        'localhost:8095',
        'music.home.lan',
        'nas.local:8095',
        '  ',
        '',
      ]) {
        expect(MusicAssistantMappers.serverDisplayName(address), 'Music Assistant', reason: address);
      }
      expect(MusicAssistantMappers.serverDisplayName(null), 'Music Assistant');
    });
  });

  test('an item with no identity at all is dropped rather than mapped empty', () {
    expect(map(const {}), isNull);
  });
}

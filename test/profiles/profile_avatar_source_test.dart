import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/models/plex/plex_home_user.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/profiles/profile_avatar_source.dart';
import 'package:plezy/profiles/profile_connection.dart';

JellyfinConnection _jellyfin(
  String id, {
  required DateTime createdAt,
  String? primaryImageTag,
  String userId = 'jf-user',
  String baseUrl = 'https://jelly.example',
}) {
  return JellyfinConnection(
    id: id,
    baseUrl: baseUrl,
    serverName: 'Jelly',
    serverMachineId: 'machine-$id',
    userId: userId,
    userName: 'Agent',
    accessToken: 'secret-token',
    deviceId: 'device-1',
    primaryImageTag: primaryImageTag,
    createdAt: createdAt,
  );
}

PlexAccountConnection _plex(String id, {required DateTime createdAt}) {
  return PlexAccountConnection(
    id: id,
    accountToken: 'token-$id',
    clientIdentifier: 'client-$id',
    accountLabel: 'Plex',
    createdAt: createdAt,
  );
}

PlexHomeUser _homeUser(String uuid, {String thumb = ''}) {
  return PlexHomeUser(
    id: 1,
    uuid: uuid,
    title: 'Home $uuid',
    thumb: thumb,
    hasPassword: false,
    restricted: false,
    updatedAt: null,
    admin: false,
    guest: false,
    protected: false,
  );
}

ProfileConnection _link(String connectionId, {String profileId = 'local-1', String userIdentifier = 'jf-user'}) {
  return ProfileConnection(profileId: profileId, connectionId: connectionId, userIdentifier: userIdentifier);
}

Profile _local([String id = 'local-1']) => Profile.local(id: id, displayName: 'Owner', createdAt: DateTime(2026, 1, 1));

String? _resolve({
  required List<Profile> profiles,
  required Map<String, List<ProfileConnection>> links,
  required Map<String, Connection> connections,
  Map<String, List<PlexHomeUser>> plexHome = const {},
  String profileId = 'local-1',
}) {
  return resolveProfileAvatarUrls(
    profiles: profiles,
    connectionsByProfile: links,
    connectionsById: connections,
    plexHomeByConnectionId: plexHome,
  )[profileId];
}

void main() {
  group('resolveProfileAvatarUrls', () {
    test('uses the picture of the oldest linked connection', () {
      final older = _jellyfin('jf-older', createdAt: DateTime(2026, 1, 1), primaryImageTag: 'older-tag');
      final newer = _jellyfin('jf-newer', createdAt: DateTime(2026, 6, 1), primaryImageTag: 'newer-tag');

      final url = _resolve(
        profiles: [_local()],
        // Deliberately newest-first: the registry stream has no ordering
        // guarantee, so resolution must sort rather than take the head.
        links: {
          'local-1': [_link('jf-newer'), _link('jf-older')],
        },
        connections: {'jf-older': older, 'jf-newer': newer},
      );

      expect(url, contains('tag=older-tag'));
    });

    test('falls back to initials when the first connection has no picture', () {
      final first = _jellyfin('jf-first', createdAt: DateTime(2026, 1, 1));
      final second = _jellyfin('jf-second', createdAt: DateTime(2026, 6, 1), primaryImageTag: 'second-tag');

      final url = _resolve(
        profiles: [_local()],
        links: {
          'local-1': [_link('jf-first'), _link('jf-second')],
        },
        connections: {'jf-first': first, 'jf-second': second},
      );

      // "First wins" is literal: we do not skip ahead to a later connection
      // that happens to have an image.
      expect(url, isNull);
    });

    test('breaks a createdAt tie on connection id so the choice is stable', () {
      final sameInstant = DateTime(2026, 1, 1);
      final b = _jellyfin('jf-b', createdAt: sameInstant, primaryImageTag: 'b-tag');
      final a = _jellyfin('jf-a', createdAt: sameInstant, primaryImageTag: 'a-tag');

      final url = _resolve(
        profiles: [_local()],
        links: {
          'local-1': [_link('jf-b'), _link('jf-a')],
        },
        connections: {'jf-b': b, 'jf-a': a},
      );

      expect(url, contains('tag=a-tag'));
    });

    test('ignores links whose connection is gone, including for ordering', () {
      final survivor = _jellyfin('jf-survivor', createdAt: DateTime(2026, 6, 1), primaryImageTag: 'survivor-tag');

      final url = _resolve(
        profiles: [_local()],
        links: {
          'local-1': [_link('jf-removed'), _link('jf-survivor')],
        },
        connections: {'jf-survivor': survivor},
      );

      expect(url, contains('tag=survivor-tag'));
    });

    test('resolves a Plex link through the home user the link points at', () {
      final plex = _plex('plex-1', createdAt: DateTime(2026, 1, 1));

      final url = _resolve(
        profiles: [_local()],
        links: {
          'local-1': [_link('plex-1', userIdentifier: 'home-b')],
        },
        connections: {'plex-1': plex},
        plexHome: {
          'plex-1': [
            _homeUser('home-a', thumb: 'https://plex.tv/users/home-a/avatar'),
            _homeUser('home-b', thumb: 'https://plex.tv/users/home-b/avatar'),
          ],
        },
      );

      expect(url, 'https://plex.tv/users/home-b/avatar');
    });

    test('gives no picture for a Plex link with no home user selected', () {
      final plex = _plex('plex-1', createdAt: DateTime(2026, 1, 1));

      final url = _resolve(
        profiles: [_local()],
        links: {
          'local-1': [_link('plex-1', userIdentifier: '')],
        },
        connections: {'plex-1': plex},
        plexHome: {
          'plex-1': [_homeUser('home-a', thumb: 'https://plex.tv/users/home-a/avatar')],
        },
      );

      expect(url, isNull);
    });

    test('gives no picture when the selected home user has a blank thumb', () {
      final plex = _plex('plex-1', createdAt: DateTime(2026, 1, 1));

      final url = _resolve(
        profiles: [_local()],
        links: {
          'local-1': [_link('plex-1', userIdentifier: 'home-a')],
        },
        connections: {'plex-1': plex},
        plexHome: {
          'plex-1': [_homeUser('home-a')],
        },
      );

      expect(url, isNull);
    });

    test('mixed Jellyfin and Plex links still resolve by creation order', () {
      final plexFirst = _plex('plex-1', createdAt: DateTime(2026, 1, 1));
      final jellyfinSecond = _jellyfin('jf-1', createdAt: DateTime(2026, 6, 1), primaryImageTag: 'jf-tag');

      final url = _resolve(
        profiles: [_local()],
        links: {
          'local-1': [_link('jf-1'), _link('plex-1', userIdentifier: 'home-a')],
        },
        connections: {'plex-1': plexFirst, 'jf-1': jellyfinSecond},
        plexHome: {
          'plex-1': [_homeUser('home-a', thumb: 'https://plex.tv/users/home-a/avatar')],
        },
      );

      expect(url, 'https://plex.tv/users/home-a/avatar');
    });

    test('leaves a Plex Home profile on its own thumb', () {
      final plexHomeProfile = Profile.virtualPlexHome(
        connectionId: 'plex-1',
        homeUser: _homeUser('home-a', thumb: 'https://plex.tv/users/home-a/avatar'),
      );
      final borrowed = _jellyfin('jf-1', createdAt: DateTime(2026, 1, 1), primaryImageTag: 'jf-tag');

      final url = _resolve(
        profiles: [plexHomeProfile],
        links: {
          plexHomeProfile.id: [_link('jf-1', profileId: plexHomeProfile.id)],
        },
        connections: {'jf-1': borrowed},
        profileId: plexHomeProfile.id,
      );

      expect(url, 'https://plex.tv/users/home-a/avatar');
    });

    test('a Plex Home profile with no avatar keeps its initials rather than borrowing one', () {
      final plexHomeProfile = Profile.virtualPlexHome(connectionId: 'plex-1', homeUser: _homeUser('home-a'));
      final borrowed = _jellyfin('jf-1', createdAt: DateTime(2026, 1, 1), primaryImageTag: 'jf-tag');

      final url = _resolve(
        profiles: [plexHomeProfile],
        links: {
          plexHomeProfile.id: [_link('jf-1', profileId: plexHomeProfile.id)],
        },
        connections: {'jf-1': borrowed},
        profileId: plexHomeProfile.id,
      );

      // Plex owns this identity end to end; "nothing changes" for Plex Home
      // profiles means a blank thumb stays blank, not that it picks up the
      // picture of a lent connection.
      expect(url, isNull);
    });

    test('gives no picture to a profile with no links', () {
      expect(_resolve(profiles: [_local()], links: const {}, connections: const {}), isNull);
    });

    test('covers every profile so callers can look up by id', () {
      final map = resolveProfileAvatarUrls(
        profiles: [_local('local-1'), _local('local-2')],
        connectionsByProfile: const {},
        connectionsById: const {},
        plexHomeByConnectionId: const {},
      );

      expect(map.keys, containsAll(['local-1', 'local-2']));
    });
  });
}

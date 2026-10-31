import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/models/jellyfin/bonfire_profile.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/profiles/profile_connection.dart';
import 'package:plezy/profiles/profile_merge.dart';

const _kidsGuid = 'a90f11cb-42a1-432d-94bb-97cc2d42ef8b';
const _masterGuid = 'b1d3c4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e';

BonfireProfile _bonfire(String guid, {String name = 'Profile', bool requiresPin = false, bool isMaster = false}) {
  return BonfireProfile.fromJson({
    'profileUserId': guid,
    'profileName': name,
    'masterUserId': _masterGuid,
    'requiresPin': requiresPin,
    'hasPin': requiresPin,
    'isMaster': isMaster,
    'profileImage': '/plugins/profiles/image/$guid?v=3',
  });
}

JellyfinConnection _conn(String id) {
  return JellyfinConnection(
    id: id,
    baseUrl: 'https://jellyfin.example.net',
    serverName: 'Home Media',
    serverMachineId: 'machine-$id',
    userId: 'master-1',
    userName: 'dalgibbard',
    accessToken: 'master-token',
    deviceId: 'device-1',
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('mergeLocalWithPlexHome with Bonfire profiles', () {
    test('Bonfire /list entries become virtual profiles on their connection', () {
      final merged = mergeLocalWithPlexHome(
        locals: const [],
        plexHomeByConnectionId: const {},
        connectionsById: {'jf-1': _conn('jf-1')},
        bonfireByConnectionId: {
          'jf-1': [_bonfire(_masterGuid, name: 'Master', isMaster: true), _bonfire(_kidsGuid, name: 'Kids', requiresPin: true)],
        },
      );

      expect(merged.length, 2);
      final kids = merged.singleWhere((p) => p.bonfireUserId == _kidsGuid);
      expect(kids.isJellyfinBonfire, isTrue);
      expect(kids.kind, ProfileKind.jellyfinBonfire);
      expect(kids.id, 'bonfire-jf-1-$_kidsGuid');
      expect(kids.displayName, 'Kids');
      expect(kids.parentConnectionId, 'jf-1');
      expect(kids.isPinProtected, isTrue);
      expect(kids.pinHash, isNull); // server-side PIN, never stored locally
      expect(
        kids.avatarThumbUrl,
        'https://jellyfin.example.net/plugins/profiles/image/$_kidsGuid?v=3&size=thumb',
      );
    });

    test('profiles whose connection isn\'t registered are dropped', () {
      final merged = mergeLocalWithPlexHome(
        locals: const [],
        plexHomeByConnectionId: const {},
        connectionsById: const {},
        bonfireByConnectionId: {'ghost': [_bonfire(_kidsGuid)]},
      );
      expect(merged, isEmpty);
    });

    test('locals, Plex Home and Bonfire profiles coexist', () {
      final local = Profile.local(
        id: 'local-1',
        displayName: 'Local',
        createdAt: DateTime(2026, 1, 1),
      );
      final merged = mergeLocalWithPlexHome(
        locals: [local],
        plexHomeByConnectionId: const {},
        connectionsById: {'jf-1': _conn('jf-1')},
        bonfireByConnectionId: {'jf-1': [_bonfire(_kidsGuid, name: 'Kids')]},
      );
      expect(merged.map((p) => p.id), containsAll(['local-1', 'bonfire-jf-1-$_kidsGuid']));
    });
  });

  group('visibleProfileConnections', () {
    test('hides the parent connection row for Bonfire profiles', () {
      final profile = Profile.virtualJellyfinBonfire(
        connectionId: 'jf-1',
        profile: _bonfire(_kidsGuid),
        serverBaseUrl: 'https://jellyfin.example.net',
      );
      final pcs = [
        ProfileConnection(profileId: profile.id, connectionId: 'jf-1', userIdentifier: _kidsGuid),
        ProfileConnection(profileId: profile.id, connectionId: 'other-1', userIdentifier: _kidsGuid),
      ];
      final visible = visibleProfileConnections(profile, pcs);
      expect(visible.map((pc) => pc.connectionId), ['other-1']);
    });
  });

  group('Bonfire profile id helpers', () {
    test('bonfireProfileId + parseBonfireProfileId round-trip', () {
      final id = bonfireProfileId(connectionId: 'jf-1', bonfireUserId: _kidsGuid);
      expect(id, 'bonfire-jf-1-$_kidsGuid');
      final parsed = parseBonfireProfileId(id);
      expect(parsed?.connectionId, 'jf-1');
      expect(parsed?.bonfireUserId, _kidsGuid);
    });

    test('connection ids containing dashes parse correctly', () {
      final parsed = parseBonfireProfileId('bonfire-server-a-1-$_kidsGuid');
      expect(parsed?.connectionId, 'server-a-1');
      expect(parsed?.bonfireUserId, _kidsGuid);
    });

    test('non-Bonfire ids parse to null', () {
      expect(parseBonfireProfileId('local-1'), isNull);
      expect(parseBonfireProfileId('bonfire-jf-1-not-a-guid'), isNull);
    });

    test('ProfileKind round-trips its persisted id', () {
      expect(ProfileKind.jellyfinBonfire.id, 'jellyfin_bonfire');
      expect(ProfileKind.fromId('jellyfin_bonfire'), ProfileKind.jellyfinBonfire);
    });

    test('local parent row is hidden when a Bonfire master virtual exists', () {
      final merged = mergeLocalWithPlexHome(
        locals: [
          Profile.local(id: 'local-dal', displayName: 'dalgibbard', createdAt: DateTime(2026, 1, 1)),
          Profile.local(id: 'local-multi', displayName: 'Shared', createdAt: DateTime(2026, 1, 1)),
        ],
        plexHomeByConnectionId: const {},
        connectionsById: {'jf-1': _conn('jf-1'), 'jf-2': _conn('jf-2')},
        bonfireByConnectionId: {
          'jf-1': [
            _bonfire(_masterGuid, name: 'dalgibbard', isMaster: true),
            _bonfire(_kidsGuid, name: 'Max'),
          ],
        },
        localConnectionsByProfile: {
          'local-dal': [
            const ProfileConnection(profileId: 'local-dal', connectionId: 'jf-1', userIdentifier: 'master-1'),
          ],
          'local-multi': [
            const ProfileConnection(profileId: 'local-multi', connectionId: 'jf-1', userIdentifier: 'master-1'),
            const ProfileConnection(profileId: 'local-multi', connectionId: 'jf-2', userIdentifier: 'master-1'),
          ],
        },
      );

      // Duplicate account row gone; the Bonfire master row owns that identity.
      expect(merged.any((p) => p.id == 'local-dal'), isFalse);
      // A local borrowing multiple connections keeps its own row.
      expect(merged.any((p) => p.id == 'local-multi'), isTrue);
      expect(merged.where((p) => p.isJellyfinBonfire).length, 2);
    });

    test('an unrowed local named after the Bonfire master user is also hidden', () {
      final merged = mergeLocalWithPlexHome(
        locals: [
          Profile.local(id: 'local-fresh', displayName: 'dalgibbard', createdAt: DateTime(2026, 1, 1)),
          Profile.local(id: 'local-other', displayName: 'Someone Else', createdAt: DateTime(2026, 1, 1)),
        ],
        plexHomeByConnectionId: const {},
        connectionsById: {'jf-1': _conn('jf-1')},
        bonfireByConnectionId: {
          'jf-1': [_bonfire(_masterGuid, name: 'dalgibbard', isMaster: true)],
        },
      );

      expect(merged.any((p) => p.id == 'local-fresh'), isFalse);
      expect(merged.any((p) => p.id == 'local-other'), isTrue);
    });

    test('machine-keyed Bonfire entries resolve compound host connections', () {
      // Live registry rows for a real sign-in carry compound `machineId/userId`
      // ids; the Bonfire map is keyed by machine id so profile ids stay
      // caller-independent regardless of which connection minted them.
      final host = JellyfinConnection(
        id: 'machine-1/60aa',
        baseUrl: 'https://jellyfin.example.net',
        serverName: 'Home Media',
        serverMachineId: 'machine-1',
        userId: '60aa',
        userName: 'dalgibbard',
        accessToken: 'master-token',
        deviceId: 'device-1',
        createdAt: DateTime(2026, 1, 1),
      );
      final merged = mergeLocalWithPlexHome(
        locals: [Profile.local(id: 'local-dal', displayName: 'dalgibbard', createdAt: DateTime(2026, 1, 1))],
        plexHomeByConnectionId: const {},
        connectionsById: {host.id: host},
        bonfireByConnectionId: {
          'machine-1': [
            _bonfire(_masterGuid, name: 'dalgibbard', isMaster: true),
            _bonfire(_kidsGuid, name: 'Max'),
          ],
        },
        localConnectionsByProfile: const {},
      );

      final max = merged.singleWhere((p) => p.bonfireUserId == _kidsGuid);
      expect(max.id, 'bonfire-machine-1-$_kidsGuid');
      expect(max.parentConnectionId, 'machine-1');
      // The unrowed local named after the master user hides through the
      // compound host row too.
      expect(merged.any((p) => p.id == 'local-dal'), isFalse);
      expect(merged.where((p) => p.isJellyfinBonfire).length, 2);
    });

    test('a local whose sole join row is the compound host row hides too', () {
      // On device the local account's join row points at the compound sign-in
      // row, while the Bonfire master set carries machine ids. A row-keyed
      // comparison misses the duplicate and the picker shows two dalgibbards.
      final host = JellyfinConnection(
        id: 'machine-1/60aa',
        baseUrl: 'https://jellyfin.example.net',
        serverName: 'Home Media',
        serverMachineId: 'machine-1',
        userId: '60aa',
        userName: 'dalgibbard',
        accessToken: 'master-token',
        deviceId: 'device-1',
        createdAt: DateTime(2026, 1, 1),
      );
      final merged = mergeLocalWithPlexHome(
        locals: [Profile.local(id: 'local-dal', displayName: 'dalgibbard', createdAt: DateTime(2026, 1, 1))],
        plexHomeByConnectionId: const {},
        connectionsById: {host.id: host},
        bonfireByConnectionId: {
          'machine-1': [
            _bonfire(_masterGuid, name: 'dalgibbard', isMaster: true),
            _bonfire(_kidsGuid, name: 'Max'),
          ],
        },
        localConnectionsByProfile: const {
          'local-dal': [
            ProfileConnection(profileId: 'local-dal', connectionId: 'machine-1/60aa', userIdentifier: '60aa'),
          ],
        },
      );

      expect(merged.any((p) => p.id == 'local-dal'), isFalse);
      expect(merged.where((p) => p.isJellyfinBonfire).length, 2);
    });
  });
}

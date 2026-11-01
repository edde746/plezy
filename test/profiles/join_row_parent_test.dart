import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/profiles/profile_connection.dart';
import 'package:plezy/profiles/server_connection_lookup.dart';

// The binder must keep borrowed rows (a Plex library hosted elsewhere) but
// must not re-bind the parent host through a Bonfire join row: those rows
// carry the parent connection's FK row id, and rows written before the
// machine-id split may carry the bare machine id or a compound host id.

JellyfinConnection _jf(String id, {String machine = 'machine-1'}) => JellyfinConnection(
  id: id,
  baseUrl: 'https://jellyfin.example.net',
  serverName: 'Home Media',
  serverMachineId: machine,
  userId: 'u1',
  userName: 'Owner',
  accessToken: 'token',
  deviceId: 'device-1',
  createdAt: DateTime(2026, 1, 1),
);

PlexAccountConnection _plex(String id) => PlexAccountConnection(
  id: id,
  accountToken: 'plex-token',
  clientIdentifier: 'cid',
  accountLabel: 'Remote Plex',
  createdAt: DateTime(2026, 1, 1),
);

ProfileConnection _row(String connectionId) =>
    ProfileConnection(profileId: 'bonfire-p', connectionId: connectionId, userToken: 't', userIdentifier: 'u1');

void main() {
  group('joinRowBelongsToParent', () {
    final parent = _jf('machine-1/u-master');
    final byId = {
      parent.id: parent,
      'machine-2/x': _jf('machine-2/x', machine: 'machine-2'),
      'plex-2': _plex('plex-2'),
    };

    bool belongs(ProfileConnection row) =>
        joinRowBelongsToParent(row, parentConnectionId: 'machine-1', parentConnection: parent, connectionsById: byId);

    test('a row keyed by the parent connections row id belongs', () {
      expect(belongs(_row(parent.id)), isTrue);
    });

    test('a legacy row keyed by the bare machine id belongs', () {
      expect(belongs(_row('machine-1')), isTrue);
    });

    test('a compound host row that resolves to the same server belongs', () {
      byId['machine-1/u-other'] = _jf('machine-1/u-other');
      expect(belongs(_row('machine-1/u-other')), isTrue);
      byId.remove('machine-1/u-other');
    });

    test('a row on another Jellyfin server is a borrow', () {
      expect(belongs(_row('machine-2/x')), isFalse);
    });

    test('a row on a Plex connection is a borrow', () {
      expect(belongs(_row('plex-2')), isFalse);
    });
  });
}

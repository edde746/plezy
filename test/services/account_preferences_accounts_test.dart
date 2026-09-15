import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/media/account_ref.dart';
import 'package:plezy/models/plex/plex_home_user.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/profiles/profile_connection.dart';
import 'package:plezy/services/account_preferences_accounts.dart';

import '../test_helpers/backend_client_fixtures.dart';

void main() {
  final home = PlexHomeProfile(
    id: 'home',
    displayName: 'Home user',
    parentConnectionId: 'parent',
    plexHomeUserUuid: 'home-user',
    createdAt: DateTime(2026),
  );
  final parent = PlexAccountConnection(
    id: 'parent',
    accountToken: 'owner-token',
    clientIdentifier: 'client',
    accountLabel: 'Plex parent',
    createdAt: DateTime(2026),
  );
  final borrowed = testJellyfinConnection();
  final borrowedRow = ProfileConnection(
    profileId: home.id,
    connectionId: borrowed.id,
    userIdentifier: borrowed.userId,
    isDefault: true,
  );
  final parentRow = ProfileConnection(
    profileId: home.id,
    connectionId: parent.id,
    userIdentifier: 'home-user',
    userToken: 'switched-token',
  );

  test('a persisted borrowed default remains editable but Home authority is its exact parent', () {
    final resolution = resolveAccountPreferenceAccounts(
      profile: home,
      profileConnections: [borrowedRow, parentRow],
      connections: [borrowed, parent],
    );
    expect(resolution.accounts.first.ref.connectionId, borrowed.id);
    expect(resolution.playbackRef, const AccountRef.plex(accountConnectionId: 'parent', homeUserUuid: 'home-user'));
    expect(resolution.accounts.last.plexToken, 'switched-token');
  });

  test('missing Home parent, row, principal or token never selects the borrowed default or owner', () {
    for (final (profile, rows, connections) in <(Profile, List<ProfileConnection>, List<Connection>)>[
      (home, [borrowedRow, parentRow], [borrowed]),
      (home, [borrowedRow], [borrowed, parent]),
      (home, [borrowedRow, parentRow.copyWith(userToken: null)], [borrowed, parent]),
      (home, [borrowedRow, parentRow.copyWith(userToken: '')], [borrowed, parent]),
      (home, [borrowedRow, parentRow.copyWith(userIdentifier: 'someone-else')], [borrowed, parent]),
      (home.copyWith(plexHomeUserUuid: null), [borrowedRow, parentRow], [borrowed, parent]),
      (home.copyWith(parentConnectionId: null), [borrowedRow, parentRow], [borrowed, parent]),
    ]) {
      final resolution = resolveAccountPreferenceAccounts(
        profile: profile,
        profileConnections: rows,
        connections: connections,
      );
      expect(resolution.playbackRef, isNull);
      expect(resolution.accounts.map((account) => account.ref.connectionId), [borrowed.id]);
    }
  });

  test('local switched principals come from each row rather than account activeProfile metadata', () {
    final local = Profile.local(id: 'local', displayName: 'Local', createdAt: DateTime(2026));
    final account = parent.copyWith(
      activeProfile: PlexHomeUser(
        id: 2,
        uuid: 'account-wide-user',
        title: 'Other user',
        thumb: '',
        hasPassword: false,
        restricted: false,
        updatedAt: null,
        admin: false,
        guest: false,
        protected: false,
      ),
    );
    final resolution = resolveAccountPreferenceAccounts(
      profile: local,
      profileConnections: [parentRow.copyWith(profileId: local.id, isDefault: true)],
      connections: [account],
    );
    expect(resolution.playbackRef, const AccountRef.plex(accountConnectionId: 'parent', homeUserUuid: 'home-user'));
    expect(resolution.accounts.single.plexToken, 'switched-token');
  });

  test('a missing local designated account does not promote another editable account', () {
    final local = Profile.local(id: 'local', displayName: 'Local', createdAt: DateTime(2026));
    final resolution = resolveAccountPreferenceAccounts(
      profile: local,
      profileConnections: [
        parentRow.copyWith(profileId: local.id, isDefault: true),
        borrowedRow.copyWith(profileId: local.id, isDefault: false),
      ],
      connections: [borrowed],
    );
    expect(resolution.playbackRef, isNull);
    expect(resolution.accounts.single.ref.connectionId, borrowed.id);
  });

  test('two MediaBrowser users on one server retain separate designated identities', () {
    final local = Profile.local(id: 'local', displayName: 'Local', createdAt: DateTime(2026));
    final other = testJellyfinConnection(userId: 'other-user');
    final resolution = resolveAccountPreferenceAccounts(
      profile: local,
      profileConnections: [
        borrowedRow.copyWith(profileId: local.id, isDefault: false),
        ProfileConnection(profileId: local.id, connectionId: other.id, userIdentifier: other.userId, isDefault: true),
      ],
      connections: [borrowed, other],
    );
    expect(resolution.playbackRef?.connectionId, other.id);
    expect(resolution.accounts.map((account) => account.ref.connectionId).toSet(), {borrowed.id, other.id});
  });
}

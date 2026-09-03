import '../connection/connection.dart';
import '../media/account_preferences_target.dart';
import '../media/account_ref.dart';
import '../profiles/profile.dart';
import '../profiles/profile_connection.dart';

/// One editable account: what the picker shows, plus the credential the
/// plex.tv source needs. MediaBrowser accounts carry no token here — their
/// requests go through the live [JellyfinClient] owned by
/// [MultiServerManager].
class AccountPreferenceAccount {
  const AccountPreferenceAccount({required this.target, required this.connection, this.plexToken});

  final AccountPreferenceTarget target;
  final Connection connection;

  /// The Plex Home-user token for this account, or the account-owner token for
  /// a local profile that signed in as the owner. Never the owner's token for
  /// a managed Home user.
  final String? plexToken;

  AccountRef get ref => target.ref;
}

/// Resolve the accounts whose preferences the active profile may edit.
///
/// Scoped to [profile]'s own connection rows: the section edits the signed-in
/// user's server-side preferences, and another profile's accounts are neither
/// reachable with these tokens nor this user's business.
///
/// Plex token resolution is deliberately strict: a Plex Home profile may use
/// only the switched token stored on its exact parent connection row. Falling
/// back to the account-owner token would read and *write* the owner's
/// preferences — and apply them to playback — while the user is in a managed
/// profile.
List<AccountPreferenceAccount> resolveAccountPreferenceAccounts({
  required Profile? profile,
  required List<ProfileConnection> profileConnections,
  required List<Connection> connections,
}) {
  if (profile == null || profileConnections.isEmpty) return const [];

  final byId = {for (final connection in connections) connection.id: connection};
  final isPlexHomeProfile = profile.kind == ProfileKind.plexHome;
  final accounts = <AccountPreferenceAccount>[];

  for (final row in profileConnections) {
    final connection = byId[row.connectionId];
    switch (connection) {
      case JellyfinConnection():
        accounts.add(
          AccountPreferenceAccount(
            target: AccountPreferenceTarget(
              ref: AccountRef.mediaBrowser(backend: connection.kind, connectionId: connection.id),
              label: connection.displayLabel,
              subtitle: connection.displaySubtitle,
              isActiveProfileAccount: row.isDefault,
            ),
            connection: connection,
          ),
        );
      case PlexAccountConnection():
        final resolved = _resolvePlexAccount(
          profile: profile,
          isPlexHomeProfile: isPlexHomeProfile,
          row: row,
          connection: connection,
        );
        if (resolved != null) accounts.add(resolved);
      case null:
        continue;
    }
  }

  accounts.sort((a, b) {
    if (a.target.isActiveProfileAccount != b.target.isActiveProfileAccount) {
      return a.target.isActiveProfileAccount ? -1 : 1;
    }
    return a.target.label.toLowerCase().compareTo(b.target.label.toLowerCase());
  });
  return accounts;
}

AccountPreferenceAccount? _resolvePlexAccount({
  required Profile profile,
  required bool isPlexHomeProfile,
  required ProfileConnection row,
  required PlexAccountConnection connection,
}) {
  String? homeUserUuid;
  String? token;

  if (isPlexHomeProfile) {
    // Only the profile's own parent account, and only with its switched token.
    if (profile.parentConnectionId != connection.id) return null;
    homeUserUuid = profile.plexHomeUserUuid;
    if (homeUserUuid == null || homeUserUuid.isEmpty) return null;
    if (!row.hasToken) return null;
    token = row.userToken;
  } else {
    // Local profile: the row's own minted token is already user-scoped; the
    // account token is correct only when the profile signed in as the owner.
    homeUserUuid = connection.activeProfile?.uuid;
    token = row.hasToken ? row.userToken : connection.accountToken;
    if (token == null || token.isEmpty) return null;
  }

  final homeUserTitle = isPlexHomeProfile ? profile.displayName : connection.activeProfile?.title;

  return AccountPreferenceAccount(
    target: AccountPreferenceTarget(
      ref: AccountRef.plex(accountConnectionId: connection.id, homeUserUuid: homeUserUuid),
      label: connection.accountLabel,
      subtitle: (homeUserTitle != null && homeUserTitle.isNotEmpty) ? homeUserTitle : null,
      isActiveProfileAccount: row.isDefault,
    ),
    connection: connection,
    plexToken: token,
  );
}

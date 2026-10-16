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

/// Picker ordering and playback authority are separate profile policies.
class AccountPreferenceResolution {
  const AccountPreferenceResolution({this.accounts = const [], this.playbackRef});

  final List<AccountPreferenceAccount> accounts;
  final AccountRef? playbackRef;
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
AccountPreferenceResolution resolveAccountPreferenceAccounts({
  required Profile? profile,
  required List<ProfileConnection> profileConnections,
  required List<Connection> connections,
}) {
  if (profile == null || profileConnections.isEmpty) return const AccountPreferenceResolution();

  final byId = {for (final connection in connections) connection.id: connection};
  final isPlexHomeProfile = profile.kind == ProfileKind.plexHome;
  final accounts = <AccountPreferenceAccount>[];
  AccountRef? playbackRef;

  for (final row in profileConnections) {
    if (row.profileId != profile.id) continue;
    final connection = byId[row.connectionId];
    final account = switch (connection) {
      JellyfinConnection() => AccountPreferenceAccount(
        target: AccountPreferenceTarget(
          ref: AccountRef.mediaBrowser(backend: connection.kind, connectionId: connection.id),
          label: connection.displayLabel,
          subtitle: connection.displaySubtitle,
          isDefaultConnection: row.isDefault,
        ),
        connection: connection,
      ),
      PlexAccountConnection() => _resolvePlexAccount(
        profile: profile,
        isPlexHomeProfile: isPlexHomeProfile,
        row: row,
        connection: connection,
      ),
      PlexDirectConnection() => null,
      null => null,
    };
    if (account == null) continue;
    accounts.add(account);
    // Home authority belongs to its exact parent, even when a borrowed
    // connection is the editable picker's default. Locals use their designated
    // row; a missing account never promotes another reachable connection.
    final isPlaybackRow = isPlexHomeProfile
        ? connection is PlexAccountConnection && row.connectionId == profile.parentConnectionId
        : row.isDefault;
    if (isPlaybackRow) playbackRef = account.ref;
  }

  accounts.sort((a, b) {
    if (a.target.isDefaultConnection != b.target.isDefaultConnection) {
      return a.target.isDefaultConnection ? -1 : 1;
    }
    return a.target.label.toLowerCase().compareTo(b.target.label.toLowerCase());
  });
  return AccountPreferenceResolution(accounts: accounts, playbackRef: playbackRef);
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
    if (row.userIdentifier != homeUserUuid || !row.hasToken) return null;
    token = row.userToken;
  } else {
    // Preserve the local tokenless fallback policy. A switched row's principal
    // comes from that row, never mutable account-level activeProfile metadata.
    homeUserUuid = row.hasToken ? row.userIdentifier : connection.activeProfile?.uuid;
    token = row.hasToken ? row.userToken : connection.accountToken;
    if (token == null || token.isEmpty) return null;
  }

  final homeUserTitle = isPlexHomeProfile ? profile.displayName : connection.activeProfile?.title;

  return AccountPreferenceAccount(
    target: AccountPreferenceTarget(
      ref: AccountRef.plex(accountConnectionId: connection.id, homeUserUuid: homeUserUuid),
      label: connection.accountLabel,
      subtitle: (homeUserTitle != null && homeUserTitle.isNotEmpty) ? homeUserTitle : null,
      isDefaultConnection: row.isDefault,
    ),
    connection: connection,
    plexToken: token,
  );
}

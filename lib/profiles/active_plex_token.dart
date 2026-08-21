import '../connection/connection_registry.dart';
import 'active_plex_identity.dart';
import 'active_profile_provider.dart';
import 'profile.dart';
import 'profile_connection_registry.dart';

/// The active profile's Plex identity together with the effective token
/// resolved by [resolveActivePlexToken].
class ActivePlexToken {
  const ActivePlexToken({required this.identity, required this.token});

  final ActivePlexIdentity identity;

  /// Effective Plex token for [identity] under the policy documented on
  /// [resolveActivePlexToken].
  final String token;
}

/// THE resolver for the active profile's effective Plex credential.
///
/// One policy: the profile's per-user token (the `ProfileConnection` row
/// bound to the identity's account, minted via `/home/users/{uuid}/switch`)
/// wins when present; otherwise the account-owner token.
///
/// [allowAccountTokenForHomeUser] controls the owner-token fallback for Plex
/// Home profiles. Cloud Discover and Seerr pass `true` — any credential on
/// the account is acceptable there. User-settings resolution passes `false`
/// because the owner's token belongs to a *different* plex.tv user, so a
/// Home profile without its switched token resolves to `null` instead of
/// silently impersonating the owner. Local profiles always fall back: their
/// selected account *is* the profile's identity.
Future<ActivePlexToken?> resolveActivePlexToken({
  required ActiveProfileProvider activeProfile,
  required ConnectionRegistry connections,
  required ProfileConnectionRegistry profileConnections,
  required bool allowAccountTokenForHomeUser,
}) async {
  final identity = await resolveActivePlexIdentity(
    activeProfile: activeProfile,
    connections: connections,
    profileConnections: profileConnections,
  );
  if (identity == null) return null;

  final profile = activeProfile.active;
  if (profile != null) {
    final profileConnection = await profileConnections.get(profile.id, identity.account.id);
    if (profileConnection?.hasToken ?? false) {
      return ActivePlexToken(identity: identity, token: profileConnection!.userToken!);
    }
  }
  if (!allowAccountTokenForHomeUser && profile?.kind == ProfileKind.plexHome) return null;
  return ActivePlexToken(identity: identity, token: identity.account.accountToken);
}

import '../connection/connection.dart';
import '../connection/connection_registry.dart';
import 'active_profile_provider.dart';
import 'profile_connection_registry.dart';

class ActivePlexIdentity {
  const ActivePlexIdentity({required this.account, this.userUuid});

  final PlexAccountConnection account;
  final String? userUuid;
}

Future<ActivePlexIdentity?> resolveActivePlexIdentity({
  required ActiveProfileProvider activeProfile,
  required ConnectionRegistry connections,
  required ProfileConnectionRegistry profileConnections,
  PlexAccountConnection? preferredAccount,
}) async {
  await activeProfile.initialize();
  final profile = activeProfile.active;

  String? userUuidForPreferred() {
    if (profile == null) return null;
    if (profile.parentConnectionId == preferredAccount?.id) {
      return profile.plexHomeUserUuid;
    }
    return null;
  }

  if (preferredAccount != null) {
    final preferredUserUuid = userUuidForPreferred();
    if (preferredUserUuid != null) {
      return ActivePlexIdentity(account: preferredAccount, userUuid: preferredUserUuid);
    }
    if (profile != null) {
      final pcs = await profileConnections.listForProfile(profile.id);
      for (final pc in pcs) {
        if (pc.connectionId == preferredAccount.id) {
          return ActivePlexIdentity(
            account: preferredAccount,
            userUuid: pc.userIdentifier.isEmpty ? null : pc.userIdentifier,
          );
        }
      }
    }
    return ActivePlexIdentity(account: preferredAccount);
  }

  final parentId = profile?.parentConnectionId;
  if (parentId != null) {
    final account = await connections.getPlexAccount(parentId);
    if (account != null) {
      return ActivePlexIdentity(account: account, userUuid: profile?.plexHomeUserUuid);
    }
  }

  if (profile != null) {
    final pcs = await profileConnections.listForProfile(profile.id);
    for (final pc in pcs) {
      final account = await connections.getPlexAccount(pc.connectionId);
      if (account != null) {
        return ActivePlexIdentity(account: account, userUuid: pc.userIdentifier.isEmpty ? null : pc.userIdentifier);
      }
    }
    return null;
  }

  final accounts = await connections.listPlexAccounts();
  if (accounts.isEmpty) return null;
  return ActivePlexIdentity(account: accounts.first);
}
